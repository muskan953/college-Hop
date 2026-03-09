package groups

import (
	"encoding/json"
	"errors"
	"net/http"
	"sort"
	"strings"

	"github.com/muskan953/college-Hop/internal/auth"
)

const DefaultThreshold = 0.1 // Minimum Jaccard score to keep a group

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

// POST /groups — Create a new travel group
func (h *Handler) CreateGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateGroupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	if req.Name == "" || req.EventID == "" {
		http.Error(w, "name and event_id are required", http.StatusBadRequest)
		return
	}

	maxMembers := req.MaxMembers
	if maxMembers <= 0 || maxMembers > 6 {
		maxMembers = 4
	}

	group := &Group{
		EventID:     req.EventID,
		Name:        req.Name,
		Description: strings.TrimSpace(req.Description),
		CreatedBy:   user.ID,
		MaxMembers:  maxMembers,
	}

	if err := h.repo.CreateGroup(r.Context(), group); err != nil {
		http.Error(w, "failed to create group", http.StatusInternalServerError)
		return
	}

	// Auto-join creator as first member
	if err := h.repo.JoinGroup(r.Context(), group.ID, user.ID); err != nil {
		http.Error(w, "failed to join group", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(group)
}

// POST /groups/{id}/join — Join a travel group
func (h *Handler) JoinGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract group ID from URL: /groups/{id}/join
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/"), "/")
	if len(parts) < 3 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	// Verify the group exists before attempting the atomic join.
	if _, err := h.repo.GetGroup(r.Context(), groupID); err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}

	// JoinGroupChecked atomically checks capacity and inserts — no race condition.
	if err := h.repo.JoinGroupChecked(r.Context(), groupID, user.ID); err != nil {
		if errors.Is(err, ErrGroupFull) {
			http.Error(w, "group is full", http.StatusBadRequest)
			return
		}
		http.Error(w, "failed to join group", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "joined group"})
}

// GET /groups/suggested?event_id=xxx — Get suggested groups with matching
func (h *Handler) SuggestedGroups(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	eventID := r.URL.Query().Get("event_id")
	if eventID == "" {
		http.Error(w, "event_id query param is required", http.StatusBadRequest)
		return
	}

	// 1. Get user's interests (1 query)
	userInterests, err := h.repo.GetUserInterests(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get user interests", http.StatusInternalServerError)
		return
	}

	// 2. Get all groups for this event WITH member counts (1 query, replaces GetGroupsForEvent + N×GetMemberCount)
	eventGroups, err := h.repo.GetGroupsWithCountsForEvent(r.Context(), eventID)
	if err != nil {
		http.Error(w, "failed to get groups", http.StatusInternalServerError)
		return
	}

	// 3. Get all member interests for every group in one shot (1 query, replaces N×GetGroupMemberInterests)
	allMemberInterests, err := h.repo.GetGroupMemberInterestsForEvent(r.Context(), eventID)
	if err != nil {
		http.Error(w, "failed to get group interests", http.StatusInternalServerError)
		return
	}

	// 4. Score each group using strict filtering + Log-Enhanced Jaccard
	var results []GroupWithDetails
	for _, g := range eventGroups {
		// Skip full groups (count already embedded in GroupWithDetails)
		if g.MemberCount >= g.MaxMembers {
			continue
		}

		memberInterestsList := allMemberInterests[g.ID] // nil if group has no members with interests

		// Strict filtering: check each member
		rejected := false
		totalScore := 0.0
		allInterests := make(map[string]bool)

		for _, memberInterests := range memberInterestsList {
			score := CalculateSimilarity(userInterests, memberInterests)
			if score < DefaultThreshold {
				rejected = true
				break
			}
			totalScore += score
			for _, interest := range memberInterests {
				allInterests[interest] = true
			}
		}

		if rejected {
			continue
		}

		avgScore := 0.0
		if len(memberInterestsList) > 0 {
			avgScore = totalScore / float64(len(memberInterestsList))
		}

		// Collect unique interests
		var interests []string
		for k := range allInterests {
			interests = append(interests, k)
		}

		result := g // copy GroupWithDetails (already has MemberCount)
		result.MatchScore = avgScore
		result.Interests = interests
		results = append(results, result)
	}

	// 5. Sort by match score descending
	sort.Slice(results, func(i, j int) bool {
		return results[i].MatchScore > results[j].MatchScore
	})

	if results == nil {
		results = []GroupWithDetails{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

// GET /me/groups — List all groups the authenticated user belongs to
func (h *Handler) GetMyGroups(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	groups, err := h.repo.GetUserGroups(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get groups", http.StatusInternalServerError)
		return
	}
	if groups == nil {
		groups = []GroupWithDetails{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(groups)
}

// GET /groups/{id} — Get a single group with full member profiles
func (h *Handler) GetGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	_, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// /groups/{id}
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 2 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}

	members, err := h.repo.GetGroupMembers(r.Context(), groupID)
	if err != nil {
		http.Error(w, "failed to get members", http.StatusInternalServerError)
		return
	}
	if members == nil {
		members = []GroupMemberProfile{}
	}

	resp := GroupDetailResponse{
		Group:       *group,
		MemberCount: len(members),
		Members:     members,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// PUT /groups/{id} — Update group name/description (creator only)
func (h *Handler) UpdateGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 2 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}
	if group.CreatedBy != user.ID {
		http.Error(w, "only the group creator can update the group", http.StatusForbidden)
		return
	}

	var req UpdateGroupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	req.Name = strings.TrimSpace(req.Name)
	if req.Name == "" {
		http.Error(w, "name is required", http.StatusBadRequest)
		return
	}

	if err := h.repo.UpdateGroup(r.Context(), groupID, req.Name, strings.TrimSpace(req.Description)); err != nil {
		http.Error(w, "failed to update group", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "group updated"})
}

// DELETE /groups/{id} — Delete the group (creator only)
func (h *Handler) DeleteGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 2 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}
	if group.CreatedBy != user.ID {
		http.Error(w, "only the group creator can delete the group", http.StatusForbidden)
		return
	}

	if err := h.repo.DeleteGroup(r.Context(), groupID); err != nil {
		http.Error(w, "failed to delete group", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "group deleted"})
}

// POST /groups/{id}/leave — Leave a group (any member except creator)
func (h *Handler) LeaveGroup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// /groups/{id}/leave
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 3 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}

	if group.CreatedBy == user.ID {
		http.Error(w, "you are the group creator — delete the group instead of leaving", http.StatusBadRequest)
		return
	}

	isMember, err := h.repo.IsGroupMember(r.Context(), groupID, user.ID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if !isMember {
		http.Error(w, "you are not a member of this group", http.StatusBadRequest)
		return
	}

	if err := h.repo.RemoveMember(r.Context(), groupID, user.ID); err != nil {
		http.Error(w, "failed to leave group", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "left group"})
}

// POST /groups/{id}/kick — Kick a member from the group (creator only)
func (h *Handler) KickMember(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 3 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	groupID := parts[1]

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}
	if group.CreatedBy != user.ID {
		http.Error(w, "only the group creator can kick members", http.StatusForbidden)
		return
	}

	var req KickRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.UserID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}
	if req.UserID == user.ID {
		http.Error(w, "you cannot kick yourself — delete the group instead", http.StatusBadRequest)
		return
	}

	isMember, err := h.repo.IsGroupMember(r.Context(), groupID, req.UserID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if !isMember {
		http.Error(w, "user is not a member of this group", http.StatusBadRequest)
		return
	}

	if err := h.repo.RemoveMember(r.Context(), groupID, req.UserID); err != nil {
		http.Error(w, "failed to kick member", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "member removed"})
}

// GET /users/matches?event_id=xxx — Find best peer matches
func (h *Handler) FindMatches(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	eventID := r.URL.Query().Get("event_id")
	if eventID == "" {
		http.Error(w, "event_id query param is required", http.StatusBadRequest)
		return
	}

	// 1. Get user's interests
	userInterests, err := h.repo.GetUserInterests(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get user interests", http.StatusInternalServerError)
		return
	}

	// 2. Get all users attending this event
	candidates, err := h.repo.GetUsersForEvent(r.Context(), eventID, user.ID)
	if err != nil {
		http.Error(w, "failed to get candidates", http.StatusInternalServerError)
		return
	}

	// 3. Score each candidate
	var matches []MatchedUser
	for _, candidate := range candidates {
		score := CalculateSimilarity(userInterests, candidate.Interests)
		if score < DefaultThreshold {
			continue
		}

		common := FindCommonInterests(userInterests, candidate.Interests)

		matches = append(matches, MatchedUser{
			UserID:          candidate.UserID,
			FullName:        candidate.FullName,
			CollegeName:     candidate.CollegeName,
			ProfilePhotoURL: candidate.ProfilePhotoURL,
			CommonInterests: common,
			MatchScore:      score,
		})
	}

	// 4. Sort by score descending
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].MatchScore > matches[j].MatchScore
	})

	// Limit to top 10
	if len(matches) > 10 {
		matches = matches[:10]
	}

	if matches == nil {
		matches = []MatchedUser{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(matches)
}
