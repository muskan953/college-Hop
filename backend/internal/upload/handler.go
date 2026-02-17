package upload

import (
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/pkg/storage"
)

const maxUploadSize = 5 << 20 // 5 MB

// Allowed MIME types per upload type
var allowedTypes = map[string]map[string]string{
	"profile_photo": {
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/webp": ".webp",
	},
	"id_card": {
		"application/pdf": ".pdf",
	},
}

type UploadResponse struct {
	URL string `json:"url"`
}

type Handler struct {
	store storage.FileStorage
}

func NewHandler(store storage.FileStorage) *Handler {
	return &Handler{store: store}
}

func (h *Handler) Upload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 1. Authenticate
	_, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// 2. Validate upload type
	uploadType := r.URL.Query().Get("type")
	allowed, exists := allowedTypes[uploadType]
	if !exists {
		http.Error(w, "invalid upload type: must be 'profile_photo' or 'id_card'", http.StatusBadRequest)
		return
	}

	// 3. Limit request body size to prevent DoS
	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize)

	// 4. Parse multipart form
	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		if strings.Contains(err.Error(), "http: request body too large") {
			http.Error(w, "file too large, max 5MB", http.StatusRequestEntityTooLarge)
			return
		}
		http.Error(w, "failed to parse form", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "missing 'file' field in form data", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// 5. Detect content type from actual file content (not header)
	buf := make([]byte, 512)
	n, err := file.Read(buf)
	if err != nil {
		http.Error(w, "failed to read file", http.StatusInternalServerError)
		return
	}
	contentType := http.DetectContentType(buf[:n])

	// Seek back to the beginning after reading for detection
	if _, err := file.Seek(0, 0); err != nil {
		http.Error(w, "failed to process file", http.StatusInternalServerError)
		return
	}

	// 6. Validate content type against allowed types for this upload type
	ext, typeAllowed := allowed[contentType]
	if !typeAllowed {
		allowedList := make([]string, 0, len(allowed))
		for k := range allowed {
			allowedList = append(allowedList, k)
		}
		http.Error(w,
			fmt.Sprintf("invalid file type '%s' for %s, allowed: %s", contentType, uploadType, strings.Join(allowedList, ", ")),
			http.StatusBadRequest,
		)
		return
	}

	// 7. Generate safe UUID filename
	_ = header // original filename is intentionally ignored for security
	safeFilename := uploadType + "/" + uuid.New().String() + ext

	// 8. Upload to storage
	url, err := h.store.Upload(safeFilename, file)
	if err != nil {
		http.Error(w, "failed to save file", http.StatusInternalServerError)
		return
	}

	// 9. Respond with the URL
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{URL: url})
}

// ServeFile serves uploaded files with security headers.
func ServeFile(uploadDir string) http.Handler {
	fs := http.FileServer(http.Dir(uploadDir))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Prevent directory listing
		if strings.HasSuffix(r.URL.Path, "/") {
			http.NotFound(w, r)
			return
		}

		// Security headers
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "public, max-age=86400")

		ext := strings.ToLower(filepath.Ext(r.URL.Path))
		switch ext {
		case ".jpg", ".jpeg":
			w.Header().Set("Content-Type", "image/jpeg")
		case ".png":
			w.Header().Set("Content-Type", "image/png")
		case ".webp":
			w.Header().Set("Content-Type", "image/webp")
		case ".pdf":
			w.Header().Set("Content-Type", "application/pdf")
		default:
			http.NotFound(w, r)
			return
		}

		fs.ServeHTTP(w, r)
	})
}
