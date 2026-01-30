import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;

import '../models/transfer_history.dart';
import '../utils/constants.dart';

/// Service for managing transfer history
///
/// Provides functionality to:
/// - Save transfer history to local storage
/// - Load transfer history from local storage
/// - Clear transfer history
class TransferHistoryService {
  static const String _historyFileName = 'transfer_history.json';
  static const int _maxHistoryItems =
      AppConstants.maxHistoryItems; // Keep last 100 transfers

  /// Get the history file path
  Future<String> _getHistoryFilePath() async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return '${directory.path}/$_historyFileName';
  }

  /// Load transfer history from local storage
  ///
  /// Returns a list of [TransferHistory] objects, sorted by timestamp (newest first)
  Future<List<TransferHistory>> loadHistory() async {
    try {
      final filePath = await _getHistoryFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      final history = jsonList
          .map((json) => TransferHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by timestamp, newest first
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return history;
    } catch (e) {
      // If error loading history, return empty list
      return [];
    }
  }

  /// Save a transfer record to history
  ///
  /// Adds the new record to the history and saves to local storage.
  /// Keeps only the most recent [_maxHistoryItems] records.
  Future<void> saveTransfer(TransferHistory transfer) async {
    try {
      // Load existing history
      final history = await loadHistory();

      // Add new transfer at the beginning
      history.insert(0, transfer);

      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save to file
      await _saveHistory(history);
    } catch (e) {
      // Silently fail if we can't save history
      // This is not critical functionality
    }
  }

  /// Save the entire history list to local storage
  Future<void> _saveHistory(List<TransferHistory> history) async {
    try {
      final filePath = await _getHistoryFilePath();
      final file = File(filePath);

      final jsonList = history.map((h) => h.toJson()).toList();
      final contents = jsonEncode(jsonList);

      await file.writeAsString(contents);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all transfer history
  Future<void> clearHistory() async {
    try {
      final filePath = await _getHistoryFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete a single transfer record
  ///
  /// Removes the specified transfer from history and saves the updated list
  Future<void> deleteTransfer(TransferHistory transfer) async {
    try {
      final history = await loadHistory();

      // Remove the transfer by matching timestamp and fileName
      history.removeWhere(
        (h) =>
            h.timestamp == transfer.timestamp &&
            h.fileName == transfer.fileName &&
            h.peerIP == transfer.peerIP,
      );

      // Save updated history
      await _saveHistory(history);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get transfer statistics
  Future<TransferStatistics> getStatistics() async {
    final history = await loadHistory();

    int totalTransfers = history.length;
    int successfulTransfers = history.where((h) => h.success).length;
    int failedTransfers = totalTransfers - successfulTransfers;
    int sentFiles = history.where((h) => !h.isReceived).length;
    int receivedFiles = history.where((h) => h.isReceived).length;
    int totalBytes = history.fold(0, (sum, h) => sum + h.fileSize);

    return TransferStatistics(
      totalTransfers: totalTransfers,
      successfulTransfers: successfulTransfers,
      failedTransfers: failedTransfers,
      sentFiles: sentFiles,
      receivedFiles: receivedFiles,
      totalBytes: totalBytes,
    );
  }
}

/// Transfer statistics
class TransferStatistics {
  final int totalTransfers;
  final int successfulTransfers;
  final int failedTransfers;
  final int sentFiles;
  final int receivedFiles;
  final int totalBytes;

  TransferStatistics({
    required this.totalTransfers,
    required this.successfulTransfers,
    required this.failedTransfers,
    required this.sentFiles,
    required this.receivedFiles,
    required this.totalBytes,
  });
}
