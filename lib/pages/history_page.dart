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
import 'history/widgets/history_app_bar.dart';
import 'history/widgets/history_empty_state.dart';
import 'history/widgets/history_filter_chips.dart';
import 'history/widgets/history_list_item.dart';
import 'history/widgets/history_statistics_card.dart';

export 'history/widgets/history_filter_chips.dart' show HistoryFilter;

/// History page to display transfer history
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const HistoryEmptyState();
    }

    return Column(
      children: [
        HistoryAppBar(
          hasHistory: _history.isNotEmpty,
          onClearHistory: _clearHistory,
        ),
        HistoryFilterChips(
          currentFilter: _currentFilter,
          history: _history,
          onFilterChanged: (filter) {
            setState(() {
              _currentFilter = filter;
            });
          },
        ),
        if (_statistics != null)
          HistoryStatisticsCard(
            statistics: _statistics!,
            isExpanded: _isStatisticsExpanded,
            onToggle: () {
              setState(() {
                _isStatisticsExpanded = !_isStatisticsExpanded;
              });
            },
          ),
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
        return HistoryListItem(
          item: item,
          onTap: () => _showDetailDialog(item),
          onMenuAction: (action) => _handleMenuAction(action, item),
        );
      },
    );
  }

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
        final result = await OpenFilex.open(item.savedPath!);
        if (result.type != ResultType.done) {
          _showErrorSnackBar('无法打开文件: ${result.message}');
        }
      } else {
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
        final path = directory.path;
        String? relativePath;

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
          await openFileManager(
            androidConfig: AndroidConfig(
              folderType: AndroidFolderType.other,
              folderPath: relativePath,
            ),
          );
        } else {
          if (path.toLowerCase().contains('download')) {
            await openFileManager(
              androidConfig: AndroidConfig(
                folderType: AndroidFolderType.download,
              ),
            );
          } else {
            await openFileManager(
              androidConfig: AndroidConfig(
                folderType: AndroidFolderType.recent,
              ),
            );
            _showErrorSnackBar('已打开最近文件，请手动查找');
          }
        }
      } else if (Platform.isIOS) {
        _showErrorSnackBar('iOS 不支持直接打开文件夹');
      } else if (Platform.isWindows) {
        final result = await Process.run('cmd', [
          '/c',
          'start',
          '',
          directory.path,
        ], runInShell: true);
        if (result.exitCode != 0) {
          _showErrorSnackBar('无法打开文件夹');
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('open', ['-R', item.savedPath!]);
        if (result.exitCode != 0) {
          _showErrorSnackBar('无法打开文件夹');
        }
      } else {
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
            _buildDetailRow('文件大小', FormatUtil.formatBytes(item.fileSize)),
            const Divider(height: 20),
            if (item.peerDeviceName != null) ...[
              _buildDetailRow(
                item.isReceived ? '来自设备' : '发送至设备',
                item.peerDeviceName!,
              ),
              const Divider(height: 20),
              _buildDetailRow('设备 IP', item.peerIP),
            ] else ...[
              _buildDetailRow(item.isReceived ? '来自设备' : '发送至设备', item.peerIP),
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
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyPathToClipboard(value),
                  tooltip: '复制',
                  color: Colors.blue,
                ),
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
