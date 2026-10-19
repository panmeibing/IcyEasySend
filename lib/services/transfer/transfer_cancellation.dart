import 'dart:async';

import 'package:flutter/foundation.dart';

/// User cancellation for one batch of files, shared by the UI and the sender.
///
/// Cancelling a file that is already on the wire runs its hook, which closes
/// that socket. Cancelling a file that has not started yet is remembered, so
/// the sender skips it instead of opening a new connection. A file that has
/// already finished, either way, can no longer be cancelled: the receiver
/// would otherwise be told to drop a file it has already saved.
class TransferCancellation extends ChangeNotifier {
  final Set<String> _cancelled = {};
  final Set<String> _finished = {};
  final Map<String, void Function()> _hooks = {};
  final Completer<void> _aborted = Completer<void>();

  /// Names cancelled so far. The sender turns these into peer notifications.
  void Function(Set<String> names)? onChanged;

  /// The whole batch was called off with [cancelAll]. Phases that wait on
  /// the receiver before any file exists, such as its confirmation, stop
  /// waiting on this.
  bool get isAborted => _aborted.isCompleted;

  /// Resolves with [work]'s result, or with null once the batch is aborted.
  Future<T?> unlessAborted<T>(Future<T> work) {
    if (isAborted) return Future.value(null);
    return Future.any<T?>([work, _aborted.future.then((_) => null)]);
  }

  bool isCancelled(String name) => _cancelled.contains(name);

  /// The file no longer needs a cancel control: it was cancelled or it ended.
  bool isSettled(String name) =>
      _cancelled.contains(name) || _finished.contains(name);

  Set<String> get cancelled => Set.unmodifiable(_cancelled);

  /// Runs [cancel] now if [name] was already cancelled, otherwise when it is.
  void attach(String name, void Function() cancel) {
    if (isCancelled(name)) {
      cancel();
      return;
    }
    _hooks[name] = cancel;
  }

  /// Records that [name] has ended, successfully or not, and drops its hook.
  void markFinished(String name) {
    _hooks.remove(name);
    if (_finished.add(name)) notifyListeners();
  }

  void cancelFile(String name) {
    if (_finished.contains(name) || !_cancelled.add(name)) return;
    _hooks.remove(name)?.call();
    onChanged?.call({name});
    notifyListeners();
  }

  void cancelAll(Iterable<String> names) {
    if (!_aborted.isCompleted) _aborted.complete();
    final fresh = <String>{};
    for (final name in names) {
      if (_finished.contains(name)) continue;
      if (_cancelled.add(name)) fresh.add(name);
    }
    final hooks = [for (final name in fresh) ?_hooks.remove(name)];
    for (final hook in hooks) {
      hook();
    }
    if (fresh.isEmpty) return;
    onChanged?.call(fresh);
    notifyListeners();
  }
}
