package profile

type UpdateProfileRequest struct {
	FullName        string   `json:"full_name"`
	CollegeName     string   `json:"college_name"`
	Major           string   `json:"major"`
	RollNumber      string   `json:"roll_number"`
	IDExpiration    string   `json:"id_expiration"`
	Bio             string   `json:"bio"`
	ProfilePhotoURL string   `json:"profile_photo_url"`
	IDCardURL       string   `json:"college_id_card_url"`
	AlternateEmail  string   `json:"alternate_email"`
	Interests       []string `json:"interests"`
}

type ProfileResponse struct {
	UserID           string   `json:"user_id"`
	FullName         string   `json:"full_name"`
	CollegeName      string   `json:"college_name"`
	Major            string   `json:"major"`
	RollNumber       string   `json:"roll_number"`
	IDExpiration     string   `json:"id_expiration"`
	Bio              string   `json:"bio"`
	ProfilePhotoURL  string   `json:"profile_photo_url"`
	IDCardURL        string   `json:"college_id_card_url"`
	AlternateEmail   string   `json:"alternate_email"`
	Interests        []string `json:"interests"`
	Status           string   `json:"status"`
	IsAlumni         bool     `json:"is_alumni"`
	EventsCount      int      `json:"events_count"`
	GroupsCount      int      `json:"groups_count"`
	ConnectionsCount int      `json:"connections_count"`
}

type UpdatePreferencesRequest struct {
	ProfileVisibility  string `json:"profile_visibility"`
	ShowLocation       bool   `json:"show_location"`
	PushNotifications  bool   `json:"push_notifications"`
	EmailNotifications bool   `json:"email_notifications"`
	NewMatchAlerts     bool   `json:"new_match_alerts"`
	MessageAlerts      bool   `json:"message_alerts"`
}

type PreferencesResponse struct {
	ProfileVisibility  string `json:"profile_visibility"`
	ShowLocation       bool   `json:"show_location"`
	PushNotifications  bool   `json:"push_notifications"`
	EmailNotifications bool   `json:"email_notifications"`
	NewMatchAlerts     bool   `json:"new_match_alerts"`
	MessageAlerts      bool   `json:"message_alerts"`
}
