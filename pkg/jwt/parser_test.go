package jwt

import (
	"encoding/base64"
	"encoding/json"
	"testing"
)

func TestParseFromJSON(t *testing.T) {
	tests := []struct {
		name    string
		body    []byte
		want    string
		wantErr bool
	}{
		{
			name: "valid JWT",
			body: []byte(`{"token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJ0ZXN0LWp0aSJ9.c2lnbmF0dXJl"}`),
			want: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJ0ZXN0LWp0aSJ9.c2lnbmF0dXJl",
		},
		{
			name:    "empty token",
			body:    []byte(`{"token":""}`),
			wantErr: true,
		},
		{
			name:    "missing token field",
			body:    []byte(`{}`),
			wantErr: true,
		},
		{
			name:    "invalid JSON",
			body:    []byte(`not json`),
			wantErr: true,
		},
		{
			name:    "invalid JWT format (2 parts)",
			body:    []byte(`{"token":"header.payload"}`),
			wantErr: true,
		},
		{
			name:    "invalid JWT format (4 parts)",
			body:    []byte(`{"token":"a.b.c.d"}`),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseFromJSON(tt.body)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseFromJSON() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("ParseFromJSON() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestExtractJTI(t *testing.T) {
	// Helper to create JWT with specific JTI
	createJWT := func(jti string) string {
		header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","typ":"JWT"}`))
		payload, err := json.Marshal(map[string]interface{}{"jti": jti})
		if err != nil {
			t.Fatalf("Failed to marshal test payload: %v", err)
		}
		encodedPayload := base64.RawURLEncoding.EncodeToString(payload)
		signature := base64.RawURLEncoding.EncodeToString([]byte("signature"))
		return header + "." + encodedPayload + "." + signature
	}

	// Helper to create JWT with specific claim value (any type)
	createJWTWithClaim := func(key string, value interface{}) string {
		header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","typ":"JWT"}`))
		payload, err := json.Marshal(map[string]interface{}{key: value})
		if err != nil {
			t.Fatalf("Failed to marshal test payload: %v", err)
		}
		encodedPayload := base64.RawURLEncoding.EncodeToString(payload)
		signature := base64.RawURLEncoding.EncodeToString([]byte("signature"))
		return header + "." + encodedPayload + "." + signature
	}

	tests := []struct {
		name    string
		token   string
		want    string
		wantErr bool
	}{
		{
			name:  "valid token with JTI",
			token: createJWT("test-jti-123"),
			want:  "test-jti-123",
		},
		{
			name:    "invalid format (2 parts)",
			token:   "header.payload",
			wantErr: true,
		},
		{
			name:    "invalid base64 payload",
			token:   "header.!!!invalid!!!.signature",
			wantErr: true,
		},
		{
			name: "missing JTI claim",
			token: func() string {
				header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","typ":"JWT"}`))
				payload, err := json.Marshal(map[string]interface{}{"sub": "user123"}) // no jti field
				if err != nil {
					t.Fatalf("Failed to marshal test payload: %v", err)
				}
				encodedPayload := base64.RawURLEncoding.EncodeToString(payload)
				signature := base64.RawURLEncoding.EncodeToString([]byte("signature"))
				return header + "." + encodedPayload + "." + signature
			}(),
			wantErr: true,
		},
		{
			name:    "valid base64, invalid JSON payload",
			token:   "header." + base64.RawURLEncoding.EncodeToString([]byte("not valid json")) + ".signature",
			wantErr: true,
		},
		{
			name:    "jti claim is number not string",
			token:   createJWTWithClaim("jti", 12345),
			wantErr: true,
		},
		{
			name:    "jti claim is boolean not string",
			token:   createJWTWithClaim("jti", true),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ExtractJTI(tt.token)
			if (err != nil) != tt.wantErr {
				t.Errorf("ExtractJTI() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("ExtractJTI() = %v, want %v", got, tt.want)
			}
		})
	}
}
