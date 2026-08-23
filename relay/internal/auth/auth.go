// Package auth implements relayd's two admission layers.
//
// The bearer token answers "who may consume my bandwidth"; the Ed25519
// challenge-response answers "who may claim this deviceId". Neither is
// sufficient alone: with only a token, anyone holding it could impersonate any
// device and intercept its incoming files; with only signatures, anyone at all
// could use the server for free.
package auth

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"strings"

	"github.com/icy-easy-send/relay/internal/protocol"
)

// DeviceIDBytes is how many bytes of the public key digest form a device id.
const DeviceIDBytes = 16

// NonceBytes is the length of the server's authentication challenge.
const NonceBytes = 16

var (
	// ErrBadPublicKey means the key was missing, malformed or the wrong size.
	ErrBadPublicKey = errors.New("public key is not a 32-byte Ed25519 key")
	// ErrDeviceIDMismatch means the claimed id is not the key's fingerprint.
	ErrDeviceIDMismatch = errors.New("deviceId is not the fingerprint of the public key")
	// ErrBadSignature means the challenge response did not verify.
	ErrBadSignature = errors.New("signature does not verify")
)

// ParseBearer extracts the token from an Authorization header.
//
// Returns an empty string when the header is absent or not a bearer scheme,
// which callers must treat as unauthorized.
func ParseBearer(header string) string {
	const prefix = "bearer "
	if len(header) <= len(prefix) || !strings.EqualFold(header[:len(prefix)], prefix) {
		return ""
	}
	return strings.TrimSpace(header[len(prefix):])
}

// TokenMatches compares tokens without leaking their contents through timing.
func TokenMatches(expected, provided string) bool {
	return subtle.ConstantTimeCompare([]byte(expected), []byte(provided)) == 1
}

// NewNonce returns fresh challenge randomness.
func NewNonce() ([]byte, error) {
	nonce := make([]byte, NonceBytes)
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	return nonce, nil
}

// DeviceIDFromPublicKey derives the canonical device id: the first 16 bytes of
// SHA-256 over the raw public key, hex encoded.
//
// This must stay byte-identical to IdentityService.deviceIdFromPublicKey on
// the Dart side; the whole anti-impersonation property rests on both ends
// computing the same value.
func DeviceIDFromPublicKey(publicKey []byte) string {
	digest := sha256.Sum256(publicKey)
	return hex.EncodeToString(digest[:DeviceIDBytes])
}

// DecodePublicKey parses a base64 Ed25519 public key.
func DecodePublicKey(encoded string) (ed25519.PublicKey, error) {
	raw, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil || len(raw) != ed25519.PublicKeySize {
		return nil, ErrBadPublicKey
	}
	return ed25519.PublicKey(raw), nil
}

// AuthMessage is the exact byte string a client signs to prove key ownership.
//
// The device id is included so a signature captured from one device cannot be
// replayed by another that happens to observe the same nonce.
func AuthMessage(nonce []byte, deviceID string) []byte {
	msg := make([]byte, 0, len(protocol.SigContextAuth)+len(nonce)+len(deviceID))
	msg = append(msg, protocol.SigContextAuth...)
	msg = append(msg, nonce...)
	msg = append(msg, deviceID...)
	return msg
}

// StreamMessage is the byte string a client signs to attach to a stream.
func StreamMessage(streamID string) []byte {
	msg := make([]byte, 0, len(protocol.SigContextStream)+len(streamID))
	msg = append(msg, protocol.SigContextStream...)
	msg = append(msg, streamID...)
	return msg
}

// VerifyIdentity checks a challenge response end to end: the key is well
// formed, the claimed id really is its fingerprint, and the signature over the
// nonce verifies.
//
// It returns the parsed key so callers can keep it for later stream proofs.
func VerifyIdentity(deviceID, encodedPublicKey, encodedSignature string, nonce []byte) (ed25519.PublicKey, error) {
	publicKey, err := DecodePublicKey(encodedPublicKey)
	if err != nil {
		return nil, err
	}
	if DeviceIDFromPublicKey(publicKey) != deviceID {
		return nil, ErrDeviceIDMismatch
	}
	signature, err := base64.StdEncoding.DecodeString(encodedSignature)
	if err != nil {
		return nil, ErrBadSignature
	}
	if !ed25519.Verify(publicKey, AuthMessage(nonce, deviceID), signature) {
		return nil, ErrBadSignature
	}
	return publicKey, nil
}

// VerifyStreamProof checks the X-Stream-Proof header for a stream attachment.
//
// The stream id is already a 256-bit capability, so this is defence in depth:
// it costs one verification and removes the risk that an id leaked through a
// log or a proxy becomes usable by whoever read it.
func VerifyStreamProof(publicKey ed25519.PublicKey, streamID, encodedSignature string) error {
	signature, err := base64.StdEncoding.DecodeString(encodedSignature)
	if err != nil {
		return ErrBadSignature
	}
	if !ed25519.Verify(publicKey, StreamMessage(streamID), signature) {
		return ErrBadSignature
	}
	return nil
}
