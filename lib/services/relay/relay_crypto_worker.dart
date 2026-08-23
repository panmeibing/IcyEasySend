import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../utils/constants.dart';
import '../../utils/log_util.dart';

/// Runs ChaCha20-Poly1305 off the UI thread.
///
/// The pure Dart implementation manages around 30 MB/s, which is fast enough
/// for any realistic uplink but far too slow to run on the main isolate: a
/// 100 MB file would freeze the interface for seconds at a time. One worker
/// serves a whole transfer, since spawning per chunk would cost more than the
/// encryption itself.
///
/// Falls back to encrypting in place if the isolate cannot be spawned. A
/// stuttering UI is a much smaller problem than a transfer that refuses to
/// start.
class RelayCryptoWorker {
  SendPort? _commands;
  Isolate? _isolate;
  ReceivePort? _responses;
  StreamSubscription<dynamic>? _subscription;

  final Map<int, Completer<Uint8List>> _pending = {};
  int _nextJobId = 0;
  bool _closed = false;

  RelayCryptoWorker._();

  /// A worker that does the work on the calling isolate.
  ///
  /// This is the fallback path [spawn] lands on when an isolate cannot be
  /// created, so it is worth being able to exercise it deliberately.
  factory RelayCryptoWorker.inlineForTesting() => RelayCryptoWorker._();

  /// Whether work is actually leaving the current isolate.
  bool get isOffloaded => _commands != null;

  /// Spawns a worker, or returns an inline one when that is not possible.
  static Future<RelayCryptoWorker> spawn() async {
    final worker = RelayCryptoWorker._();
    final responses = ReceivePort();

    try {
      final ready = Completer<SendPort>();
      worker._responses = responses;
      worker._subscription = responses.listen((message) {
        if (message is SendPort) {
          if (!ready.isCompleted) {
            ready.complete(message);
          }
          return;
        }
        worker._onResponse(message);
      });

      worker._isolate = await Isolate.spawn(
        _workerMain,
        responses.sendPort,
        debugName: 'relay-crypto',
      );
      worker._commands = await ready.future.timeout(
        const Duration(seconds: 5),
      );
      return worker;
    } catch (e) {
      LogUtil.wTag(LogTags.transfer, '无法启动加密隔离区，改为在主线程加解密: $e');
      await worker._subscription?.cancel();
      worker._subscription = null;
      responses.close();
      worker._responses = null;
      worker._isolate?.kill(priority: Isolate.immediate);
      worker._isolate = null;
      worker._commands = null;
      return worker;
    }
  }

  /// Encrypts one chunk, returning ciphertext with the tag appended.
  Future<Uint8List> encrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List data,
  }) {
    return _run(encrypting: true, key: key, nonce: nonce, aad: aad, data: data);
  }

  /// Decrypts one frame, throwing when the tag does not verify.
  Future<Uint8List> decrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List data,
  }) {
    return _run(
      encrypting: false,
      key: key,
      nonce: nonce,
      aad: aad,
      data: data,
    );
  }

  Future<Uint8List> _run({
    required bool encrypting,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List data,
  }) {
    final commands = _commands;
    if (commands == null || _closed) {
      return _process(
        encrypting: encrypting,
        key: key,
        nonce: nonce,
        aad: aad,
        data: data,
      );
    }

    final id = _nextJobId++;
    final completer = Completer<Uint8List>();
    _pending[id] = completer;

    commands.send([
      id,
      encrypting,
      key,
      nonce,
      aad,
      // Moves the bytes instead of copying them, which matters at 64 KiB a
      // frame and several frames in flight.
      TransferableTypedData.fromList([data]),
    ]);
    return completer.future;
  }

  void _onResponse(dynamic message) {
    if (message is! List || message.length != 3) {
      return;
    }
    final completer = _pending.remove(message[0] as int);
    if (completer == null || completer.isCompleted) {
      return;
    }

    final error = message[2];
    if (error != null) {
      completer.completeError(RelayCryptoException(error.toString()));
      return;
    }
    completer.complete(
      (message[1] as TransferableTypedData).materialize().asUint8List(),
    );
  }

  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        // Whoever queued this may already have walked away, and an error
        // nobody catches would be reported against an unrelated later test or
        // transfer.
        completer.future.ignore();
        completer.completeError(
          RelayCryptoException('加密任务在完成前被取消'),
        );
      }
    }
    _pending.clear();

    await _subscription?.cancel();
    _responses?.close();
    _isolate?.kill(priority: Isolate.immediate);
  }

  // -- the isolate ----------------------------------------------------------

  static void _workerMain(SendPort ready) {
    final commands = ReceivePort();
    ready.send(commands.sendPort);

    commands.listen((message) async {
      if (message is! List || message.length != 6) {
        return;
      }

      final id = message[0] as int;
      try {
        final result = await _process(
          encrypting: message[1] as bool,
          key: message[2] as Uint8List,
          nonce: message[3] as Uint8List,
          aad: message[4] as Uint8List,
          data: (message[5] as TransferableTypedData)
              .materialize()
              .asUint8List(),
        );
        ready.send([id, TransferableTypedData.fromList([result]), null]);
      } catch (e) {
        ready.send([id, null, e.toString()]);
      }
    });
  }

  /// The actual cryptography, identical in the worker and the fallback.
  static Future<Uint8List> _process({
    required bool encrypting,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List data,
  }) async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = SecretKey(key);

    if (encrypting) {
      final box = await algorithm.encrypt(
        data,
        secretKey: secretKey,
        nonce: nonce,
        aad: aad,
      );
      final out = Uint8List(box.cipherText.length + box.mac.bytes.length);
      out.setRange(0, box.cipherText.length, box.cipherText);
      out.setRange(box.cipherText.length, out.length, box.mac.bytes);
      return out;
    }

    if (data.length < AppConstants.relayAeadTagBytes) {
      throw RelayCryptoException('密文帧长度异常');
    }
    final split = data.length - AppConstants.relayAeadTagBytes;
    final clear = await algorithm.decrypt(
      SecretBox(
        data.sublist(0, split),
        nonce: nonce,
        mac: Mac(data.sublist(split)),
      ),
      secretKey: secretKey,
      aad: aad,
    );
    return Uint8List.fromList(clear);
  }
}

/// Raised when a frame cannot be produced or verified.
class RelayCryptoException implements Exception {
  final String message;

  RelayCryptoException(this.message);

  @override
  String toString() => message;
}
