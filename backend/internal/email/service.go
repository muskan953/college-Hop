package email

import (
	"fmt"
	"github.com/resend/resend-go/v2"
)

// Service defines the interface for sending transactional emails.
type Service interface {
	SendOTP(toEmail, otp string) error
}

// ResendService implements Service using the Resend API.
type ResendService struct {
	client *resend.Client
	from   string
}

// NewResendService creates a new Resend email service.
func NewResendService(apiKey, fromAddress string) Service {
	client := resend.NewClient(apiKey)
	return &ResendService{
		client: client,
		from:   fromAddress,
	}
}

// SendOTP sends an OTP verification code.
func (s *ResendService) SendOTP(toEmail, otp string) error {
	htmlBody := fmt.Sprintf(`
		<div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; text-align: center; color: #1a1a1a; padding: 40px 20px; background-color: #f9f9fb; border-radius: 12px; max-width: 600px; margin: 0 auto; border: 1px solid #eaeaee;">
			<h1 style="color: #4F46E5; font-size: 28px; margin-bottom: 10px;">Welcome to College Hop! 🎓</h1>
			<p style="font-size: 16px; line-height: 1.6; color: #4b5563; margin-bottom: 30px;">
				We are thrilled to have you join our academic community. To complete your secure sign-in process and verify your student identity, please use the magical code below:
			</p>
			
			<div style="background-color: #ffffff; padding: 30px; border-radius: 12px; font-weight: 800; font-size: 48px; letter-spacing: 12px; color: #111827; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05); border: 2px dashed #e5e7eb; display: inline-block;">
				%s
			</div>
			
			<p style="font-size: 14px; margin-top: 35px; color: #6b7280; line-height: 1.5;">
				<strong>Security Notice:</strong> This code uniquely identifies your session and will expire in exactly 5 minutes. Please do not share this code with anyone. If you didn't request this login, please ignore this email.
			</p>
			
			<hr style="border: none; border-top: 1px solid #e5e7eb; margin: 40px 0 20px 0;" />
			<p style="font-size: 12px; color: #9ca3af;">
				© 2026 College Hop Inc.<br>
				Connecting Students, Building Campuses
			</p>
		</div>
	`, otp)

	params := &resend.SendEmailRequest{
		From:    s.from,
		To:      []string{toEmail},
		Subject: "Your College Hop Verification Code",
		Html:    htmlBody,
	}

	_, err := s.client.Emails.Send(params)
	if err != nil {
		return fmt.Errorf("failed to send OTP email via Resend: %w", err)
	}

	return nil
}

// MockService implements Service for testing purposes without sending real emails.
type MockService struct{}

// NewMockService creates a mock email service.
func NewMockService() Service {
	return &MockService{}
}

// SendOTP simply logs instead of sending.
func (m *MockService) SendOTP(toEmail, otp string) error {
	fmt.Printf("[MOCK EMAIL] Sent OTP %s to %s\n", otp, toEmail)
	return nil
}
