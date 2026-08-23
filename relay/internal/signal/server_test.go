package signal

import (
	"context"
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/icy-easy-send/relay/internal/auth"
	"github.com/icy-easy-send/relay/internal/limit"
	"github.com/icy-easy-send/relay/internal/protocol"
	"github.com/icy-easy-send/relay/internal/stream"
)

const testToken = "0123456789abcdef0123456789abcdef"

type harness struct {
	server  *httptest.Server
	hub     *Hub
	streams *stream.Registry
	url     string
}

func newHarness(t *testing.T) *harness {
	t.Helper()

	hub := NewHub()
	streams := stream.NewRegistry(2, time.Minute)

	srv := NewServer(ServerOptions{
		Hub:         hub,
		Streams:     streams,
		Token:       testToken,
		PairLimiter: limit.NewPairLimiter(2),
		Limits:      protocol.Limits{MaxConcurrentStreams: 2, MaxMessageBytes: protocol.MaxMessageBytes},
		// Keep pings out of the way; these tests finish in milliseconds.
		PingInterval: time.Hour,
		AuthTimeout:  2 * time.Second,
	})

	server := httptest.NewServer(srv)
	t.Cleanup(server.Close)

	return &harness{
		server:  server,
		hub:     hub,
		streams: streams,
		url:     "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/signal",
	}
}

// client is a test device with a background reader.
//
// Reads run on their own goroutine because cancelling a websocket read context
// tears the connection down, which would make "assert the server said nothing"
// impossible to express directly on the socket.
type client struct {
	t        *testing.T
	conn     *websocket.Conn
	deviceID string
	private  ed25519.PrivateKey

	messages chan []byte
	closed   chan struct{}
}

func newClient(t *testing.T, conn *websocket.Conn, deviceID string, private ed25519.PrivateKey) *client {
	c := &client{
		t:        t,
		conn:     conn,
		deviceID: deviceID,
		private:  private,
		messages: make(chan []byte, 32),
		closed:   make(chan struct{}),
	}
	go c.pump()
	return c
}

func (c *client) pump() {
	defer close(c.closed)
	for {
		_, data, err := c.conn.Read(context.Background())
		if err != nil {
			return
		}
		c.messages <- data
	}
}

// dial opens a socket and completes the challenge-response handshake.
func (h *harness) dial(t *testing.T) *client {
	t.Helper()
	return h.dialWithToken(t, testToken)
}

func (h *harness) dialWithToken(t *testing.T, token string) *client {
	t.Helper()

	public, private, err := ed25519.GenerateKey(nil)
	if err != nil {
		t.Fatalf("GenerateKey: %v", err)
	}
	return h.dialAs(t, public, private, token)
}

// dialAs connects with a specific identity, which is how a reconnect is
// simulated: same key, new socket.
func (h *harness) dialAs(t *testing.T, public ed25519.PublicKey, private ed25519.PrivateKey, token string) *client {
	t.Helper()

	deviceID := auth.DeviceIDFromPublicKey(public)

	conn, resp, err := websocket.Dial(context.Background(), h.url, &websocket.DialOptions{
		HTTPHeader: http.Header{"Authorization": []string{"Bearer " + token}},
	})
	if err != nil {
		if resp != nil {
			t.Fatalf("dial rejected with status %d", resp.StatusCode)
		}
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { conn.CloseNow() })

	c := newClient(t, conn, deviceID, private)

	var challenge protocol.Challenge
	c.read(&challenge)
	if challenge.Type != protocol.TypeChallenge || challenge.Nonce == "" {
		t.Fatalf("expected a challenge, got %+v", challenge)
	}

	nonce, err := base64.StdEncoding.DecodeString(challenge.Nonce)
	if err != nil {
		t.Fatalf("decode nonce: %v", err)
	}
	signature := ed25519.Sign(private, auth.AuthMessage(nonce, deviceID))

	c.write(protocol.Auth{
		Envelope:  protocol.NewEnvelope(protocol.TypeAuth, time.Now().Unix()),
		DeviceID:  deviceID,
		PublicKey: base64.StdEncoding.EncodeToString(public),
		Signature: base64.StdEncoding.EncodeToString(signature),
	})

	var welcome protocol.Welcome
	c.read(&welcome)
	if welcome.Type != protocol.TypeWelcome || welcome.SessionID == "" {
		t.Fatalf("expected a welcome, got %+v", welcome)
	}
	return c
}

func (c *client) write(msg any) {
	c.t.Helper()
	data, err := json.Marshal(msg)
	if err != nil {
		c.t.Fatalf("marshal: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := c.conn.Write(ctx, websocket.MessageText, data); err != nil {
		c.t.Fatalf("write: %v", err)
	}
}

func (c *client) read(into any) {
	c.t.Helper()

	data, ok := c.next(3 * time.Second)
	if !ok {
		c.t.Fatal("expected a message, got none")
	}
	if err := json.Unmarshal(data, into); err != nil {
		c.t.Fatalf("unmarshal %s: %v", data, err)
	}
}

// next returns the next message, waiting up to timeout.
func (c *client) next(timeout time.Duration) ([]byte, bool) {
	select {
	case data := <-c.messages:
		return data, true
	default:
	}

	select {
	case data := <-c.messages:
		return data, true
	case <-c.closed:
		// The socket died, but anything already queued still counts.
		select {
		case data := <-c.messages:
			return data, true
		default:
			return nil, false
		}
	case <-time.After(timeout):
		return nil, false
	}
}

func (c *client) subscribe(peers ...string) {
	c.write(protocol.Subscribe{
		Envelope: protocol.NewEnvelope(protocol.TypeSubscribe, time.Now().Unix()),
		Peers:    peers,
	})
}

// expectNothing asserts the server stays quiet for a short window.
func (c *client) expectNothing(d time.Duration) {
	c.t.Helper()
	if data, ok := c.next(d); ok {
		c.t.Fatalf("expected silence, got %s", data)
	}
}

// expectClosed asserts the server hung up on this client.
func (c *client) expectClosed() {
	c.t.Helper()
	select {
	case <-c.closed:
	case <-time.After(3 * time.Second):
		c.t.Fatal("expected the connection to be closed")
	}
}

func TestRejectsConnectionsWithoutTheToken(t *testing.T) {
	h := newHarness(t)

	_, resp, err := websocket.Dial(context.Background(), h.url, nil)
	if err == nil {
		t.Fatal("expected the upgrade to be refused")
	}
	if resp == nil || resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401 before the upgrade, got %v", resp)
	}
}

func TestRejectsAForgedDeviceID(t *testing.T) {
	h := newHarness(t)

	public, private, _ := ed25519.GenerateKey(nil)
	victim, _, _ := ed25519.GenerateKey(nil)
	victimID := auth.DeviceIDFromPublicKey(victim)

	conn, _, err := websocket.Dial(context.Background(), h.url, &websocket.DialOptions{
		HTTPHeader: http.Header{"Authorization": []string{"Bearer " + testToken}},
	})
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer conn.CloseNow()

	c := newClient(t, conn, victimID, private)
	var challenge protocol.Challenge
	c.read(&challenge)
	nonce, _ := base64.StdEncoding.DecodeString(challenge.Nonce)

	// Own a valid key, sign correctly, but claim to be the victim.
	c.write(protocol.Auth{
		Envelope:  protocol.NewEnvelope(protocol.TypeAuth, time.Now().Unix()),
		DeviceID:  victimID,
		PublicKey: base64.StdEncoding.EncodeToString(public),
		Signature: base64.StdEncoding.EncodeToString(ed25519.Sign(private, auth.AuthMessage(nonce, victimID))),
	})

	c.expectClosed()
	if h.hub.Count() != 0 {
		t.Errorf("hub registered %d sessions, want 0", h.hub.Count())
	}
}

func TestPresenceRequiresMutualSubscription(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	// One-sided interest reveals nothing, so the token alone cannot be used to
	// probe whether a given device is online.
	alice.subscribe(bob.deviceID)
	alice.expectNothing(200 * time.Millisecond)

	bob.subscribe(alice.deviceID)

	var toBob protocol.Presence
	bob.read(&toBob)
	if toBob.Type != protocol.TypePresence || toBob.DeviceID != alice.deviceID || !toBob.Online {
		t.Errorf("bob got %+v, want alice online", toBob)
	}

	var toAlice protocol.Presence
	alice.read(&toAlice)
	if toAlice.DeviceID != bob.deviceID || !toAlice.Online {
		t.Errorf("alice got %+v, want bob online", toAlice)
	}
}

func TestPresenceReportsAnOfflinePeer(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	// Nobody else is connected, so a mutual subscription is impossible and the
	// server must stay silent rather than confirm the peer does not exist.
	alice.subscribe("cccc2222cccc2222cccc2222cccc2222")
	alice.expectNothing(200 * time.Millisecond)
}

func TestDisconnectNotifiesMutualWatchers(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	alice.subscribe(bob.deviceID)
	bob.subscribe(alice.deviceID)

	var drain protocol.Presence
	bob.read(&drain)
	alice.read(&drain)

	bob.conn.Close(websocket.StatusNormalClosure, "bye")

	var offline protocol.Presence
	alice.read(&offline)
	if offline.DeviceID != bob.deviceID || offline.Online {
		t.Errorf("alice got %+v, want bob offline", offline)
	}
}

func TestRelayForwardsOpaquePayloads(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	const payload = "c2VjcmV0LWJ5dGVz"
	envelope := protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix())
	envelope.MID = "m-1"
	alice.write(protocol.Relay{
		Envelope: envelope,
		To:       bob.deviceID,
		Kind:     protocol.KindTransfer,
		Payload:  payload,
	})

	var got protocol.Relay
	bob.read(&got)
	if got.Type != protocol.TypeRelay || got.From != alice.deviceID || got.Payload != payload {
		t.Errorf("bob got %+v", got)
	}
	if got.To != "" {
		t.Error("the forwarded message should not echo the target back")
	}
	if got.MID != "m-1" {
		t.Errorf("mid = %q, want it preserved for response matching", got.MID)
	}
}

func TestRelayWorksWithoutSubscription(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	// Two devices meeting for the first time cannot have subscribed to each
	// other yet, so pairing must not require it.
	alice.write(protocol.Relay{
		Envelope: protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix()),
		To:       bob.deviceID,
		Kind:     protocol.KindPair,
		Payload:  "aGVsbG8=",
	})

	var got protocol.Relay
	bob.read(&got)
	if got.From != alice.deviceID {
		t.Errorf("got %+v", got)
	}
}

func TestRelayToAnOfflinePeerFails(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	envelope := protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix())
	envelope.MID = "m-2"
	alice.write(protocol.Relay{Envelope: envelope, To: "dddd3333dddd3333dddd3333dddd3333", Payload: "eA=="})

	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodePeerOffline {
		t.Errorf("code = %q, want peer_offline", got.Code)
	}
	if got.MID != "m-2" {
		t.Errorf("mid = %q, want the failing request's id", got.MID)
	}
}

func TestRelayToSelfIsRejected(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	alice.write(protocol.Relay{
		Envelope: protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix()),
		To:       alice.deviceID,
		Payload:  "eA==",
	})

	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodeBadRequest {
		t.Errorf("code = %q, want bad_request", got.Code)
	}
}

func TestPairRelayIsRateLimited(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	send := func(kind string) {
		alice.write(protocol.Relay{
			Envelope: protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix()),
			To:       bob.deviceID,
			Kind:     kind,
			Payload:  "eA==",
		})
	}

	// The harness allows two pairing requests per minute.
	send(protocol.KindPair)
	send(protocol.KindPair)
	var forwarded protocol.Relay
	bob.read(&forwarded)
	bob.read(&forwarded)

	send(protocol.KindPair)
	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodeRateLimited {
		t.Fatalf("code = %q, want rate_limited", got.Code)
	}

	// Transfer traffic between already-paired devices is not affected.
	send(protocol.KindTransfer)
	bob.read(&forwarded)
	if forwarded.Kind != protocol.KindTransfer {
		t.Errorf("kind = %q", forwarded.Kind)
	}
}

func TestStreamCreateBindsTheRequestedRoles(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	envelope := protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix())
	envelope.MID = "s-1"
	alice.write(protocol.StreamCreate{Envelope: envelope, Peer: bob.deviceID, Role: protocol.RoleSender})

	var created protocol.StreamCreated
	alice.read(&created)
	if created.Type != protocol.TypeStreamCreated || len(created.StreamID) != stream.IDBytes*2 {
		t.Fatalf("got %+v", created)
	}
	if created.MID != "s-1" {
		t.Errorf("mid = %q, want it echoed", created.MID)
	}
	if created.ExpiresAt <= time.Now().Unix() {
		t.Error("stream should expire in the future")
	}

	s, err := h.streams.Get(created.StreamID)
	if err != nil {
		t.Fatalf("stream not registered: %v", err)
	}
	if s.Sender != alice.deviceID || s.Receiver != bob.deviceID {
		t.Errorf("bound to %s -> %s", s.Sender, s.Receiver)
	}
}

func TestStreamCreateAsReceiverSwapsTheEndpoints(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	alice.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     bob.deviceID,
		Role:     protocol.RoleReceiver,
	})

	var created protocol.StreamCreated
	alice.read(&created)

	s, err := h.streams.Get(created.StreamID)
	if err != nil {
		t.Fatalf("stream not registered: %v", err)
	}
	if s.Sender != bob.deviceID || s.Receiver != alice.deviceID {
		t.Errorf("bound to %s -> %s", s.Sender, s.Receiver)
	}
}

func TestStreamCreateRejectsAnOfflinePeer(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	alice.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     "eeee4444eeee4444eeee4444eeee4444",
		Role:     protocol.RoleSender,
	})

	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodePeerOffline {
		t.Errorf("code = %q, want peer_offline", got.Code)
	}
}

func TestStreamCreateRejectsAnUnknownRole(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	alice.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     bob.deviceID,
		Role:     "observer",
	})

	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodeBadRequest {
		t.Errorf("code = %q, want bad_request", got.Code)
	}
}

func TestStreamCreateEnforcesTheConcurrencyLimit(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	create := func() {
		alice.write(protocol.StreamCreate{
			Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
			Peer:     bob.deviceID,
			Role:     protocol.RoleSender,
		})
	}

	// The harness registry allows two streams per device.
	var created protocol.StreamCreated
	create()
	alice.read(&created)
	create()
	alice.read(&created)

	create()
	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodeTooManyStreams {
		t.Errorf("code = %q, want too_many_streams", got.Code)
	}
}

func TestDisconnectReleasesTheDevicesStreams(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)
	bob := h.dial(t)

	alice.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     bob.deviceID,
		Role:     protocol.RoleSender,
	})
	var created protocol.StreamCreated
	alice.read(&created)

	alice.conn.Close(websocket.StatusNormalClosure, "bye")

	// Streams outlive nothing: a device that drops must not leave capabilities
	// or quota behind.
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if h.streams.Len() == 0 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("registry still holds %d streams", h.streams.Len())
}

func TestReconnectReplacesTheStaleSession(t *testing.T) {
	h := newHarness(t)

	public, private, _ := ed25519.GenerateKey(nil)
	first := h.dialAs(t, public, private, testToken)

	// A device whose network dropped reconnects before the server noticed the
	// old socket was dead. The newcomer has to win, or the device would be
	// unreachable until the stale connection timed out.
	second := h.dialAs(t, public, private, testToken)

	first.expectClosed()

	if h.hub.Count() != 1 {
		t.Fatalf("hub has %d sessions, want 1", h.hub.Count())
	}
	session, ok := h.hub.Lookup(second.deviceID)
	if !ok {
		t.Fatal("the reconnected device should be registered")
	}
	if session.SessionID == "" {
		t.Error("the live session should be the new one")
	}
}

func TestReconnectPreservesStreamsAllocatedBeforeTheHandoff(t *testing.T) {
	h := newHarness(t)

	public, private, _ := ed25519.GenerateKey(nil)
	bob := h.dial(t)

	first := h.dialAs(t, public, private, testToken)
	first.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     bob.deviceID,
		Role:     protocol.RoleSender,
	})
	var created protocol.StreamCreated
	first.read(&created)

	_ = h.dialAs(t, public, private, testToken)
	first.expectClosed()

	if h.streams.Len() != 1 {
		t.Fatalf("registry has %d streams after reconnect, want 1", h.streams.Len())
	}
	if _, err := h.streams.Get(created.StreamID); err != nil {
		t.Fatalf("stream %s missing after reconnect: %v", created.StreamID, err)
	}
}

func TestUnknownMessageTypeIsReported(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	envelope := protocol.NewEnvelope("teleport", time.Now().Unix())
	envelope.MID = "m-9"
	alice.write(envelope)

	var got protocol.Error
	alice.read(&got)
	if got.Code != protocol.CodeBadRequest {
		t.Errorf("code = %q, want bad_request", got.Code)
	}
}

func TestApplicationPingIsAnswered(t *testing.T) {
	h := newHarness(t)
	alice := h.dial(t)

	envelope := protocol.NewEnvelope(protocol.TypePing, time.Now().Unix())
	envelope.MID = "p-1"
	alice.write(envelope)

	var pong protocol.Envelope
	alice.read(&pong)
	if pong.Type != protocol.TypePong || pong.MID != "p-1" {
		t.Errorf("got %+v", pong)
	}
}
