// Package protocol defines the wire types shared by the signaling and data
// planes: the message envelope, the message type names and the error codes.
//
// Everything here is deliberately content-free. The server routes on `to` and
// `from` and never looks inside `payload`, with the single exception of the
// `kind` field, which sits outside the payload precisely so that rate limiting
// pairing requests does not require decrypting or parsing user data.
package protocol

import "net/http"

// Version is the signaling protocol version carried in every envelope.
const Version = 1

// MaxMessageBytes caps a single signaling message.
//
// Signaling carries small JSON only; anything larger is either a bug or an
// attempt to push file data through the cheap plane.
const MaxMessageBytes = 64 * 1024

// MaxSubscribePeers caps how many device ids a single subscribe message may
// list. Without a bound a client could force the hub to allocate and scan an
// arbitrarily large map under the global mutex.
const MaxSubscribePeers = 256

// Signature domain separators. Both are ASCII-prefixed so a signature made for
// one purpose can never be replayed as the other.
const (
	// SigContextAuth covers "icy-relay-auth-v1" ‖ nonce ‖ deviceId, where
	// deviceId contributes its 32 ASCII hex characters.
	SigContextAuth = "icy-relay-auth-v1"
	// SigContextStream covers "icy-relay-stream-v1" ‖ streamId, with streamId
	// again as ASCII hex.
	SigContextStream = "icy-relay-stream-v1"
)

// Message types on the signaling plane.
const (
	TypeChallenge     = "challenge"
	TypeAuth          = "auth"
	TypeWelcome       = "welcome"
	TypeSubscribe     = "subscribe"
	TypePresence      = "presence"
	TypeRelay         = "relay"
	TypeStreamCreate  = "stream.create"
	TypeStreamCreated = "stream.created"
	TypePing          = "ping"
	TypePong          = "pong"
	TypeError         = "error"
)

// Relay kinds, used only to classify a message for rate limiting.
const (
	KindPair     = "pair"
	KindTransfer = "transfer"
)

// Stream roles requested through stream.create.
const (
	RoleSender   = "sender"
	RoleReceiver = "receiver"
)

// Error codes shared by both planes.
const (
	CodeUnauthorized    = "unauthorized"
	CodeBadIdentity     = "bad_identity"
	CodeBadRequest      = "bad_request"
	CodePeerOffline     = "peer_offline"
	CodeStreamNotFound  = "stream_not_found"
	CodeStreamForbidden = "stream_forbidden"
	CodePeerNotAttached = "peer_not_attached"
	CodeTooManyStreams  = "too_many_streams"
	CodePayloadTooLarge = "payload_too_large"
	CodeIdleTimeout     = "idle_timeout"
	CodeRateLimited     = "rate_limited"
	CodeInternal        = "internal"
)

// HTTPStatus maps an error code to the status the data plane returns for it.
func HTTPStatus(code string) int {
	switch code {
	case CodeUnauthorized:
		return http.StatusUnauthorized
	case CodeBadIdentity, CodeStreamForbidden:
		return http.StatusForbidden
	case CodeBadRequest:
		return http.StatusBadRequest
	case CodePeerOffline, CodeStreamNotFound:
		return http.StatusNotFound
	case CodePeerNotAttached:
		return http.StatusGatewayTimeout
	case CodeTooManyStreams, CodeRateLimited:
		return http.StatusTooManyRequests
	case CodePayloadTooLarge:
		return http.StatusRequestEntityTooLarge
	case CodeIdleTimeout:
		return http.StatusRequestTimeout
	default:
		return http.StatusInternalServerError
	}
}

// Envelope is the common header of every signaling message. It is decoded
// first, on its own, to learn the type before decoding the full message.
type Envelope struct {
	V    int    `json:"v"`
	Type string `json:"type"`
	MID  string `json:"mid,omitempty"`
	TS   int64  `json:"ts,omitempty"`
}

// Challenge is sent by the server immediately after the socket opens.
type Challenge struct {
	Envelope
	// Nonce is base64 raw server randomness the client must sign.
	Nonce string `json:"nonce"`
}

// Auth is the client's response to a Challenge.
//
// It carries the three fields the server actually needs and nothing else: no
// device name, platform or app version (decision D3).
type Auth struct {
	Envelope
	DeviceID  string `json:"deviceId"`
	PublicKey string `json:"publicKey"`
	Signature string `json:"signature"`
}

// Limits tells the client the server's operating envelope so it can size its
// own concurrency instead of discovering the ceiling through errors.
type Limits struct {
	MaxConcurrentStreams int   `json:"maxConcurrentStreams"`
	MaxStreamBytes       int64 `json:"maxStreamBytes"`
	MaxMessageBytes      int   `json:"maxMessageBytes"`
	PairRatePerMin       int   `json:"pairRatePerMin"`
}

// Welcome completes the two-layer admission handshake.
type Welcome struct {
	Envelope
	SessionID  string `json:"sessionId"`
	ServerTime int64  `json:"serverTime"`
	Limits     Limits `json:"limits"`
}

// Subscribe replaces the set of peers whose presence this device wants.
type Subscribe struct {
	Envelope
	Peers []string `json:"peers"`
}

// Presence is pushed only when the two devices subscribe to each other, so the
// server cannot be used to probe whether an arbitrary device is online.
type Presence struct {
	Envelope
	DeviceID string `json:"deviceId"`
	Online   bool   `json:"online"`
}

// Relay is an opaque message forwarded between two devices.
//
// Exactly one of To (client to server) and From (server to client) is set.
type Relay struct {
	Envelope
	To      string `json:"to,omitempty"`
	From    string `json:"from,omitempty"`
	Kind    string `json:"kind,omitempty"`
	Payload string `json:"payload"`
}

// StreamCreate asks for a data-plane stream towards Peer.
type StreamCreate struct {
	Envelope
	Peer string `json:"peer"`
	Role string `json:"role"`
}

// StreamCreated returns the capability token for a stream.
type StreamCreated struct {
	Envelope
	StreamID  string `json:"streamId"`
	ExpiresAt int64  `json:"expiresAt"`
}

// Error reports a failure, echoing MID when the failure answers a request.
type Error struct {
	Envelope
	Code    string `json:"code"`
	Message string `json:"message,omitempty"`
}

// NewEnvelope builds a header of the given type.
func NewEnvelope(msgType string, now int64) Envelope {
	return Envelope{V: Version, Type: msgType, TS: now}
}
