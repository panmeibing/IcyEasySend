import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/format_util.dart';

/// Transfer progress indicator widget
class TransferProgressCard extends StatelessWidget {
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final double transferSpeed;
  final Duration? estimatedTimeRemaining;
  final String status;
  final int completedFilesCount;
  final int totalFilesCount;

  const TransferProgressCard({
    super.key,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.transferSpeed,
    this.estimatedTimeRemaining,
    required this.status,
    required this.completedFilesCount,
    required this.totalFilesCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.transferring,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (totalFilesCount > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedFilesCount/$totalFilesCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2196F3),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1976D2),
            ),
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (totalBytes > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${l10n.transferred}: ${FormatUtil.formatBytes(bytesTransferred)} / ${FormatUtil.formatBytes(totalBytes)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          if (transferSpeed > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.transferSpeed}: ${FormatUtil.formatSpeed(transferSpeed)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          if (estimatedTimeRemaining != null) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.remainingTime}: ${FormatUtil.formatDuration(estimatedTimeRemaining!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}
