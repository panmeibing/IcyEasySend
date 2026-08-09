import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/web_share_session.dart';
import '../../../utils/format_util.dart';
import '../../../utils/toast_helper.dart';

/// Dialog showing a QR code and link for guest browser downloads.
class WebShareQrDialog extends StatefulWidget {
  final WebShareSession session;
  final String shareUrl;
  final FutureOr<void> Function() onStopSharing;
  final String Function()? shareUrlBuilder;

  const WebShareQrDialog({
    super.key,
    required this.session,
    required this.shareUrl,
    required this.onStopSharing,
    this.shareUrlBuilder,
  });

  /// Show the dialog. Returns `true` if sharing was stopped by the user.
  static Future<bool?> show(
    BuildContext context, {
    required WebShareSession session,
    required String shareUrl,
    required FutureOr<void> Function() onStopSharing,
    String Function()? shareUrlBuilder,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return WebShareQrDialog(
          session: session,
          shareUrl: shareUrl,
          onStopSharing: onStopSharing,
          shareUrlBuilder: shareUrlBuilder,
        );
      },
    );
  }

  @override
  State<WebShareQrDialog> createState() => _WebShareQrDialogState();
}

class _WebShareQrDialogState extends State<WebShareQrDialog> {
  late String _shareUrl;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _shareUrl = widget.shareUrl;
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final nextUrl = widget.shareUrlBuilder?.call();
      setState(() {
        if (nextUrl != null && nextUrl.isNotEmpty && nextUrl != _shareUrl) {
          _shareUrl = nextUrl;
        }
        _updateRemaining();
      });
      if (_remaining <= Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  void _updateRemaining() {
    final diff = widget.session.expiresAt.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (!mounted) return;
    ToastHelper.showSuccess(
      context,
      AppLocalizations.of(context).webShareLinkCopied,
    );
  }

  Future<void> _stopSharing() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await widget.onStopSharing();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _stopping = false);
      }
    }
  }

  String _formatRemaining(AppLocalizations l10n) {
    final totalSeconds = _remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return l10n.webShareExpiresIn(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth * 0.55).clamp(180.0, 260.0);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_2, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.webShareTitle)),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.webShareHint,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: _shareUrl,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.webShareFilesSummary(
                  widget.session.files.length,
                  FormatUtil.formatBytes(widget.session.totalSize),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _formatRemaining(l10n),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _shareUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: _stopping
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(l10n.close),
            ),
            TextButton.icon(
              onPressed: _stopping ? null : _copyLink,
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l10n.webShareCopyLink),
            ),
            ElevatedButton(
              onPressed: _stopping ? null : _stopSharing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: _stopping
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.webShareStopSharing),
            ),
          ],
        ),
      ],
    );
  }
}
