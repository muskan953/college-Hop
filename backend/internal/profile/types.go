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
	Interests       []string `json:"interests"`
}

type ProfileResponse struct {
	FullName        string   `json:"full_name"`
	CollegeName     string   `json:"college_name"`
	Major           string   `json:"major"`
	RollNumber      string   `json:"roll_number"`
	IDExpiration    string   `json:"id_expiration"`
	Bio             string   `json:"bio"`
	ProfilePhotoURL string   `json:"profile_photo_url"`
	IDCardURL       string   `json:"college_id_card_url"`
	Interests       []string `json:"interests"`
	Status          string   `json:"status"`
}
