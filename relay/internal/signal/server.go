package signal

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/coder/websocket"

	"github.com/icy-easy-send/relay/internal/auth"
	"github.com/icy-easy-send/relay/internal/limit"
	"github.com/icy-easy-send/relay/internal/protocol"
	"github.com/icy-easy-send/relay/internal/stream"
)

// Timing defaults for the signaling plane. See section 5.6 of the design doc.
const (
	DefaultPingInterval = 25 * time.Second
	DefaultPongTimeout  = 10 * time.Second
	DefaultAuthTimeout  = 10 * time.Second
	DefaultWriteTimeout = 10 * time.Second
)

// Observer receives coarse operational counters from the signaling plane.
// Implementations must not retain high-cardinality labels such as device ids.
type Observer interface {
	AuthFailure(reason string)
	Error(code string)
	StreamCreated()
	PairRateLimited()
}

// ServerOptions configures the signaling endpoint.
type ServerOptions struct {
	Hub         *Hub
	Streams     *stream.Registry
	Token       string
	PairLimiter *limit.PairLimiter
	Limits      protocol.Limits
	Observer    Observer

	PingInterval time.Duration
	PongTimeout  time.Duration
	AuthTimeout  time.Duration
	WriteTimeout time.Duration

	Logger *slog.Logger
}

// Server serves the WebSocket endpoint at /v1/signal.
type Server struct {
	opts ServerOptions
}

// NewServer builds the signaling server, filling in default timings.
func NewServer(opts ServerOptions) *Server {
	if opts.PingInterval == 0 {
		opts.PingInterval = DefaultPingInterval
	}
	if opts.PongTimeout == 0 {
		opts.PongTimeout = DefaultPongTimeout
	}
	if opts.AuthTimeout == 0 {
		opts.AuthTimeout = DefaultAuthTimeout
	}
	if opts.WriteTimeout == 0 {
		opts.WriteTimeout = DefaultWriteTimeout
	}
	if opts.Logger == nil {
		opts.Logger = slog.Default()
	}
	return &Server{opts: opts}
}

func (srv *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// First admission layer, before the upgrade: a caller without the token
	// never gets to allocate a WebSocket on this server.
	if !auth.TokenMatches(srv.opts.Token, auth.ParseBearer(r.Header.Get("Authorization"))) {
		if srv.opts.Observer != nil {
			srv.opts.Observer.AuthFailure("token")
			srv.opts.Observer.Error(protocol.CodeUnauthorized)
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(map[string]any{"ok": false, "code": protocol.CodeUnauthorized})
		return
	}

	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		CompressionMode: websocket.CompressionDisabled,
	})
	if err != nil {
		srv.opts.Logger.Debug("websocket upgrade failed", "err", err)
		return
	}
	defer conn.CloseNow()

	conn.SetReadLimit(protocol.MaxMessageBytes)

	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	session, err := srv.handshake(ctx, conn, cancel)
	if err != nil {
		srv.rejectHandshake(conn, err)
		return
	}
	defer srv.teardown(session)

	go session.writeLoop(ctx, srv.opts.WriteTimeout)
	go session.pingLoop(ctx, srv.opts.PingInterval, srv.opts.PongTimeout)

	srv.readLoop(ctx, session)
}

// handshake runs the second admission layer: prove ownership of the key whose
// fingerprint is the claimed device id.
func (srv *Server) handshake(ctx context.Context, conn *websocket.Conn, cancel context.CancelFunc) (*Session, error) {
	nonce, err := auth.NewNonce()
	if err != nil {
		return nil, err
	}

	challenge := protocol.Challenge{
		Envelope: protocol.NewEnvelope(protocol.TypeChallenge, time.Now().Unix()),
		Nonce:    base64.StdEncoding.EncodeToString(nonce),
	}
	if err := writeJSON(ctx, conn, srv.opts.WriteTimeout, challenge); err != nil {
		return nil, err
	}

	authCtx, cancelAuth := context.WithTimeout(ctx, srv.opts.AuthTimeout)
	defer cancelAuth()

	_, data, err := conn.Read(authCtx)
	if err != nil {
		return nil, err
	}

	var msg protocol.Auth
	if err := json.Unmarshal(data, &msg); err != nil || msg.Type != protocol.TypeAuth {
		return nil, errBadRequest
	}

	publicKey, err := auth.VerifyIdentity(msg.DeviceID, msg.PublicKey, msg.Signature, nonce)
	if err != nil {
		return nil, err
	}

	sessionID, err := newSessionID()
	if err != nil {
		return nil, err
	}

	session := newSession(msg.DeviceID, sessionID, publicKey, conn, cancel)

	// A device reconnecting after a network drop can arrive before the server
	// has noticed the old socket is dead. The newest connection wins.
	if previous := srv.opts.Hub.Register(session); previous != nil {
		previous.Close()
		srv.opts.Logger.Debug("replaced stale session", "device", shortID(msg.DeviceID))
	}

	welcome := protocol.Welcome{
		Envelope:   protocol.NewEnvelope(protocol.TypeWelcome, time.Now().Unix()),
		SessionID:  sessionID,
		ServerTime: time.Now().Unix(),
		Limits:     srv.opts.Limits,
	}
	if err := writeJSON(ctx, conn, srv.opts.WriteTimeout, welcome); err != nil {
		srv.opts.Hub.Unregister(session)
		return nil, err
	}

	srv.opts.Logger.Debug("device connected", "device", shortID(msg.DeviceID), "online", srv.opts.Hub.Count())
	return session, nil
}

func (srv *Server) rejectHandshake(conn *websocket.Conn, err error) {
	code := protocol.CodeBadIdentity
	switch {
	case errors.Is(err, errBadRequest):
		code = protocol.CodeBadRequest
	case errors.Is(err, auth.ErrBadPublicKey),
		errors.Is(err, auth.ErrDeviceIDMismatch),
		errors.Is(err, auth.ErrBadSignature):
		code = protocol.CodeBadIdentity
	default:
		// A read timeout or a client that hung up needs no explanation.
		conn.Close(websocket.StatusPolicyViolation, "handshake incomplete")
		return
	}

	if srv.opts.Observer != nil {
		if code == protocol.CodeBadIdentity {
			srv.opts.Observer.AuthFailure("identity")
		}
		srv.opts.Observer.Error(code)
	}
	srv.opts.Logger.Debug("handshake rejected", "code", code)
	conn.Close(websocket.StatusPolicyViolation, code)
}

func (srv *Server) teardown(session *Session) {
	session.Close()

	// Unregister is a no-op when a newer connection already replaced this
	// session. In that case the device is still online and its streams must
	// not be torn down.
	watchers, removed := srv.opts.Hub.Unregister(session)
	if !removed {
		return
	}

	for _, watcher := range watchers {
		watcher.Send(presenceMessage(session.DeviceID, false))
	}
	// Idle and half-attached streams die with the signaling session. Fully
	// attached transfers keep running until the data-plane handler releases them.
	if srv.opts.Streams != nil {
		srv.opts.Streams.ReleaseDevice(session.DeviceID)
	}
	srv.opts.Logger.Debug("device disconnected", "device", shortID(session.DeviceID), "online", srv.opts.Hub.Count())
}

func (srv *Server) readLoop(ctx context.Context, session *Session) {
	for {
		_, data, err := session.conn.Read(ctx)
		if err != nil {
			return
		}
		srv.dispatch(session, data)
	}
}

func (srv *Server) dispatch(session *Session, data []byte) {
	var envelope protocol.Envelope
	if err := json.Unmarshal(data, &envelope); err != nil {
		srv.sendError(session, "", protocol.CodeBadRequest, "malformed message")
		return
	}

	switch envelope.Type {
	case protocol.TypeSubscribe:
		srv.handleSubscribe(session, data)
	case protocol.TypeRelay:
		srv.handleRelay(session, data, envelope.MID)
	case protocol.TypeStreamCreate:
		srv.handleStreamCreate(session, data, envelope.MID)
	case protocol.TypePing:
		pong := protocol.NewEnvelope(protocol.TypePong, time.Now().Unix())
		pong.MID = envelope.MID
		session.Send(pong)
	default:
		srv.sendError(session, envelope.MID, protocol.CodeBadRequest, "unknown message type")
	}
}

func (srv *Server) sendError(session *Session, mid, code, message string) {
	if srv.opts.Observer != nil {
		srv.opts.Observer.Error(code)
	}
	session.SendError(mid, code, message)
}

func (srv *Server) handleSubscribe(session *Session, data []byte) {
	var msg protocol.Subscribe
	if err := json.Unmarshal(data, &msg); err != nil {
		srv.sendError(session, "", protocol.CodeBadRequest, "malformed subscribe")
		return
	}
	if len(msg.Peers) > protocol.MaxSubscribePeers {
		srv.sendError(session, "", protocol.CodeBadRequest, "too many peers in subscribe")
		return
	}

	for _, update := range srv.opts.Hub.Subscribe(session.DeviceID, msg.Peers) {
		update.To.Send(presenceMessage(update.DeviceID, update.Online))
	}
}

func (srv *Server) handleRelay(session *Session, data []byte, mid string) {
	var msg protocol.Relay
	if err := json.Unmarshal(data, &msg); err != nil {
		srv.sendError(session, mid, protocol.CodeBadRequest, "malformed relay")
		return
	}
	if msg.To == "" || msg.To == session.DeviceID {
		srv.sendError(session, mid, protocol.CodeBadRequest, "invalid relay target")
		return
	}

	// The only field the server inspects. Pairing is forwarded without
	// requiring a mutual subscription, so it is the one kind that has to be
	// rate limited on its own.
	if msg.Kind == protocol.KindPair && !srv.opts.PairLimiter.Allow(session.DeviceID) {
		if srv.opts.Observer != nil {
			srv.opts.Observer.PairRateLimited()
		}
		srv.sendError(session, mid, protocol.CodeRateLimited, "too many pairing requests")
		return
	}

	target, ok := srv.opts.Hub.Lookup(msg.To)
	if !ok {
		srv.sendError(session, mid, protocol.CodePeerOffline, "peer is not connected")
		return
	}

	forwarded := protocol.Relay{
		Envelope: protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix()),
		From:     session.DeviceID,
		Kind:     msg.Kind,
		Payload:  msg.Payload,
	}
	forwarded.MID = msg.MID

	if !target.Send(forwarded) {
		srv.sendError(session, mid, protocol.CodePeerOffline, "peer is not reachable")
	}
}

func (srv *Server) handleStreamCreate(session *Session, data []byte, mid string) {
	var msg protocol.StreamCreate
	if err := json.Unmarshal(data, &msg); err != nil {
		srv.sendError(session, mid, protocol.CodeBadRequest, "malformed stream.create")
		return
	}
	if msg.Peer == "" || msg.Peer == session.DeviceID {
		srv.sendError(session, mid, protocol.CodeBadRequest, "invalid stream peer")
		return
	}

	var sender, receiver string
	switch msg.Role {
	case protocol.RoleSender:
		sender, receiver = session.DeviceID, msg.Peer
	case protocol.RoleReceiver:
		sender, receiver = msg.Peer, session.DeviceID
	default:
		srv.sendError(session, mid, protocol.CodeBadRequest, "role must be sender or receiver")
		return
	}

	// Allocating a stream towards an offline peer would only burn a quota slot
	// and fail at rendezvous, so it is refused up front.
	if _, ok := srv.opts.Hub.Lookup(msg.Peer); !ok {
		srv.sendError(session, mid, protocol.CodePeerOffline, "peer is not connected")
		return
	}

	s, err := srv.opts.Streams.Create(session.DeviceID, sender, receiver)
	if err != nil {
		if errors.Is(err, stream.ErrTooManyStreams) {
			srv.sendError(session, mid, protocol.CodeTooManyStreams, "concurrent stream limit reached")
			return
		}
		srv.sendError(session, mid, protocol.CodeInternal, "could not allocate stream")
		return
	}
	if srv.opts.Observer != nil {
		srv.opts.Observer.StreamCreated()
	}

	created := protocol.StreamCreated{
		Envelope:  protocol.NewEnvelope(protocol.TypeStreamCreated, time.Now().Unix()),
		StreamID:  s.ID,
		ExpiresAt: s.ExpiresAt.Unix(),
	}
	created.MID = mid
	session.Send(created)
}

var errBadRequest = errors.New(protocol.CodeBadRequest)

func presenceMessage(deviceID string, online bool) protocol.Presence {
	return protocol.Presence{
		Envelope: protocol.NewEnvelope(protocol.TypePresence, time.Now().Unix()),
		DeviceID: deviceID,
		Online:   online,
	}
}

func writeJSON(ctx context.Context, conn *websocket.Conn, timeout time.Duration, msg any) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	writeCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	return conn.Write(writeCtx, websocket.MessageText, data)
}

func newSessionID() (string, error) {
	raw := make([]byte, 16)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return hex.EncodeToString(raw), nil
}

// shortID trims a device id for logging.
//
// Even at debug level only the first 8 characters are recorded, so logs never
// carry a value that identifies a device across servers.
func shortID(deviceID string) string {
	if len(deviceID) <= 8 {
		return deviceID
	}
	return deviceID[:8]
}
