import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/transfer_history.dart';
import '../services/transfer_history_service.dart';
import '../utils/dialog_helper.dart';
import '../utils/format_util.dart';
import '../utils/toast_helper.dart';

/// History page to display transfer history
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

/// Filter type for history records
enum HistoryFilter {
  all, // 全部
  sent, // 已发送
  received, // 已接收
}

class HistoryPageState extends State<HistoryPage> {
  late final TransferHistoryService _historyService;
  List<TransferHistory> _history = [];
  TransferStatistics? _statistics;
  bool _isLoading = true;
  bool _isStatisticsExpanded = false;
  HistoryFilter _currentFilter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();

    // Initialize services (can be overridden for testing)
    _historyService = TransferHistoryService();

    _loadHistory();
  }

  /// Public method to refresh history from external calls
  void refreshHistory() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _historyService.loadHistory();
      final statistics = await _historyService.getStatistics();

      setState(() {
        _history = history;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '清除历史记录',
      message: '确定要清除所有传输历史记录吗？此操作无法撤销。',
      confirmText: '清除',
      icon: Icons.delete_sweep,
      iconColor: Colors.red,
    );

    if (confirmed) {
      await _historyService.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty
        ? _buildEmptyState()
        : Column(
            children: [
              _buildAppBar(),
              _buildFilterChips(),
              if (_statistics != null) _buildStatistics(),
              Expanded(child: _buildHistoryList()),
            ],
          );
  }

  /// Get filtered history based on current filter
  List<TransferHistory> get _filteredHistory {
    switch (_currentFilter) {
      case HistoryFilter.all:
        return _history;
      case HistoryFilter.sent:
        return _history.where((item) => !item.isReceived).toList();
      case HistoryFilter.received:
        return _history.where((item) => item.isReceived).toList();
    }
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(
            label: '全部',
            filter: HistoryFilter.all,
            count: _history.length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '已发送',
            filter: HistoryFilter.sent,
            count: _history.where((item) => !item.isReceived).length,
            icon: Icons.upload,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '已接收',
            filter: HistoryFilter.received,
            count: _history.where((item) => item.isReceived).length,
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
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
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
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                '传输历史',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            if (_history.isNotEmpty)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearHistory,
                  tooltip: '清除历史',
                  color: const Color(0xFF757575),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无传输历史',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _statistics!;
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
            onTap: () {
              setState(() {
                _isStatisticsExpanded = !_isStatisticsExpanded;
              });
            },
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
                      const Text(
                        '统计信息',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${stats.totalTransfers} 次传输',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isStatisticsExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isStatisticsExpanded) ...[
            Container(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '总传输',
                          stats.totalTransfers.toString(),
                          const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '成功',
                          stats.successfulTransfers.toString(),
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '失败',
                          stats.failedTransfers.toString(),
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
                          '已发送',
                          stats.sentFiles.toString(),
                          const Color(0xFFFF9800),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '已接收',
                          stats.receivedFiles.toString(),
                          const Color(0xFF9C27B0),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '总大小',
                          FormatUtil.formatBytes(stats.totalBytes),
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

  Widget _buildStatItem(String label, String value, Color color) {
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

  Widget _buildHistoryList() {
    final filteredHistory = _filteredHistory;

    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '没有符合条件的记录',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final item = filteredHistory[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(TransferHistory item) {
    final icon = item.isReceived ? Icons.download : Icons.upload;
    final iconColor = item.isReceived
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2196F3);
    final statusIcon = item.success ? Icons.check_circle : Icons.error;
    final statusColor = item.success
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);

    // Display device name if available, otherwise show IP
    final peerDisplay = item.peerDeviceName ?? item.peerIP;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${item.isReceived ? '来自' : '发送至'}: $peerDisplay',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              tooltip: '更多操作',
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                // Only show "Open File" and "Open Folder" for received files with saved path
                if (item.isReceived &&
                    item.savedPath != null &&
                    item.success) ...[
                  const PopupMenuItem(
                    value: 'open_file',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, size: 18),
                        SizedBox(width: 12),
                        Text('打开文件'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'open_folder',
                    child: Row(
                      children: [
                        Icon(Icons.folder_open, size: 18),
                        SizedBox(width: 12),
                        Text('打开所在文件夹'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 12),
                      Text('查看详情'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('删除记录', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showDetailDialog(item),
      ),
    );
  }

  /// Handle menu action
  Future<void> _handleMenuAction(String action, TransferHistory item) async {
    switch (action) {
      case 'open_file':
        await _openFile(item);
        break;
      case 'open_folder':
        await _openFolder(item);
        break;
      case 'view_details':
        _showDetailDialog(item);
        break;
      case 'delete':
        await _deleteRecord(item);
        break;
    }
  }

  /// Open the file
  Future<void> _openFile(TransferHistory item) async {
    if (item.savedPath == null) {
      _showErrorSnackBar('文件路径不存在');
      return;
    }

    final file = File(item.savedPath!);
    if (!await file.exists()) {
      _showErrorSnackBar('文件不存在，可能已被删除');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use open_filex for Android and iOS
        final result = await OpenFilex.open(item.savedPath!);
        if (result.type != ResultType.done) {
          _showErrorSnackBar('无法打开文件: ${result.message}');
        }
      } else {
        // Use url_launcher for desktop platforms (macOS, Windows, Linux)
        final uri = Uri.file(item.savedPath!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorSnackBar('无法打开文件');
        }
      }
    } catch (e) {
      _showErrorSnackBar('打开文件失败: $e');
    }
  }

  /// Open the folder containing the file
  Future<void> _openFolder(TransferHistory item) async {
    if (item.savedPath == null) {
      _showErrorSnackBar('文件路径不存在');
      return;
    }

    final file = File(item.savedPath!);
    final directory = file.parent;

    if (!await directory.exists()) {
      _showErrorSnackBar('文件夹不存在');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // On Android, use open_file_manager to open the folder
        final path = directory.path;

        // Try to extract the relative path from common Android storage paths
        String? relativePath;

        // Common Android storage paths
        final storagePrefixes = [
          '/storage/emulated/0/',
          '/sdcard/',
          '/mnt/sdcard/',
        ];

        for (final prefix in storagePrefixes) {
          if (path.startsWith(prefix)) {
            relativePath = path.substring(prefix.length);
            break;
          }
        }

        if (relativePath != null && relativePath.isNotEmpty) {
          // Open the specific folder
          await openFileManager(
            androidConfig: AndroidConfig(
              folderType: AndroidFolderType.other,
              folderPath: relativePath,
            ),
          );
        } else {
          // Fallback: try to determine folder type based on path
          if (path.toLowerCase().contains('download')) {
            await openFileManager(
              androidConfig: AndroidConfig(
                folderType: AndroidFolderType.download,
              ),
            );
          } else {
            // Open recent folder as last resort
            await openFileManager(
              androidConfig: AndroidConfig(
                folderType: AndroidFolderType.recent,
              ),
            );
            _showErrorSnackBar('已打开最近文件，请手动查找');
          }
        }
      } else if (Platform.isIOS) {
        // iOS doesn't allow opening folders directly
        _showErrorSnackBar('iOS 不支持直接打开文件夹');
      } else if (Platform.isWindows) {
        // On Windows, use 'start' command which is safer and won't be flagged by antivirus
        // This opens the folder in Windows Explorer
        final result = await Process.run(
          'cmd',
          ['/c', 'start', '', directory.path],
          runInShell: true,
        );
        if (result.exitCode != 0) {
          _showErrorSnackBar('无法打开文件夹');
        }
      } else if (Platform.isMacOS) {
        // On macOS, use 'open' command to reveal file in Finder
        final result = await Process.run(
          'open',
          ['-R', item.savedPath!],
        );
        if (result.exitCode != 0) {
          _showErrorSnackBar('无法打开文件夹');
        }
      } else {
        // For Linux, use url_launcher with file:// scheme
        final uri = Uri.file(directory.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorSnackBar('无法打开文件夹');
        }
      }
    } catch (e) {
      _showErrorSnackBar('打开文件夹失败: $e');
    }
  }

  /// Delete a single record
  Future<void> _deleteRecord(TransferHistory item) async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '删除记录',
      message: '确定要删除 "${item.fileName}" 的传输记录吗？\n\n注意：这只会删除记录，不会删除文件本身。',
      confirmText: '删除',
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );

    if (confirmed) {
      await _historyService.deleteTransfer(item);
      await _loadHistory();

      if (mounted) {
        ToastHelper.showSuccess(context, '记录已删除');
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ToastHelper.showError(context, message);
    }
  }

  /// Show detail dialog for a transfer history item
  void _showDetailDialog(TransferHistory item) {
    DialogHelper.showCustomDialog(
      context,
      title: Row(
        children: [
          Icon(
            item.isReceived ? Icons.download : Icons.upload,
            color: item.isReceived ? Colors.green : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isReceived ? '接收记录' : '发送记录',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Icon(
            item.success ? Icons.check_circle : Icons.error,
            color: item.success ? Colors.green : Colors.red,
            size: 24,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('文件名', item.fileName),
            const Divider(height: 20),
            _buildDetailRow(
              '文件大小',
              FormatUtil.formatBytes(item.fileSize),
            ),
            const Divider(height: 20),
            if (item.peerDeviceName != null) ...[
              _buildDetailRow(
                item.isReceived ? '来自设备' : '发送至设备',
                item.peerDeviceName!,
              ),
              const Divider(height: 20),
              _buildDetailRow('设备 IP', item.peerIP),
            ] else ...[
              _buildDetailRow(
                item.isReceived ? '来自设备' : '发送至设备',
                item.peerIP,
              ),
            ],
            const Divider(height: 20),
            _buildDetailRow(
              '传输时间',
              FormatUtil.formatFullDateTime(item.timestamp),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              '传输状态',
              item.success ? '成功' : '失败',
              valueColor: item.success ? Colors.green : Colors.red,
            ),
            if (item.isReceived && item.savedPath != null) ...[
              const Divider(height: 20),
              _buildDetailRow('保存位置', item.savedPath!, copyable: true),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// Build a detail row in the dialog
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool copyable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (copyable)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copyPathToClipboard(value),
                tooltip: '复制',
                color: Colors.blue,
              ),
          ],
        ),
      ],
    );
  }

  /// Copy file path to clipboard
  Future<void> _copyPathToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));

    if (mounted) {
      ToastHelper.showSuccess(context, '路径已复制到剪贴板');
    }
  }
}
