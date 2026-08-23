import 'package:flutter/foundation.dart';

import '../models/transfer_data.dart';
import '../models/transfer_file_item.dart';
import '../utils/constants.dart';
import '../utils/operation_result.dart';

/// The physical path a [TransportChannel] uses to reach a peer.
enum TransportKind {
  /// Direct HTTP connection on the local network.
  lan,

  /// Forwarded through a self-hosted relay server on the public internet.
  relay,
}

/// A peer's address on the local network.
///
/// [address] is kept verbatim because it is handed to
/// `NetworkUtil.buildHttpUrl`, which accepts both `ip` and `ip:port`, and is
/// also recorded in the transfer history. Reformatting it would silently
/// change stored history entries.
class LanEndpoint {
  final String address;
  final String ip;
  final int port;

  const LanEndpoint._({
    required this.address,
    required this.ip,
    required this.port,
  });

  factory LanEndpoint({required String ip, required int port}) {
    return LanEndpoint._(address: '$ip:$port', ip: ip, port: port);
  }

  /// Parses `ip` or `ip:port`, defaulting to [AppConstants.defaultPort].
  ///
  /// The original string is preserved in [address].
  factory LanEndpoint.parse(String address) {
    final separator = address.lastIndexOf(':');
    if (separator <= 0) {
      return LanEndpoint._(
        address: address,
        ip: address,
        port: AppConstants.defaultPort,
      );
    }

    final port = int.tryParse(address.substring(separator + 1));
    if (port == null) {
      return LanEndpoint._(
        address: address,
        ip: address,
        port: AppConstants.defaultPort,
      );
    }

    return LanEndpoint._(
      address: address,
      ip: address.substring(0, separator),
      port: port,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LanEndpoint && other.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => address;
}

/// A peer device, independent of how it is reached.
///
/// The same physical device may be reachable over several channels at once, so
/// callers should hold one [PeerRef] per device rather than one per route.
///
/// [deviceId] is null when nothing but an address is known — currently the case
/// for manually entered IPs. It becomes the merge key once devices advertise
/// their public key over `/health` and multicast.
class PeerRef {
  final String? deviceId;
  final String? deviceName;
  final LanEndpoint? lan;
  final bool relayOnline;

  const PeerRef({
    this.deviceId,
    this.deviceName,
    this.lan,
    this.relayOnline = false,
  });

  /// A peer known only by its local network address.
  factory PeerRef.lanAddress(
    String address, {
    String? deviceId,
    String? deviceName,
  }) {
    return PeerRef(
      deviceId: deviceId,
      deviceName: deviceName,
      lan: LanEndpoint.parse(address),
    );
  }

  bool get hasLan => lan != null;

  /// Short human-readable form for logs and error messages.
  String describe() {
    final name = deviceName;
    if (name != null && name.isNotEmpty) {
      final address = lan?.address;
      return address == null ? name : '$name ($address)';
    }
    return lan?.address ?? deviceId ?? 'unknown';
  }

  PeerRef copyWith({
    String? deviceId,
    String? deviceName,
    LanEndpoint? lan,
    bool? relayOnline,
  }) {
    return PeerRef(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      lan: lan ?? this.lan,
      relayOnline: relayOnline ?? this.relayOnline,
    );
  }

  @override
  String toString() => 'PeerRef(${describe()})';
}

/// Outcome of a lightweight reachability check.
///
/// [unavailable] and [unreachable] are deliberately distinct: the former means
/// the channel has no route to even attempt, the latter means it tried and
/// failed. Channel selection treats them differently.
class ProbeResult {
  final TransportKind kind;
  final bool ok;
  final bool attempted;
  final Duration? rtt;
  final String? deviceName;
  final String? errorMessage;

  const ProbeResult._({
    required this.kind,
    required this.ok,
    required this.attempted,
    this.rtt,
    this.deviceName,
    this.errorMessage,
  });

  factory ProbeResult.reachable({
    required TransportKind kind,
    required Duration rtt,
    String? deviceName,
  }) {
    return ProbeResult._(
      kind: kind,
      ok: true,
      attempted: true,
      rtt: rtt,
      deviceName: deviceName,
    );
  }

  factory ProbeResult.unreachable({
    required TransportKind kind,
    required String errorMessage,
  }) {
    return ProbeResult._(
      kind: kind,
      ok: false,
      attempted: true,
      errorMessage: errorMessage,
    );
  }

  /// The channel cannot route to this peer at all, so nothing was sent.
  factory ProbeResult.unavailable({
    required TransportKind kind,
    String? errorMessage,
  }) {
    return ProbeResult._(
      kind: kind,
      ok: false,
      attempted: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'ProbeResult(${kind.name}, ok: $ok, attempted: $attempted, '
      'rtt: ${rtt?.inMilliseconds}ms, error: $errorMessage)';
}

/// Progress of the whole batch.
typedef TransferProgressCallback =
    void Function(double progress, int bytesTransferred, int totalBytes);

/// Progress of a single file, identified by its index in the input list.
typedef FileProgressCallback =
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    );

/// A route over which files can be sent to a peer.
///
/// Implementations own everything protocol-specific; callers work only in terms
/// of a [PeerRef] and a list of files.
abstract class TransportChannel {
  TransportKind get kind;

  /// Brings up whatever long-lived resources the channel needs.
  ///
  /// Safe to call more than once.
  Future<void> start();

  /// Releases resources acquired by [start].
  Future<void> stop();

  /// Checks whether [peer] can currently be reached over this channel.
  ///
  /// Must complete within [timeout] and must not throw; failures are reported
  /// through the returned [ProbeResult].
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout});

  /// Sends [files] to [peer], keyed by [TransferFileItem.transferName].
  ///
  /// Every input file gets an entry in the result map, successful or not.
  Future<Map<String, OperationResult<TransferData>>> sendFiles({
    required PeerRef peer,
    required List<TransferFileItem> files,
    String? secretKey,
    TransferProgressCallback? onProgress,
    FileProgressCallback? onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  });
}
