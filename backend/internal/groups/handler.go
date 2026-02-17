package groups

import (
	"encoding/json"
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

	group, err := h.repo.GetGroup(r.Context(), groupID)
	if err != nil {
		http.Error(w, "group not found", http.StatusNotFound)
		return
	}

	// Check capacity
	count, err := h.repo.GetMemberCount(r.Context(), groupID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if count >= group.MaxMembers {
		http.Error(w, "group is full", http.StatusBadRequest)
		return
	}

	if err := h.repo.JoinGroup(r.Context(), groupID, user.ID); err != nil {
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

	// 1. Get user's interests
	userInterests, err := h.repo.GetUserInterests(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get user interests", http.StatusInternalServerError)
		return
	}

	// 2. Get all groups for this event
	eventGroups, err := h.repo.GetGroupsForEvent(r.Context(), eventID)
	if err != nil {
		http.Error(w, "failed to get groups", http.StatusInternalServerError)
		return
	}

	// 3. Score each group using strict filtering + Log-Enhanced Jaccard
	var results []GroupWithDetails
	for _, g := range eventGroups {
		memberInterestsList, err := h.repo.GetGroupMemberInterests(r.Context(), g.ID)
		if err != nil {
			continue
		}

		memberCount, _ := h.repo.GetMemberCount(r.Context(), g.ID)

		// Skip full groups
		if memberCount >= g.MaxMembers {
			continue
		}

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

		results = append(results, GroupWithDetails{
			Group:       g,
			MemberCount: memberCount,
			MatchScore:  avgScore,
			Interests:   interests,
		})
	}

	// 4. Sort by match score descending
	sort.Slice(results, func(i, j int) bool {
		return results[i].MatchScore > results[j].MatchScore
	})

	if results == nil {
		results = []GroupWithDetails{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
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
