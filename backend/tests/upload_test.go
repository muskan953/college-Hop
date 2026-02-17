package tests

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/server"
)

func TestUpload(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{
		UploadFunc: func(filename string, file io.Reader) (string, error) {
			return "http://test-server/uploads/" + filename, nil
		},
	}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, &MockAdminRepository{}, mockStore, "./uploads")
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, _ := writer.CreateFormFile("file", "test.jpg")
	// Write fake image data (minimal JPEG signature FF D8 FF)
	part.Write([]byte{0xFF, 0xD8, 0xFF})
	writer.Close()

	req, _ := http.NewRequest("POST", "/upload?type=profile_photo", body)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var resp map[string]string
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Errorf("failed to decode response: %v", err)
	}

	if resp["url"] == "" {
		t.Error("expected url in response")
	}
}
