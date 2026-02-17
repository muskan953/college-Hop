package storage

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// FileStorage defines the interface for file storage operations.
// Swap implementations (Local -> S3) without changing business logic.
type FileStorage interface {
	Upload(filename string, file io.Reader) (url string, err error)
	Delete(filename string) error
}

// LocalStorage stores files on the local filesystem.
type LocalStorage struct {
	uploadDir string
	baseURL   string
}

// NewLocalStorage creates a new LocalStorage instance.
// uploadDir: absolute path to the directory where files are saved (e.g., /app/uploads).
// baseURL: the public URL prefix to construct download URLs (e.g., http://localhost:8080/uploads).
func NewLocalStorage(uploadDir string, baseURL string) (*LocalStorage, error) {
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}
	return &LocalStorage{uploadDir: uploadDir, baseURL: baseURL}, nil
}

func (s *LocalStorage) Upload(filename string, file io.Reader) (string, error) {
	destPath := filepath.Join(s.uploadDir, filename)

	destFile, err := os.Create(destPath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer destFile.Close()

	if _, err := io.Copy(destFile, file); err != nil {
		// Clean up the partially written file
		os.Remove(destPath)
		return "", fmt.Errorf("failed to write file: %w", err)
	}

	url := s.baseURL + "/" + filename
	return url, nil
}

func (s *LocalStorage) Delete(filename string) error {
	destPath := filepath.Join(s.uploadDir, filename)
	if err := os.Remove(destPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to delete file: %w", err)
	}
	return nil
}
