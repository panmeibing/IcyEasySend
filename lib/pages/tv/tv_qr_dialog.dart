import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/web_share_session.dart';
import '../home/home_ui.dart';
import 'tv_widgets.dart';

/// Large QR for a guest browser. Back and Close leave the share running.
class TvQrDialog extends StatefulWidget {
  final WebShareSession session;
  final String shareUrl;
  final String Function()? shareUrlBuilder;
  final FutureOr<void> Function() onStopSharing;

  const TvQrDialog({
    super.key,
    required this.session,
    required this.shareUrl,
    required this.onStopSharing,
    this.shareUrlBuilder,
  });

  @override
  State<TvQrDialog> createState() => _TvQrDialogState();
}

class _TvQrDialogState extends State<TvQrDialog> {
  late String _shareUrl = widget.shareUrl;
  Timer? _ticker;
  late Duration _remaining = widget.session.expiresAt.difference(DateTime.now());
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = widget.shareUrlBuilder?.call();
      setState(() {
        if (next != null && next.isNotEmpty) _shareUrl = next;
        _remaining = widget.session.expiresAt.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await widget.onStopSharing();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalSeconds = _remaining.inSeconds.clamp(0, 86400);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final clock =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: true,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: _shareUrl,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.webShareTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: HomeUi.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _shareUrl,
                        style: const TextStyle(fontSize: 18, color: HomeUi.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.webShareExpiresIn(clock),
                        style: const TextStyle(
                          fontSize: 16,
                          color: HomeUi.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          TvButton(
                            label: l10n.close,
                            primary: true,
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TvButton(
                            label: l10n.webShareStopSharing,
                            onPressed: _stopping ? null : _stop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
