import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/dialog_helper.dart';
import '../utils/log_util.dart';

/// Tells the user the disk is full, once, no matter how many files hit it.
///
/// A batch that runs out of space fails every remaining file for the same
/// reason, and both the LAN and relay receive paths report independently, so
/// the alert is collapsed to a single dialog rather than one per file. State
/// has to be shared across those callers to do that, hence the singleton.
class DiskFullNotifier {
  static final DiskFullNotifier _instance = DiskFullNotifier._internal();

  factory DiskFullNotifier() => _instance;

  DiskFullNotifier._internal();

  /// How long after a dialog is dismissed before another one may appear.
  /// Long enough to cover the tail of a failing batch, short enough that a
  /// genuinely separate transfer later still gets told.
  static const Duration _cooldown = Duration(seconds: 10);

  bool _visible = false;
  DateTime? _lastShown;

  /// Shows the alert unless one is already up or was just dismissed.
  ///
  /// [context] comes from the caller's own `contextGetter`, so this service
  /// never holds a `BuildContext` of its own. A null or unmounted context
  /// means the app has no UI to show it in — the failure is still reported
  /// through the transfer result either way.
  Future<void> notify(BuildContext? context) async {
    if (context == null || !context.mounted || _visible) {
      return;
    }

    final last = _lastShown;
    if (last != null && DateTime.now().difference(last) < _cooldown) {
      return;
    }

    _visible = true;
    final l10n = AppLocalizations.of(context);

    try {
      await DialogHelper.showErrorDialog(
        context,
        title: l10n.diskFullTitle,
        message: l10n.storageInsufficient,
        confirmText: l10n.gotIt,
      );
    } catch (e) {
      LogUtil.wTag(LogTags.transfer, '磁盘已满提示弹出失败: $e');
    } finally {
      _visible = false;
      // Timed from dismissal, not from display, so a dialog the user leaves
      // open does not burn the whole cooldown.
      _lastShown = DateTime.now();
    }
  }

  /// Clears the cooldown so tests (and a fresh app session) start clean.
  @visibleForTesting
  void reset() {
    _visible = false;
    _lastShown = null;
  }
}
