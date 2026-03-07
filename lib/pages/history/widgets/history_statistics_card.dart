import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/transfer_history_service.dart';
import '../../../utils/format_util.dart';

/// Statistics card widget for history page
class HistoryStatisticsCard extends StatelessWidget {
  final TransferStatistics statistics;
  final bool isExpanded;
  final VoidCallback onToggle;

  const HistoryStatisticsCard({
    super.key,
    required this.statistics,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          size: 18,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.statisticsInfo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        l10n.transfersCount(statistics.totalTransfers),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.totalTransfers,
                          statistics.totalTransfers.toString(),
                          const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.successfulTransfers,
                          statistics.successfulTransfers.toString(),
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.failedTransfers,
                          statistics.failedTransfers.toString(),
                          const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.sentFiles,
                          statistics.sentFiles.toString(),
                          const Color(0xFFFF9800),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.receivedFiles,
                          statistics.receivedFiles.toString(),
                          const Color(0xFF9C27B0),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          l10n.totalSize,
                          FormatUtil.formatBytes(statistics.totalBytes),
                          const Color(0xFF009688),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
