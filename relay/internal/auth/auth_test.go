package auth

import (
	"crypto/ed25519"
	"encoding/base64"
	"testing"
)

func newIdentity(t *testing.T) (ed25519.PublicKey, ed25519.PrivateKey, string) {
	t.Helper()
	public, private, err := ed25519.GenerateKey(nil)
	if err != nil {
		t.Fatalf("GenerateKey: %v", err)
	}
	return public, private, DeviceIDFromPublicKey(public)
}

func TestParseBearer(t *testing.T) {
	cases := map[string]string{
		"Bearer secret":    "secret",
		"bearer secret":    "secret",
		"BEARER   secret ": "secret",
		"Basic secret":     "",
		"Bearer":           "",
		"":                 "",
		"secret":           "",
	}

	for header, want := range cases {
		if got := ParseBearer(header); got != want {
			t.Errorf("ParseBearer(%q) = %q, want %q", header, got, want)
		}
	}
}

func TestTokenMatches(t *testing.T) {
	if !TokenMatches("abc", "abc") {
		t.Error("identical tokens should match")
	}
	if TokenMatches("abc", "abd") || TokenMatches("abc", "ab") || TokenMatches("abc", "") {
		t.Error("differing tokens must not match")
	}
}

func TestDeviceIDFromPublicKey(t *testing.T) {
	public, _, deviceID := newIdentity(t)

	if len(deviceID) != DeviceIDBytes*2 {
		t.Fatalf("deviceId length = %d, want %d", len(deviceID), DeviceIDBytes*2)
	}
	if DeviceIDFromPublicKey(public) != deviceID {
		t.Error("derivation must be deterministic")
	}

	other, _, otherID := newIdentity(t)
	if otherID == deviceID {
		t.Error("different keys must produce different ids")
	}
	_ = other
}

func TestDecodePublicKeyRejectsMalformedInput(t *testing.T) {
	cases := map[string]string{
		"empty":        "",
		"not base64":   "!!!!",
		"wrong size":   base64.StdEncoding.EncodeToString(make([]byte, 16)),
		"almost right": base64.StdEncoding.EncodeToString(make([]byte, 33)),
	}

	for name, encoded := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := DecodePublicKey(encoded); err == nil {
				t.Fatal("expected an error")
			}
		})
	}
}

func TestVerifyIdentityAcceptsAWellFormedResponse(t *testing.T) {
	public, private, deviceID := newIdentity(t)
	nonce, err := NewNonce()
	if err != nil {
		t.Fatalf("NewNonce: %v", err)
	}

	signature := ed25519.Sign(private, AuthMessage(nonce, deviceID))

	got, err := VerifyIdentity(
		deviceID,
		base64.StdEncoding.EncodeToString(public),
		base64.StdEncoding.EncodeToString(signature),
		nonce,
	)
	if err != nil {
		t.Fatalf("VerifyIdentity: %v", err)
	}
	if !got.Equal(public) {
		t.Error("returned key should be the one that was verified")
	}
}

func TestVerifyIdentityRejectsForgedDeviceID(t *testing.T) {
	public, private, deviceID := newIdentity(t)
	_, _, victimID := newIdentity(t)
	nonce, _ := NewNonce()

	// Sign correctly, but claim to be somebody else. This is the attack the
	// fingerprint check exists to stop: with only a token, anyone could
	// otherwise connect as a device that is expecting to receive files.
	signature := ed25519.Sign(private, AuthMessage(nonce, victimID))

	_, err := VerifyIdentity(
		victimID,
		base64.StdEncoding.EncodeToString(public),
		base64.StdEncoding.EncodeToString(signature),
		nonce,
	)
	if err != ErrDeviceIDMismatch {
		t.Fatalf("err = %v, want ErrDeviceIDMismatch", err)
	}
	_ = deviceID
}

func TestVerifyIdentityRejectsReplayedNonce(t *testing.T) {
	public, private, deviceID := newIdentity(t)
	firstNonce, _ := NewNonce()
	secondNonce, _ := NewNonce()

	signature := ed25519.Sign(private, AuthMessage(firstNonce, deviceID))

	_, err := VerifyIdentity(
		deviceID,
		base64.StdEncoding.EncodeToString(public),
		base64.StdEncoding.EncodeToString(signature),
		secondNonce,
	)
	if err != ErrBadSignature {
		t.Fatalf("err = %v, want ErrBadSignature", err)
	}
}

func TestVerifyIdentityRejectsMalformedSignature(t *testing.T) {
	public, _, deviceID := newIdentity(t)
	nonce, _ := NewNonce()

	_, err := VerifyIdentity(
		deviceID,
		base64.StdEncoding.EncodeToString(public),
		"not base64!!",
		nonce,
	)
	if err != ErrBadSignature {
		t.Fatalf("err = %v, want ErrBadSignature", err)
	}
}

func TestStreamProof(t *testing.T) {
	public, private, _ := newIdentity(t)
	const streamID = "6f1c2d3e4f5a6b7c"

	valid := base64.StdEncoding.EncodeToString(ed25519.Sign(private, StreamMessage(streamID)))
	if err := VerifyStreamProof(public, streamID, valid); err != nil {
		t.Fatalf("VerifyStreamProof: %v", err)
	}

	if err := VerifyStreamProof(public, "another-stream", valid); err != ErrBadSignature {
		t.Error("a proof for one stream must not attach to another")
	}
	if err := VerifyStreamProof(public, streamID, "%%%"); err != ErrBadSignature {
		t.Error("malformed proof should be rejected")
	}
}

func TestAuthAndStreamContextsAreDistinct(t *testing.T) {
	_, private, deviceID := newIdentity(t)
	nonce, _ := NewNonce()

	// The domain separators must keep a signature made for one purpose from
	// being accepted for the other.
	authSig := ed25519.Sign(private, AuthMessage(nonce, deviceID))
	streamSig := ed25519.Sign(private, StreamMessage(deviceID))

	if string(authSig) == string(streamSig) {
		t.Fatal("auth and stream signatures over related input must differ")
	}
}
