import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants.dart';

/// Transfer settings card widget
class TransferSettingsCard extends StatelessWidget {
  // Concurrent transfers
  final int concurrentTransfers;
  final int tempConcurrentTransfers;
  final int maxConcurrentTransfers;
  final Function(int) onConcurrentTransfersChanged;
  final Function(int) onConcurrentTransfersChangeEnd;

  // Max history items
  final int maxHistoryItems;
  final bool isEditingMaxHistory;
  final int allowMaxHisCount;
  final int allowMinHisCount;
  final TextEditingController maxHistoryController;
  final VoidCallback onEditMaxHistory;
  final VoidCallback onSaveMaxHistory;
  final VoidCallback onCancelMaxHistory;

  // Max clipboard size
  final int maxClipboardSizeMB;
  final bool isEditingMaxClipboardSize;
  final TextEditingController maxClipboardSizeController;
  final VoidCallback onEditMaxClipboardSize;
  final VoidCallback onSaveMaxClipboardSize;
  final VoidCallback onCancelMaxClipboardSize;

  // IP validation
  final bool enableIPValidation;
  final Function(bool) onIPValidationChanged;

  const TransferSettingsCard({
    super.key,
    required this.concurrentTransfers,
    required this.tempConcurrentTransfers,
    required this.maxConcurrentTransfers,
    required this.onConcurrentTransfersChanged,
    required this.onConcurrentTransfersChangeEnd,
    required this.maxHistoryItems,
    required this.isEditingMaxHistory,
    required this.allowMaxHisCount,
    required this.allowMinHisCount,
    required this.maxHistoryController,
    required this.onEditMaxHistory,
    required this.onSaveMaxHistory,
    required this.onCancelMaxHistory,
    required this.maxClipboardSizeMB,
    required this.isEditingMaxClipboardSize,
    required this.maxClipboardSizeController,
    required this.onEditMaxClipboardSize,
    required this.onSaveMaxClipboardSize,
    required this.onCancelMaxClipboardSize,
    required this.enableIPValidation,
    required this.onIPValidationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings_suggest,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '传输设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Concurrent transfers setting
            _buildConcurrentTransfersSection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max history items setting
            _buildMaxHistorySection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max clipboard size setting
            _buildMaxClipboardSizeSection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // IP validation toggle
            _buildIPValidationSection(),
          ],
        ),
      ),
    );
  }

  /// Build concurrent transfers section
  Widget _buildConcurrentTransfersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '并发传输数量',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '同时传输的文件数量（1-$maxConcurrentTransfers）',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$tempConcurrentTransfers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2196F3),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: const Color(0xFF2196F3),
            overlayColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: tempConcurrentTransfers.toDouble(),
            min: 1,
            max: maxConcurrentTransfers.toDouble(),
            divisions: 9,
            label: '$tempConcurrentTransfers',
            onChanged: (value) => onConcurrentTransfersChanged(value.toInt()),
            onChangeEnd: (value) =>
                onConcurrentTransfersChangeEnd(value.toInt()),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '较高的并发数可以更好地利用带宽，但可能增加设备负载',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build max history section
  Widget _buildMaxHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最大历史记录数',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '保存的最大传输记录数量（$allowMinHisCount-$allowMaxHisCount）',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (isEditingMaxHistory)
                    TextField(
                      controller: maxHistoryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '输入数量 ($allowMinHisCount-$allowMaxHisCount)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      autofocus: true,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 20,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$maxHistoryItems 条',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isEditingMaxHistory) ...[
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                onPressed: onSaveMaxHistory,
                tooltip: '保存',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                onPressed: onCancelMaxHistory,
                tooltip: '取消',
              ),
            ] else ...[
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                onPressed: onEditMaxHistory,
                tooltip: '编辑',
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '超过设置数量的旧记录将被自动删除，只保留最新的记录',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build max clipboard size section
  Widget _buildMaxClipboardSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最大剪切板大小',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '允许同步的最大剪切板大小（${AppConstants.minClipboardSizeMB}-${AppConstants.maxClipboardSizeMB} MB）',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (isEditingMaxClipboardSize)
                    TextField(
                      controller: maxClipboardSizeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText:
                            '输入大小 (${AppConstants.minClipboardSizeMB}-${AppConstants.maxClipboardSizeMB} MB)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      autofocus: true,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.content_paste,
                            size: 20,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$maxClipboardSizeMB MB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isEditingMaxClipboardSize) ...[
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                onPressed: onSaveMaxClipboardSize,
                tooltip: '保存',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                onPressed: onCancelMaxClipboardSize,
                tooltip: '取消',
              ),
            ] else ...[
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                onPressed: onEditMaxClipboardSize,
                tooltip: '编辑',
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '超过此大小的剪切板内容将无法同步，建议使用文件传输功能',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build IP validation section
  Widget _buildIPValidationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IP地址校验',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '校验目标设备IP是否在同一网段',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: enableIPValidation,
              onChanged: onIPValidationChanged,
              activeTrackColor: const Color(0xFF2196F3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enableIPValidation
                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                : const Color(0xFFFFA726).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                enableIPValidation
                    ? Icons.info_outline
                    : Icons.warning_amber_rounded,
                size: 16,
                color: enableIPValidation
                    ? const Color(0xFF1976D2)
                    : const Color(0xFFF57C00),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enableIPValidation
                      ? '启用后会检查目标IP是否在同一网段，可以避免连接错误的设备'
                      : '禁用后不会检查IP网段，适用于复杂网络环境（如热点、VPN等）',
                  style: TextStyle(
                    fontSize: 11,
                    color: enableIPValidation
                        ? Colors.grey[700]
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
