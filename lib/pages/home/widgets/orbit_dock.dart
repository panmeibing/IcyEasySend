import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../transport/transport_channel.dart';
import '../../../utils/format_util.dart';
import '../home_ui.dart';

/// Bottom dock: target summary, progress, send / QR.
///
/// Selected files are reviewed via the orbit core sheet, not listed here.
class OrbitDock extends StatelessWidget {
  final bool isServerRunning;
  final bool isSending;
  final bool isCreatingWebShare;
  final bool canSend;
  final bool canShareViaQr;
  final PeerRef? selectedPeer;
  final String? manualTargetLabel;
  final double progress;
  final String progressStatus;
  final double transferSpeed;
  final Duration? estimatedTimeRemaining;
  final List<TransferFileItem> sendingFiles;
  final Set<int> completedFileIndices;
  final bool Function(String name)? isFileSettled;
  final void Function(String name)? onCancelFile;
  final VoidCallback? onCancelAll;
  final VoidCallback onMore;
  final VoidCallback onSend;
  final VoidCallback onShareViaQr;
  final VoidCallback onAddFiles;
  final VoidCallback? onClearPeer;

  const OrbitDock({
    super.key,
    required this.isServerRunning,
    required this.isSending,
    required this.isCreatingWebShare,
    required this.canSend,
    required this.canShareViaQr,
    required this.selectedPeer,
    required this.manualTargetLabel,
    required this.progress,
    required this.progressStatus,
    required this.transferSpeed,
    required this.estimatedTimeRemaining,
    this.sendingFiles = const [],
    this.completedFileIndices = const {},
    this.isFileSettled,
    this.onCancelFile,
    this.onCancelAll,
    required this.onMore,
    required this.onSend,
    required this.onShareViaQr,
    required this.onAddFiles,
    this.onClearPeer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final targetText = _targetLabel(l10n);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomeUi.borderSoft),
        boxShadow: [
          BoxShadow(
            color: HomeUi.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: HomeUi.inkMuted,
                      ),
                      children: [
                        if (selectedPeer != null ||
                            manualTargetLabel != null) ...[
                          TextSpan(text: '${l10n.sendFile} · '),
                          TextSpan(
                            text: targetText,
                            style: const TextStyle(
                              color: HomeUi.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else
                          TextSpan(text: l10n.targetDeviceInfo),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedPeer != null && onClearPeer != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.clearSelection,
                    onPressed: isSending ? null : onClearPeer,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: HomeUi.inkMuted,
                  ),
                TextButton(
                  onPressed: isServerRunning ? onMore : null,
                  style: TextButton.styleFrom(
                    foregroundColor: HomeUi.inkMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.moreActions),
                ),
              ],
            ),
          ),
          if (isSending) ...[
            const SizedBox(height: 12),
            _DockProgress(
              progress: progress,
              status: progressStatus,
              transferSpeed: transferSpeed,
              estimatedTimeRemaining: estimatedTimeRemaining,
              sendingFiles: sendingFiles,
              completedFileIndices: completedFileIndices,
              isFileSettled: isFileSettled,
              onCancelFile: onCancelFile,
              onCancelAll: onCancelAll,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _DockIconButton(
                tooltip: l10n.shareViaQr,
                onPressed: canShareViaQr ? onShareViaQr : null,
                child: isCreatingWebShare
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'QR',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: HomeUi.primaryDeep,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: canSend ? onSend : null,
                    style: HomeUi.softFilledButton(enabled: canSend).copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    child: Text(isSending ? l10n.sending : l10n.sendFile),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _DockIconButton(
                tooltip: l10n.selectFiles,
                onPressed: isServerRunning && !isSending ? onAddFiles : null,
                child: const Icon(Icons.add_rounded, color: HomeUi.primaryDeep),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _targetLabel(AppLocalizations l10n) {
    final peer = selectedPeer;
    if (peer != null) {
      final channel = peer.channelLabel;
      final name = peer.deviceName?.trim();
      final base = (name != null && name.isNotEmpty)
          ? name
          : (peer.hasLan
                ? peer.lan!.ip
                : (peer.deviceId ?? l10n.targetDeviceInfo));
      return channel == null ? base : '$base · $channel';
    }
    return manualTargetLabel ?? l10n.targetDeviceInfo;
  }
}

class _DockIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  const _DockIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: HomeUi.primarySoft,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DockProgress extends StatelessWidget {
  final double progress;
  final String status;
  final double transferSpeed;
  final Duration? estimatedTimeRemaining;
  final List<TransferFileItem> sendingFiles;
  final Set<int> completedFileIndices;
  final bool Function(String name)? isFileSettled;
  final void Function(String name)? onCancelFile;
  final VoidCallback? onCancelAll;

  const _DockProgress({
    required this.progress,
    required this.status,
    required this.transferSpeed,
    required this.estimatedTimeRemaining,
    required this.sendingFiles,
    required this.completedFileIndices,
    required this.isFileSettled,
    required this.onCancelFile,
    required this.onCancelAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HomeUi.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeUi.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.isNotEmpty ? status : l10n.transferring,
                  style: const TextStyle(
                    color: HomeUi.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: HomeUi.primaryDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white,
              color: HomeUi.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  FormatUtil.formatTransferSpeedLabel(
                    l10n.transferSpeed,
                    transferSpeed,
                  ),
                  style: const TextStyle(
                    color: HomeUi.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                FormatUtil.formatRemainingTimeLabel(
                  l10n.remainingTime,
                  estimatedTimeRemaining,
                ),
                style: const TextStyle(
                  color: HomeUi.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (sendingFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sendingFiles.length,
                itemBuilder: (context, index) {
                  final item = sendingFiles[index];
                  final name = item.transferName;
                  final done =
                      completedFileIndices.contains(index) ||
                      (isFileSettled?.call(name) ?? false);
                  return SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HomeUi.ink,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (!done && onCancelFile != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.cancel,
                            onPressed: () => onCancelFile!(name),
                            icon: const Icon(Icons.close, size: 16),
                            color: HomeUi.inkMuted,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (onCancelAll != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancelAll,
                child: Text(l10n.cancelAll),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
