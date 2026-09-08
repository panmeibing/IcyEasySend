/// Application-wide constants
class AppConstants {
  // Information about this project
  static const String projectName = "Icy Easy Send";
  static const String projectNameTight = "IcyEasySend";
  static const String version = "v2.0.0";
  static const String author = "冰冷的希望";

  /// Public project page (releases / source).
  static const String githubUrl = "https://github.com/panmeibing/IcyEasySend";

  /// Wire protocol version advertised over `/health` and UDP multicast.
  ///
  /// Peers that do not advertise it are treated as pre-identity clients and
  /// fall back to the legacy shared-secret path.
  static const String protocolVersion = "icy-relay-v1";

  // Network constants

  /// Default port for file transfer server
  ///
  /// This is the default port used by the HTTP server to listen for incoming
  /// file transfer requests. The server will try this port first, and if it's
  /// occupied, it will try subsequent ports up to [maxServerPort].
  static const int defaultPort = 9527;

  /// Maximum port number to try when starting the server
  ///
  /// If [defaultPort] is occupied, the server will try ports in the range
  /// [defaultPort] to [maxServerPort] until it finds an available one.
  static const int maxServerPort = 9537;

  // Timeout constants

  /// Timeout for network requests, seconds
  static const int requestTimeout = 30;

  /// Timeout for network requests (health check), seconds
  static const int checkHealthTimeout = 5;

  // Device scan constants

  /// Lower concurrency for retry / alternate-port passes to reduce router load
  static const int deviceScanRetryConcurrency = 8;

  /// Per-probe timeout during LAN scan (aligned with health check)
  static const int deviceScanProbeTimeoutSeconds = checkHealthTimeout;

  /// Max attempts per IP:port during a scan phase
  static const int deviceScanMaxAttempts = 2;

  /// Max attempts when retrying default port on previously missed IPs
  static const int deviceScanDefaultPortRetryAttempts = 3;

  /// Delay between retry attempts
  static const Duration deviceScanRetryDelay = Duration(milliseconds: 400);

  /// UDP multicast group for LAN discovery (224.0.0.0/24, LocalSend default).
  /// Discovery UDP uses the same port as the HTTP server ([defaultPort]).
  static const String multicastGroup = '224.0.0.167';

  /// Background multicast announcement interval while the server runs.
  static const Duration multicastBackgroundInterval = Duration(seconds: 20);

  /// How long to listen for multicast responses during a scan.
  static const Duration deviceScanMulticastWait = Duration(milliseconds: 2600);

  /// Extra wait after burst announcements for TCP/UDP responses to arrive.
  static const Duration deviceScanMulticastTailWait =
      Duration(milliseconds: 500);

  /// Delays between repeated multicast announcements (like LocalSend)
  static const List<int> multicastAnnouncementDelaysMs = [100, 500, 2000];

  /// Fast HTTP probe timeout for fallback discovery (milliseconds)
  static const int deviceScanDiscoveryTimeoutMs = 1000;

  /// How long the LAN probe gets to win a race against the relay.
  ///
  /// A known-IP `/health` check is usually tens of milliseconds; 600 ms covers
  /// slow home networks without making a pure-relay send feel stuck.
  static const Duration relayLanWinWindow = Duration(milliseconds: 600);

  /// Upper bound on a relay presence probe during channel selection.
  static const Duration relayProbeTimeout = Duration(seconds: 5);

  /// HTTP fallback concurrency when multicast finds nothing
  static const int deviceScanFallbackConcurrency = 50;

  /// Timeout for confirmation requests (longer to allow user to respond)
  /// User has 30 seconds to confirm, so we add 5 seconds buffer
  static const Duration confirmTimeout = Duration(seconds: 35);

  /// Base timeout for file transfer
  /// Actual timeout is calculated as: baseTimeout + (fileSize / 1MB) seconds
  static const Duration fileTransferBaseTimeout = Duration(seconds: 60);

  // File size constants

  /// Maximum file size (20GB)
  static const int maxFileSize = 20 * 1024 * 1024 * 1024;

  // History constants

  /// Maximum number of history items to keep
  static const int defaultMaxHistoryItems = 100;

  /// Maximum number of history items user can set
  static const int allowMaxHistoryItems = 1000;

  /// Minimum number of history items user can set
  static const int allowMinHistoryItems = 10;

  // Concurrent transfer constants

  /// Default number of concurrent transfers
  static const int defaultConcurrentTransfers = 5;

  /// Maximum number of concurrent transfers
  static const int maxConcurrentTransfers = 10;

  /// The delimiter used to display diagnostic information
  static const String diagInfoSeparator = '==========';

  // UI and Dialog constants

  /// Timeout duration for receive confirmation dialog
  /// User has this amount of time to accept or reject incoming files
  static const Duration receiveConfirmationTimeout = Duration(seconds: 30);

  /// Initial countdown seconds for receive confirmation
  static const int receiveConfirmationCountdown = 30;

  /// Countdown update interval (1 second)
  static const Duration countdownInterval = Duration(seconds: 1);

  /// Batch window duration for grouping multiple file requests from same sender
  /// Files arriving within this window will be grouped together
  static const Duration batchRequestWindow = Duration(milliseconds: 500);

  /// Progress update interval for file transfer UI
  static const Duration progressUpdateInterval = Duration(milliseconds: 500);

  /// Auto-close delay after all files are received
  /// Dialog will automatically close after this duration when transfer completes
  static const Duration autoCloseDelay = Duration(seconds: 1);

  /// File size constant
  static const int bytesPerKB = 1024;
  static const int bytesPerMB = 1024 * 1024;
  static const int bytesPerGB = 1024 * 1024 * 1024;

  /// Dialog width percentage (relative to screen width)
  /// All dialogs will use this percentage of screen width for consistent sizing
  static const double dialogWidthPercent = 0.8;

  // Clipboard constants

  /// Default max clipboard size
  static const int defaultMaxClipboardSize = 2;

  /// Minimum clipboard size
  static const int minClipboardSizeMB = 1;

  /// Maximum clipboard size
  static const int maxClipboardSizeMB = 10;

  /// Keep the latest temp file count from clipboard
  static const int maxClipboardKeepCount = 5;

  /// In-memory clipboard cache max age (background fallback).
  static const Duration clipboardCacheMaxAge = Duration(hours: 24);

  /// Max plaintext JSON size for an *inline* clipboard payload on the relay
  /// signaling plane. Larger content uses the data-plane stream (P2).
  ///
  /// Kept well under [relay] `MaxMessageBytes` (64 KiB) to leave room for the
  /// secure wrapper, base64 envelope and JSON framing.
  static const int relayClipboardMaxPlainBytes = 20 * 1024;

  /// Synthetic file id used with [RelaySessionKeys.fileKey] for one clipboard
  /// blob. One clipboard session carries at most one blob.
  static const String relayClipboardBlobId = 'clipboard';

  /// How long the initiator waits for the peer to answer a clipboard offer /
  /// confirm the share (includes the confirmation dialog).
  static const Duration relayClipboardReplyTimeout = Duration(seconds: 70);

  /// How long either side waits for [clipboard.done] after the stream upload
  /// finishes (on top of the transfer timeout sized for the blob).
  static const Duration relayClipboardStreamAckTimeout = Duration(seconds: 30);

  /// Default lifetime for guest web-share sessions (QR download links).
  static const Duration webShareSessionDuration = Duration(minutes: 30);

  /// Peer IP placeholder stored in transfer history for web-share sessions.
  static const String webShareHistoryPeerIp = 'web-share';

  // Pairing constants

  /// Domain separator for the pairing short authentication string.
  static const String sasContext = "icy-pair-v1";

  /// Number of decimal digits shown to the user for out-of-band comparison.
  static const int sasDigits = 6;

  /// How long the receiver's pairing dialog waits for a decision.
  static const int pairingConfirmationCountdown = 60;

  /// Client timeout for `POST /pair/request`.
  ///
  /// Must exceed [pairingConfirmationCountdown]: the peer only answers once a
  /// human has decided, and giving up first would abandon a pairing the other
  /// user is about to accept.
  static const Duration pairingRequestTimeout = Duration(seconds: 65);

  /// Client timeout for `POST /pair/confirm`, which needs no user input.
  static const Duration pairingConfirmTimeout = Duration(seconds: 10);

  /// How long the receiver keeps an unconfirmed pairing around.
  static const Duration pairingPendingTtl = Duration(minutes: 2);

  // Relay constants

  /// Domain separator for the relay admission challenge response.
  static const String relayAuthContext = "icy-relay-auth-v1";

  /// Domain separator for the proof presented when attaching to a data stream.
  static const String relayStreamContext = "icy-relay-stream-v1";

  /// WebSocket path of the relay signaling plane.
  static const String relaySignalPath = "/v1/signal";

  /// HTTP path prefix of the relay data plane.
  static const String relayStreamPath = "/v1/stream";

  /// How long to wait for the relay to answer a request-response message.
  static const Duration relayRequestTimeout = Duration(seconds: 15);

  /// How long to wait for the admission handshake to complete.
  static const Duration relayHandshakeTimeout = Duration(seconds: 20);

  /// Application-level keepalive interval on the signaling socket.
  ///
  /// Shorter than the server's own 25 s ping so an idle connection is proven
  /// dead by whichever side notices first.
  static const Duration relayPingInterval = Duration(seconds: 20);

  /// Backoff bounds for reconnecting to the relay.
  static const Duration relayReconnectMinDelay = Duration(seconds: 1);
  static const Duration relayReconnectMaxDelay = Duration(seconds: 60);

  /// How long the sender waits for the receiver to answer a transfer manifest.
  ///
  /// Must exceed [receiveConfirmationCountdown]: the peer only answers once a
  /// human has decided.
  static const Duration relayManifestTimeout = Duration(seconds: 40);

  /// How long the sender waits for `file.done` after the bytes are uploaded.
  static const Duration relayFileAckTimeout = Duration(seconds: 30);

  /// How long an accepted relay batch may stall before it is given up on.
  ///
  /// Any progress restarts the clock, so this only fires when nothing at all
  /// is moving. Without it a sender that disappears mid-batch would leave the
  /// receiver's progress dialog open indefinitely.
  static const Duration relayReceiveIdleTimeout = Duration(minutes: 2);

  /// Peer address recorded in transfer history for relayed transfers.
  static const String relayHistoryPeerIp = 'relay';

  // Relay end-to-end encryption

  /// Domain separator for the session handshake transcript.
  static const String relayHandshakeContext = "icy-relay-hs-v1";

  /// Domain separator for the additional data of encrypted signaling messages.
  static const String relaySignalingContext = "icy-relay-sig-v1";

  /// HKDF labels. Sender and receiver derive the same keys from these, so the
  /// exact strings are part of the wire protocol.
  static const String relayLabelSenderToReceiver = "icy s2r v1";
  static const String relayLabelReceiverToSender = "icy r2s v1";
  static const String relayLabelFileKey = "icy file v1";
  static const String relayLabelFileNonce = "icy file nonce v1";

  /// Plaintext bytes per encrypted frame.
  static const int relayChunkSize = 64 * 1024;

  /// Poly1305 tag length appended to every frame's ciphertext.
  static const int relayAeadTagBytes = 16;

  /// Big-endian u32 frame length prefixed to every frame.
  static const int relayFrameHeaderBytes = 4;

  /// Total per-frame overhead on the wire.
  static const int relayFrameOverhead =
      relayFrameHeaderBytes + relayAeadTagBytes;

  /// How many frames may be encrypting or decrypting at once.
  ///
  /// Bounded on purpose: without a ceiling the crypto isolate would race ahead
  /// of the network and pull the whole file into memory.
  static const int relayCryptoQueueDepth = 8;

  /// How long the sender waits for the receiver to answer a session offer.
  ///
  /// No user is involved at this stage, so this is a network timeout rather
  /// than a human one.
  static const Duration relayHandshakeReplyTimeout = Duration(seconds: 20);

  // Relay pairing (method B)

  /// How long the initiator waits for the peer's pairing answer, which only
  /// arrives once a human has compared the digits.
  static const Duration relayPairReplyTimeout = Duration(seconds: 70);

  /// How long the receiver keeps an unconfirmed relay pairing around.
  static const Duration relayPairPendingTtl = Duration(minutes: 2);

  // Relay resume and retry

  /// Directory holding half-received files, relative to the save directory.
  ///
  /// Kept beside the destination rather than in the app's own storage so
  /// finalizing a file is a rename instead of a copy; on Android the two are
  /// routinely different mounts.
  static const String relayPartialDirName = ".icy-partial";

  /// Suffixes of the two files that make up one interrupted download.
  static const String relayPartialSuffix = ".part";
  static const String relayPartialMetaSuffix = ".meta";

  /// How often the resume bookkeeping is written back to disk, in chunks.
  ///
  /// Writing it per chunk would mean a second file write for every 64 KiB.
  /// Lagging behind costs at most this much repeated transfer after a crash,
  /// because the partial file is truncated to whatever the record vouches for.
  static const int relayResumeFlushChunks = 16;

  /// How long a half-received file is kept before it is swept away.
  static const Duration relayPartialMaxAge = Duration(days: 7);

  /// How many times one file is retried before the batch moves on.
  static const int relayMaxFileRetries = 3;

  /// Backoff before each retry. Its length is the retry ceiling.
  static const List<Duration> relayRetryBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 9),
  ];

  // File name constants
  static const String defaultLoggerFileName = "IcyEasySend.log";
  static const String historyFileName = "IcyEasySendTransferHistory.json";

  /// Ed25519 identity key, stored in the application support directory.
  static const String identityFileName = "identity.key";

  /// Trusted peer list, stored in the application support directory.
  static const String pairedDevicesFileName = "paired_devices.json";

  // Logger constants
  static const int maxReadLogLines = 50;
}
