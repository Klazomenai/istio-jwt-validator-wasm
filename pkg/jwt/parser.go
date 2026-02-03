package jwt

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
)

// ValidateRequest represents the JSON request body for /api/validate
type ValidateRequest struct {
	Token string `json:"token"`
}

// ParseFromJSON extracts JWT token from request body
func ParseFromJSON(body []byte) (string, error) {
	var req ValidateRequest
	if err := json.Unmarshal(body, &req); err != nil {
		return "", err
	}
	if req.Token == "" {
		return "", errors.New("token field is empty")
	}

	// Validate JWT format (3 parts separated by dots)
	parts := strings.Split(req.Token, ".")
	if len(parts) != 3 {
		return "", errors.New("invalid JWT format: expected 3 parts")
	}

	return req.Token, nil
}

// ExtractJTI extracts JTI claim from JWT payload (without signature verification)
func ExtractJTI(token string) (string, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return "", errors.New("invalid JWT format")
	}

	// Decode payload (second part)
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", err
	}

	// Parse JSON claims
	var claims map[string]interface{}
	if err := json.Unmarshal(payload, &claims); err != nil {
		return "", err
	}

	// Extract jti claim
	jti, ok := claims["jti"].(string)
	if !ok {
		return "", errors.New("jti claim not found or not a string")
	}

	return jti, nil
}
