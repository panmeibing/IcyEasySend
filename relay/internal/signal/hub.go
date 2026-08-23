// Package signal implements the WebSocket control plane: admission, presence
// and opaque message routing between two devices.
package signal

import (
	"crypto/ed25519"
	"sync"
)

// Hub tracks authenticated sessions and who wants to hear about whom.
//
// Presence is only ever revealed between devices that subscribe to each other.
// Without that rule, anyone holding the server token could enumerate which
// devices are online, which is exactly the metadata this design is trying not
// to accumulate.
type Hub struct {
	mu       sync.RWMutex
	sessions map[string]*Session
	subs     map[string]map[string]struct{}
}

// NewHub creates an empty hub.
func NewHub() *Hub {
	return &Hub{
		sessions: make(map[string]*Session),
		subs:     make(map[string]map[string]struct{}),
	}
}

// Register adds a session, returning any previous session for the same device.
//
// A device reconnecting before the server noticed the old socket died is
// normal, so the newcomer wins and the caller closes the stale one.
func (h *Hub) Register(s *Session) *Session {
	h.mu.Lock()
	defer h.mu.Unlock()

	previous := h.sessions[s.DeviceID]
	h.sessions[s.DeviceID] = s
	return previous
}

// Unregister removes a session and reports which peers should be told it went
// offline. removed is false when the session was already replaced by a newer
// one, in which case watchers is nil.
func (h *Hub) Unregister(s *Session) (watchers []*Session, removed bool) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if current, ok := h.sessions[s.DeviceID]; !ok || current != s {
		return nil, false
	}
	delete(h.sessions, s.DeviceID)

	watchers = h.mutualWatchersLocked(s.DeviceID)
	delete(h.subs, s.DeviceID)
	return watchers, true
}

// Lookup returns the live session for a device.
func (h *Hub) Lookup(deviceID string) (*Session, bool) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	s, ok := h.sessions[deviceID]
	return s, ok
}

// PublicKey returns the key a connected device authenticated with.
func (h *Hub) PublicKey(deviceID string) (ed25519.PublicKey, bool) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	s, ok := h.sessions[deviceID]
	if !ok {
		return nil, false
	}
	return s.PublicKey, true
}

// PresenceUpdate is one presence notification to deliver.
type PresenceUpdate struct {
	To       *Session
	DeviceID string
	Online   bool
}

// Subscribe replaces deviceID's subscription set and returns the notifications
// the change implies.
//
// Two things happen at once: the subscriber learns the state of every peer it
// now watches mutually, and those peers learn the subscriber is online. Both
// directions are gated on the subscription being mutual.
func (h *Hub) Subscribe(deviceID string, peers []string) []PresenceUpdate {
	h.mu.Lock()
	defer h.mu.Unlock()

	self, ok := h.sessions[deviceID]
	if !ok {
		return nil
	}

	// Peers that were mutual before and are not in the new set must be told
	// this device is gone, otherwise they keep showing it as online forever.
	previouslyMutual := h.mutualWatchersLocked(deviceID)

	set := make(map[string]struct{}, len(peers))
	for _, peer := range peers {
		if peer != "" && peer != deviceID {
			set[peer] = struct{}{}
		}
	}
	h.subs[deviceID] = set

	stillMutual := make(map[string]struct{}, len(set))
	var updates []PresenceUpdate

	for peer := range set {
		if !h.subscribedToLocked(peer, deviceID) {
			continue
		}
		stillMutual[peer] = struct{}{}

		peerSession, online := h.sessions[peer]
		updates = append(updates, PresenceUpdate{To: self, DeviceID: peer, Online: online})
		if online {
			updates = append(updates, PresenceUpdate{To: peerSession, DeviceID: deviceID, Online: true})
		}
	}

	for _, watcher := range previouslyMutual {
		if _, ok := stillMutual[watcher.DeviceID]; ok {
			continue
		}
		updates = append(updates, PresenceUpdate{To: watcher, DeviceID: deviceID, Online: false})
	}

	return updates
}

// mutualWatchersLocked returns connected sessions that subscribe to deviceID
// and are subscribed to by it.
func (h *Hub) mutualWatchersLocked(deviceID string) []*Session {
	var watchers []*Session
	for peer := range h.subs[deviceID] {
		if !h.subscribedToLocked(peer, deviceID) {
			continue
		}
		if session, ok := h.sessions[peer]; ok {
			watchers = append(watchers, session)
		}
	}
	return watchers
}

func (h *Hub) subscribedToLocked(subscriber, target string) bool {
	_, ok := h.subs[subscriber][target]
	return ok
}

// Count reports the number of connected devices.
func (h *Hub) Count() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.sessions)
}
