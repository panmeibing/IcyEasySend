package stream

import (
	"crypto/ed25519"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/icy-easy-send/relay/internal/auth"
	"github.com/icy-easy-send/relay/internal/protocol"
)

// copyBufferSize is the per-stream memory cost of relaying. Two of these (one
// per direction of the pipe handoff) is the entire footprint of a transfer,
// regardless of file size.
const copyBufferSize = 32 * 1024

// KeyLookup returns the public key an authenticated device presented on the
// signaling plane, so the data plane can verify its stream proof.
//
// A device that is not connected has no key, which also means a stream cannot
// be attached by someone who never authenticated.
type KeyLookup func(deviceID string) (ed25519.PublicKey, bool)

// Limiter wraps a reader to cap throughput for one device. Nil means unlimited.
// deviceID is the authenticated sender so a pool can share one budget across
// that device's concurrent streams.
type Limiter func(deviceID string, r io.Reader) io.Reader

// Observer receives coarse operational counters from the data plane.
// Implementations must not retain high-cardinality labels such as device ids.
type Observer interface {
	Error(code string)
	BytesRelayed(n int64)
	AuthFailure(reason string)
}

// HandlerOptions configures the data plane HTTP handler.
type HandlerOptions struct {
	Registry          *Registry
	Token             string
	Keys              KeyLookup
	RendezvousTimeout time.Duration
	IdleTimeout       time.Duration
	MaxStreamBytes    int64
	Limiter           Limiter
	Observer          Observer
	Logger            *slog.Logger
}

// Handler serves POST and GET on /v1/stream/{streamId}.
type Handler struct {
	opts HandlerOptions
}

// NewHandler builds the data plane handler.
func NewHandler(opts HandlerOptions) *Handler {
	if opts.Logger == nil {
		opts.Logger = slog.Default()
	}
	return &Handler{opts: opts}
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	streamID := strings.TrimPrefix(r.URL.Path, "/v1/stream/")
	if streamID == "" || strings.Contains(streamID, "/") {
		h.writeError(w, protocol.CodeBadRequest, "missing stream id")
		return
	}

	deviceID, err := h.authenticate(r, streamID)
	if err != nil {
		h.writeError(w, errorCode(err), err.Error())
		return
	}

	s, err := h.opts.Registry.Get(streamID)
	if err != nil {
		h.writeError(w, protocol.CodeStreamNotFound, "unknown stream")
		return
	}

	role, err := s.Role(deviceID)
	if err != nil {
		h.writeError(w, protocol.CodeStreamForbidden, "not an endpoint of this stream")
		return
	}

	switch {
	case r.Method == http.MethodPost && role == protocol.RoleSender:
		h.serveSender(w, r, s, deviceID)
	case r.Method == http.MethodGet && role == protocol.RoleReceiver:
		h.serveReceiver(w, r, s)
	default:
		// Using the wrong verb for your role is indistinguishable from trying
		// to attach to the other end, so it is refused the same way.
		h.writeError(w, protocol.CodeStreamForbidden, "method does not match role")
	}
}

// authenticate applies both admission layers to a data plane request.
func (h *Handler) authenticate(r *http.Request, streamID string) (string, error) {
	if !auth.TokenMatches(h.opts.Token, auth.ParseBearer(r.Header.Get("Authorization"))) {
		if h.opts.Observer != nil {
			h.opts.Observer.AuthFailure("token")
		}
		return "", errors.New(protocol.CodeUnauthorized)
	}

	deviceID := r.Header.Get("X-Device-Id")
	if deviceID == "" {
		if h.opts.Observer != nil {
			h.opts.Observer.AuthFailure("identity")
		}
		return "", errors.New(protocol.CodeBadIdentity)
	}

	publicKey, ok := h.opts.Keys(deviceID)
	if !ok {
		if h.opts.Observer != nil {
			h.opts.Observer.AuthFailure("identity")
		}
		return "", errors.New(protocol.CodeBadIdentity)
	}
	if err := auth.VerifyStreamProof(publicKey, streamID, r.Header.Get("X-Stream-Proof")); err != nil {
		if h.opts.Observer != nil {
			h.opts.Observer.AuthFailure("identity")
		}
		return "", errors.New(protocol.CodeBadIdentity)
	}
	return deviceID, nil
}

func (h *Handler) serveSender(w http.ResponseWriter, r *http.Request, s *Stream, deviceID string) {
	writer, err := s.AttachSender(r.Context(), h.opts.RendezvousTimeout)
	if err != nil {
		// This end attached, so Sweep will never collect the stream — it only
		// reclaims ones nobody touched. Release it here or the quota slot is
		// held until the device disconnects.
		h.opts.Registry.Release(s)
		h.writeError(w, errorCode(err), err.Error())
		return
	}

	var src io.Reader = r.Body
	if h.opts.Limiter != nil {
		src = h.opts.Limiter(deviceID, src)
	}

	controller := http.NewResponseController(w)
	extend := func() error { return controller.SetReadDeadline(time.Now().Add(h.opts.IdleTimeout)) }

	written, err := pump(writer, src, extend, nil, h.opts.MaxStreamBytes)
	// A nil error closes the write half cleanly, which is what the receiver
	// reads as the end of the file.
	writer.CloseWithError(err)

	if err != nil {
		h.opts.Registry.Release(s)
		h.opts.Logger.Debug("stream upload ended early", "bytes", written, "err", err)
		h.writeError(w, errorCode(err), err.Error())
		return
	}

	if h.opts.Observer != nil {
		h.opts.Observer.BytesRelayed(written)
	}

	// Deliberately not released on success. Release closes the read half too,
	// and the receiver is still there: the pipe is unbuffered, so the last
	// bytes have been handed over but the read that turns into EOF has not
	// necessarily happened yet. Closing now would race it and turn a complete
	// transfer into an aborted one. Teardown belongs to the receiver, which is
	// the end that knows when the file has actually arrived.
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "bytes": written})
}

func (h *Handler) serveReceiver(w http.ResponseWriter, r *http.Request, s *Stream) {
	reader, err := s.AttachReceiver(r.Context(), h.opts.RendezvousTimeout)
	if err != nil {
		h.opts.Registry.Release(s)
		h.writeError(w, errorCode(err), err.Error())
		return
	}
	// Runs however this ends, which is what makes the receiver the single
	// owner of teardown for a stream that got as far as moving bytes.
	defer h.opts.Registry.Release(s)

	// No Content-Length: the size is not known here and must not be, since
	// that would require buffering the whole file.
	w.Header().Set("Content-Type", "application/octet-stream")
	w.WriteHeader(http.StatusOK)

	controller := http.NewResponseController(w)
	controller.Flush()

	extend := func() error { return controller.SetWriteDeadline(time.Now().Add(h.opts.IdleTimeout)) }
	flush := func() { controller.Flush() }

	written, err := pump(w, reader, extend, flush, h.opts.MaxStreamBytes)
	reader.CloseWithError(err)

	if err != nil {
		// The status line is already out, so the only honest signal left is to
		// drop the connection: a truncated body must not look like a complete
		// one to the receiving client.
		h.opts.Logger.Debug("stream download ended early", "bytes", written, "err", err)
		panic(http.ErrAbortHandler)
	}
}

// pump moves bytes one buffer at a time, renewing the idle deadline after each
// successful chunk.
//
// The deadline has to be per-chunk rather than for the whole request: a 20 GB
// transfer legitimately takes hours, and only a stall means something is
// actually wrong.
func pump(dst io.Writer, src io.Reader, extend func() error, flush func(), maxBytes int64) (int64, error) {
	buf := make([]byte, copyBufferSize)
	var total int64

	for {
		if err := extend(); err != nil {
			// A server that cannot set deadlines would let a stalled stream
			// live forever, so give up rather than run unbounded.
			return total, err
		}

		n, readErr := src.Read(buf)
		if n > 0 {
			if maxBytes > 0 && total+int64(n) > maxBytes {
				return total, errStreamTooLarge
			}
			if _, writeErr := dst.Write(buf[:n]); writeErr != nil {
				return total, writeErr
			}
			total += int64(n)
			if flush != nil {
				flush()
			}
		}
		if readErr != nil {
			if errors.Is(readErr, io.EOF) {
				return total, nil
			}
			return total, readErr
		}
	}
}

var errStreamTooLarge = errors.New(protocol.CodePayloadTooLarge)

func errorCode(err error) string {
	switch {
	case err == nil:
		return protocol.CodeInternal
	case errors.Is(err, ErrPeerNotAttached):
		return protocol.CodePeerNotAttached
	case errors.Is(err, ErrForbidden), errors.Is(err, ErrAlreadyAttached):
		return protocol.CodeStreamForbidden
	case errors.Is(err, ErrNotFound):
		return protocol.CodeStreamNotFound
	case errors.Is(err, ErrTooManyStreams):
		return protocol.CodeTooManyStreams
	case errors.Is(err, errStreamTooLarge):
		return protocol.CodePayloadTooLarge
	case isTimeout(err):
		return protocol.CodeIdleTimeout
	}

	switch err.Error() {
	case protocol.CodeUnauthorized, protocol.CodeBadIdentity, protocol.CodeBadRequest:
		return err.Error()
	}
	return protocol.CodeInternal
}

func isTimeout(err error) bool {
	var timeout interface{ Timeout() bool }
	return errors.As(err, &timeout) && timeout.Timeout()
}

func (h *Handler) writeError(w http.ResponseWriter, code, message string) {
	if h.opts.Observer != nil {
		h.opts.Observer.Error(code)
	}
	writeJSON(w, protocol.HTTPStatus(code), map[string]any{
		"ok":      false,
		"code":    code,
		"message": message,
	})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
