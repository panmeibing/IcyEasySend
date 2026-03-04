import 'package:flutter/material.dart';

import '../../../models/transfer_history.dart';

/// Filter type for history records
enum HistoryFilter {
  all, // 全部
  sent, // 已发送
  received, // 已接收
}

/// Filter chips widget for history page
class HistoryFilterChips extends StatelessWidget {
  final HistoryFilter currentFilter;
  final List<TransferHistory> history;
  final Function(HistoryFilter) onFilterChanged;

  const HistoryFilterChips({
    super.key,
    required this.currentFilter,
    required this.history,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(
            label: '全部',
            filter: HistoryFilter.all,
            count: history.length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '已发送',
            filter: HistoryFilter.sent,
            count: history.where((item) => !item.isReceived).length,
            icon: Icons.upload,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '已接收',
            filter: HistoryFilter.received,
            count: history.where((item) => item.isReceived).length,
            icon: Icons.download,
          ),
        ],
      ),
    );
  }

  /// Build a single filter chip
  Widget _buildFilterChip({
    required String label,
    required HistoryFilter filter,
    required int count,
    IconData? icon,
  }) {
    final isSelected = currentFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => onFilterChanged(filter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFF616161),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF212121),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
