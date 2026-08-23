import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:icy_easy_send/utils/constants.dart';

import '../models/transfer_data.dart';
import '../models/transfer_file_item.dart';
import '../transport/channel_selector.dart';
import '../transport/lan_channel.dart';
import '../transport/transport_channel.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import 'preferences_service.dart';
import 'relay/relay_service.dart';
import 'transfer/batch_transfer_manager.dart';
import 'transfer/file_receiver.dart';
import 'transfer/file_sender.dart' as sender;
import 'transfer/health_checker.dart' as checker;
import 'transfer_history_service.dart';
import 'validation_service.dart';

class FileTransferService {
  final FileReceiver _fileReceiver;
  final TransportChannel _lanChannel;
  final String logTag = LogTags.transfer;

  /// Resolved on first use rather than in the constructor, because the relay
  /// service builds a [FileTransferService] of its own for the receive side.
  /// Taking the channel eagerly would make the two construct each other.
  TransportChannel? _relayChannel;

  /// Injected by tests; production builds one that sees the live channels.
  final ChannelSelector? _channelSelector;

  FileTransferService({
    TransferHistoryService? historyService,
    PreferencesService? preferencesService,
    ValidationService? validationService,
    checker.HealthChecker? healthChecker,
    sender.FileSender? fileSender,
    FileReceiver? fileReceiver,
    BatchTransferManager? batchTransferManager,
    TransportChannel? lanChannel,
    TransportChannel? relayChannel,
    ChannelSelector? channelSelector,
  }) : _fileReceiver =
           fileReceiver ?? FileReceiver(validationService: validationService),
       _relayChannel = relayChannel,
       _channelSelector = channelSelector,
       _lanChannel =
           lanChannel ??
           LanChannel(
             batchTransferManager:
                 batchTransferManager ??
                 BatchTransferManager(
                   preferencesService: preferencesService,
                   validationService: validationService,
                   healthChecker: healthChecker,
                   fileSender: fileSender,
                 ),
             healthChecker: healthChecker,
           );

  /// Send files to a peer reachable at [targetIP] (`ip` or `ip:port`).
  Future<Map<String, OperationResult<TransferData>>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<TransferFileItem> files,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    )?
    onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) {
    return sendFilesTo(
      peer: PeerRef.lanAddress(targetIP),
      files: files,
      secretKey: secretKey,
      onProgress: onProgress,
      onFileProgress: onFileProgress,
      onStatusChange: onStatusChange,
      onHistoryUpdated: onHistoryUpdated,
    );
  }

  /// Send files to [peer] over the best channel currently available.
  Future<Map<String, OperationResult<TransferData>>> sendFilesTo({
    required PeerRef peer,
    required List<TransferFileItem> files,
    String? secretKey,
    TransferProgressCallback? onProgress,
    FileProgressCallback? onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) async {
    final resolved = _withFreshPresence(peer);
    final selector = _selector();
    final selection = await selector.select(resolved);
    if (selection == null) {
      final reason = selector.unreachableMessage(resolved);
      LogUtil.wTag(
        logTag,
        '选路失败: ${resolved.describe()}, 原因=$reason',
      );
      return {
        for (final item in files)
          item.transferName: OperationResult<TransferData>.failure(reason),
      };
    }

    LogUtil.iTag(
      logTag,
      '开始批量文件传输: 目标=${resolved.describe()}, '
      '通道=${selection.channel.kind.name}, 文件数=${files.length}',
    );

    try {
      final results = await selection.channel.sendFiles(
        peer: resolved,
        files: files,
        secretKey: secretKey,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        onStatusChange: onStatusChange,
        onHistoryUpdated: onHistoryUpdated,
      );

      int successCount = 0;
      int failureCount = 0;

      for (final entry in results.entries) {
        if (entry.value.isSuccess) {
          successCount++;
        } else {
          failureCount++;
          LogUtil.wTag(
            logTag,
            '文件传输失败: ${entry.key}, 原因: ${entry.value.errorMessage}',
          );
        }
      }

      LogUtil.iTag(
        logTag,
        '批量传输完成: 成功=$successCount, 失败=$failureCount, 总数=${files.length}',
      );

      return results;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '批量文件传输异常: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Probe whether [peer] is currently reachable, without sending anything.
  ///
  /// Races the same way a send would, so a peer that is only reachable over
  /// one of two advertised paths still reports as reachable.
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout}) async {
    final resolved = _withFreshPresence(peer);
    final selection = await _selector().select(resolved);
    if (selection == null) {
      return ProbeResult.unreachable(
        kind: resolved.hasLan ? TransportKind.lan : TransportKind.relay,
        errorMessage: _selector().unreachableMessage(resolved),
      );
    }
    // Prefer the selection's own probe when the caller did not ask for a
    // different timeout; otherwise re-probe the winning channel.
    if (timeout == null) {
      return selection.probe;
    }
    return selection.channel.probe(resolved, timeout: timeout);
  }

  ChannelSelector _selector() {
    return _channelSelector ??
        ChannelSelector(
          lan: _lanChannel,
          relay: _relayChannel ??= RelayService.instance.channel,
        );
  }

  /// Refreshes [PeerRef.relayOnline] from the live presence set.
  ///
  /// A stale flag would skip the relay probe entirely. When the relay is not
  /// connected there is nothing fresher to read, so the caller's stamp is kept
  /// — which is also what lets unit tests drive routing without a live client.
  PeerRef _withFreshPresence(PeerRef peer) {
    final id = peer.deviceId;
    if (id == null || id.isEmpty) {
      return peer;
    }
    try {
      final client = RelayService.instance.client;
      if (!client.config.isActive || !client.isConnected) {
        return peer;
      }
      return peer.copyWith(relayOnline: client.isOnline(id));
    } catch (_) {
      return peer;
    }
  }

  Future<OperationResult<TransferData>> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    void Function(double progress, int bytesReceived, int totalBytes)?
    onProgress,
  }) async {
    LogUtil.iTag(
      logTag,
      '开始接收文件: $fileName, 大小=${(fileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB, 来自=$senderIP',
    );

    try {
      final result = await _fileReceiver.receiveFileDirectly(
        fileStream: fileStream,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        senderDeviceName: senderDeviceName,
        onProgress: onProgress,
      );

      if (result.isSuccess) {
        LogUtil.iTag(
          logTag,
          '文件接收成功: $fileName, 保存路径=${result.data!.savedPath}',
        );
        return OperationResult.success(
          data: TransferData(
            savedPath: result.data!.savedPath,
            bytesTransferred: result.data!.bytesTransferred,
          ),
        );
      } else {
        LogUtil.wTag(logTag, '文件接收失败: $fileName, 原因=${result.errorMessage}');
        return OperationResult.failure(result.errorMessage!);
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '文件接收异常: $fileName, 错误=$e', e, stackTrace);
      rethrow;
    }
  }

  /// Moves a fully received partial file into the save directory.
  ///
  /// Used by the resumable relay path, which writes the bytes itself so it can
  /// keep track of chunks, and then hands the finished file over to the same
  /// save logic every other transfer goes through.
  Future<OperationResult<TransferData>> adoptReceivedFile({
    required File source,
    required String fileName,
    required int fileSize,
  }) {
    return _fileReceiver.adoptReceivedFile(
      source: source,
      fileName: fileName,
      fileSize: fileSize,
    );
  }
}
