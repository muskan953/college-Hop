package auth

import "context"

type contextKey string

const userContextKey contextKey = "user"

type UserContext struct {
	ID    string
	Email string
}

func WithUser(ctx context.Context, user UserContext) context.Context {
	return context.WithValue(ctx, userContextKey, user)
}

func UserFromContext(ctx context.Context) (UserContext, bool) {
	user, ok := ctx.Value(userContextKey).(UserContext)
	return user, ok
}
