import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/transfer_history.dart';
import '../services/transfer_history_service.dart';

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
  final TransferHistoryService _historyService = TransferHistoryService();
  List<TransferHistory> _history = [];
  TransferStatistics? _statistics;
  bool _isLoading = true;
  bool _isStatisticsExpanded = false;
  HistoryFilter _currentFilter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史记录'),
        content: const Text('确定要清除所有传输历史记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label),
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _currentFilter = filter;
            });
          }
        },
        showCheckmark: false,
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                '传输历史',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (_history.isNotEmpty)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearHistory,
                  tooltip: '清除历史',
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
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isStatisticsExpanded = !_isStatisticsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '统计信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '总传输',
                          stats.totalTransfers.toString(),
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '成功',
                          stats.successfulTransfers.toString(),
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '失败',
                          stats.failedTransfers.toString(),
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '已发送',
                          stats.sentFiles.toString(),
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '已接收',
                          stats.receivedFiles.toString(),
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '总大小',
                          _formatBytes(stats.totalBytes),
                          Colors.teal,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
    final iconColor = item.isReceived ? Colors.green : Colors.blue;
    final statusIcon = item.success ? Icons.check_circle : Icons.error;
    final statusColor = item.success ? Colors.green : Colors.red;

    // Display device name if available, otherwise show IP
    final peerDisplay = item.peerDeviceName ?? item.peerIP;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.isReceived ? '来自' : '发送至'}: $peerDisplay',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
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
      final uri = Uri.file(item.savedPath!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('无法打开文件');
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
      final uri = Uri.directory(directory.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('无法打开文件夹');
      }
    } catch (e) {
      _showErrorSnackBar('打开文件夹失败: $e');
    }
  }

  /// Delete a single record
  Future<void> _deleteRecord(TransferHistory item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text(
          '确定要删除 "${item.fileName}" 的传输记录吗？\n\n注意：这只会删除记录，不会删除文件本身。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.deleteTransfer(item);
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('记录已删除'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show detail dialog for a transfer history item
  void _showDetailDialog(TransferHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              _buildDetailRow('文件大小', _formatBytes(item.fileSize)),
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
              _buildDetailRow('传输时间', _formatFullDateTime(item.timestamp)),
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
      ),
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

  /// Format full date time for detail view
  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Copy file path to clipboard
  Future<void> _copyPathToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('路径已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
