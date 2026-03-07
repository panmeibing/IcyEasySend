import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.clearHistoryTitle,
      message: l10n.clearHistoryMessage,
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
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
    final l10n = AppLocalizations.of(context);
    final filteredHistory = _filteredHistory;

    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              l10n.noFilteredRecords,
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
    final l10n = AppLocalizations.of(context);
    if (item.savedPath == null) {
      _showErrorSnackBar(l10n.filePathNotExist);
      return;
    }

    final file = File(item.savedPath!);
    if (!await file.exists()) {
      _showErrorSnackBar(l10n.fileNotExist);
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await OpenFilex.open(item.savedPath!);
        if (result.type != ResultType.done) {
          _showErrorSnackBar(l10n.cannotOpenFileWithMessage(result.message));
        }
      } else {
        final uri = Uri.file(item.savedPath!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorSnackBar(l10n.cannotOpenFile);
        }
      }
    } catch (e) {
      _showErrorSnackBar('${l10n.openFileFailed}: $e');
    }
  }

  /// Open the folder containing the file
  Future<void> _openFolder(TransferHistory item) async {
    final l10n = AppLocalizations.of(context);
    if (item.savedPath == null) {
      _showErrorSnackBar(l10n.filePathNotExist);
      return;
    }

    final file = File(item.savedPath!);
    final directory = file.parent;

    if (!await directory.exists()) {
      _showErrorSnackBar(l10n.folderNotExist);
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
            _showErrorSnackBar(l10n.recentFilesOpened);
          }
        }
      } else if (Platform.isIOS) {
        _showErrorSnackBar(l10n.iosNoFolderSupport);
      } else if (Platform.isWindows) {
        final result = await Process.run('cmd', [
          '/c',
          'start',
          '',
          directory.path,
        ], runInShell: true);
        if (result.exitCode != 0) {
          _showErrorSnackBar(l10n.cannotOpenFolder);
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('open', ['-R', item.savedPath!]);
        if (result.exitCode != 0) {
          _showErrorSnackBar(l10n.cannotOpenFolder);
        }
      } else {
        final uri = Uri.file(directory.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorSnackBar(l10n.cannotOpenFolder);
        }
      }
    } catch (e) {
      _showErrorSnackBar('${l10n.openFolderFailed}: $e');
    }
  }

  /// Delete a single record
  Future<void> _deleteRecord(TransferHistory item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.deleteRecordTitle,
      message: l10n.deleteRecordMessage(item.fileName),
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );

    if (confirmed) {
      await _historyService.deleteTransfer(item);
      await _loadHistory();

      if (mounted) {
        ToastHelper.showSuccess(context, l10n.recordDeleted);
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
    final l10n = AppLocalizations.of(context);
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
              item.isReceived ? l10n.receiveRecord : l10n.sendRecord,
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
            _buildDetailRow(l10n.fileName, item.fileName),
            const Divider(height: 20),
            _buildDetailRow(
              l10n.fileSize,
              FormatUtil.formatBytes(item.fileSize),
            ),
            const Divider(height: 20),
            if (item.peerDeviceName != null) ...[
              _buildDetailRow(
                item.isReceived ? l10n.fromDevice : l10n.toDevice,
                item.peerDeviceName!,
              ),
              const Divider(height: 20),
              _buildDetailRow(l10n.deviceIP, item.peerIP),
            ] else ...[
              _buildDetailRow(
                item.isReceived ? l10n.fromDevice : l10n.toDevice,
                item.peerIP,
              ),
            ],
            const Divider(height: 20),
            _buildDetailRow(
              l10n.transferTime,
              FormatUtil.formatFullDateTime(item.timestamp),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              l10n.transferStatus,
              item.success ? l10n.statusSuccess : l10n.statusFailed,
              valueColor: item.success ? Colors.green : Colors.red,
            ),
            if (item.isReceived && item.savedPath != null) ...[
              const Divider(height: 20),
              _buildDetailRow(
                l10n.savedLocation,
                item.savedPath!,
                copyable: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
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
    final l10n = AppLocalizations.of(context);
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
                  tooltip: l10n.copy,
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
      ToastHelper.showSuccess(context, AppLocalizations.of(context).pathCopied);
    }
  }
}
