import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:icy_easy_send/utils/constants.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../models/clipboard_data_model.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';
import '../utils/operation_result.dart';
import 'native_clipboard_service.dart';

/// 增强的剪切板服务类
///
/// 支持文本和任意文件的剪切板操作
/// 使用 super_clipboard 包实现跨平台兼容
class ClipboardService {
  final String logTag = LogTags.clipboard;

  /// 从文件 URI 读取文件
  ///
  /// 参数:
  /// - [uri]: 文件 URI
  ///
  /// 返回: 包含文件数据的 ClipboardDataModel，如果失败则返回 null
  Future<ClipboardDataModel?> _readFileFromUri(Uri uri) async {
    LogUtil.iTag(logTag, '读取到文件 URI: $uri');

    try {
      final filePath = uri.toFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        LogUtil.wTag(logTag, '文件不存在: $filePath');
        return null;
      }

      // 获取文件信息
      final fileName = path.basename(filePath);
      final fileSize = await file.length();

      LogUtil.dTag(logTag, '文件名: $fileName, 大小: $fileSize bytes');

      // 读取文件数据
      final bytes = await file.readAsBytes();

      // 获取 MIME 类型
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      LogUtil.iTag(
        logTag,
        '成功读取文件，名称: $fileName, MIME: $mimeType, 大小: ${bytes.length} bytes',
      );

      return ClipboardDataModel(
        type: ClipboardDataType.file,
        fileData: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '读取文件失败: $e', e, stackTrace);
      return null;
    }
  }

  /// 解析 HTTP 响应中的剪切板数据
  ///
  /// 参数:
  /// - [responseBody]: HTTP 响应体
  ///
  /// 返回: 操作结果，包含剪切板数据或错误信息
  OperationResult<ClipboardDataModel> _parseClipboardResponse(
    String responseBody,
  ) {
    try {
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      final accepted = responseData['accepted'] as bool? ?? false;

      if (!accepted) {
        final message = responseData['message'] as String? ?? '用户拒绝了请求';
        LogUtil.wTag(logTag, '请求被拒绝: $message');
        return OperationResult.failure(message);
      }

      final clipboardDataJson =
          responseData['clipboardData'] as Map<String, dynamic>?;

      if (clipboardDataJson == null) {
        LogUtil.wTag(logTag, '目标设备剪切板为空');
        return OperationResult.failure('目标设备剪切板为空');
      }

      final clipboardData = ClipboardDataModel.fromJson(clipboardDataJson);

      LogUtil.iTag(
        logTag,
        '成功获取剪切板内容，类型: ${clipboardData.typeDescription}, 大小: ${clipboardData.sizeInMB.toStringAsFixed(2)} MB',
      );
      return OperationResult.success(data: clipboardData);
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '解析响应失败: $e', e, stackTrace);
      return OperationResult.failure('解析响应失败: $e');
    }
  }

  /// 获取本地剪切板内容
  ///
  /// 返回剪切板中的内容（文本或文件），如果剪切板为空或出错则返回null
  /// 优先级：文件 URI > 纯文本
  Future<ClipboardDataModel?> getClipboardContent() async {
    LogUtil.dTag(logTag, '正在读取本地剪切板...');

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final imageData = await _readNativeImage();
        if (imageData != null) {
          return imageData;
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, '原生读取图片失败: $e', e, stackTrace);
      }
    }

    ClipboardDataModel? imageData;
    try {
      imageData = await _readImageFromSuperClipboard();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '通过 super_clipboard 读取图片失败: $e', e, stackTrace);
    }
    if (imageData != null) {
      return imageData;
    }

    ClipboardDataModel? fileData;
    try {
      fileData = await _readFileFromSuperClipboard();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '通过 super_clipboard 读取文件失败: $e', e, stackTrace);
    }
    if (fileData != null) {
      return fileData;
    }

    // Native text after binary content — avoids treating copied images as text.
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final nativeText = await _readNativeText();
        if (nativeText != null) {
          return nativeText;
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, '原生读取文本失败: $e', e, stackTrace);
      }
    }

    ClipboardDataModel? textData;
    try {
      textData = await _readTextFromSuperClipboard();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'super_clipboard 读取文本失败: $e', e, stackTrace);
    }
    if (textData != null) {
      return textData;
    }

    LogUtil.wTag(logTag, '剪切板为空或不包含支持的格式');
    return null;
  }

  Future<ClipboardDataModel?> _readNativeImage() async {
    final image = await NativeClipboardService.getImageFromClipboard();
    if (image == null) {
      return null;
    }

    final mimeType = image.mimeType ?? 'image/png';
    final extension = mimeType.contains('jpeg') || mimeType.contains('jpg')
        ? 'jpg'
        : mimeType.contains('png')
        ? 'png'
        : mimeType.contains('webp')
        ? 'webp'
        : 'png';
    final fileName = image.fileName ?? 'clipboard_image.$extension';

    LogUtil.iTag(
      logTag,
      '成功通过原生 API 读取图片剪切板，大小: ${image.bytes.length} bytes',
    );

    return ClipboardDataModel(
      type: ClipboardDataType.file,
      fileData: image.bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<ClipboardDataModel?> _readNativeText() async {
    final nativeText = await NativeClipboardService.getTextFromClipboard();
    if (nativeText == null) {
      LogUtil.dTag(logTag, '原生 API 未读取到文本');
      return null;
    }

    final text = _htmlToPlainText(nativeText);
    if (text.isEmpty) {
      LogUtil.dTag(logTag, '原生 API 读取结果为空文本');
      return null;
    }

    LogUtil.iTag(logTag, '成功通过原生 API 读取剪切板，长度: ${text.length}');
    return ClipboardDataModel(
      type: ClipboardDataType.text,
      textContent: text,
    );
  }

  Future<ClipboardDataModel?> _readImageFromSuperClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return null;
    }

    ClipboardDataReader reader;
    try {
      reader = await clipboard.read();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'super_clipboard 打开失败: $e', e, stackTrace);
      return null;
    }

    LogUtil.dTag(logTag, '剪切板可用格式: ${reader.platformFormats}');

    if (reader.canProvide(Formats.png)) {
      try {
        final bytes = await _readSuperClipboardFile(reader, Formats.png);
        if (bytes != null && bytes.isNotEmpty) {
          LogUtil.iTag(logTag, '成功读取 PNG 剪切板，大小: ${bytes.length} bytes');
          return ClipboardDataModel(
            type: ClipboardDataType.file,
            fileData: bytes,
            fileName: 'clipboard_image.png',
            mimeType: 'image/png',
          );
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, 'super_clipboard 读取 PNG 失败: $e', e, stackTrace);
      }
    }

    if (reader.canProvide(Formats.jpeg)) {
      try {
        final bytes = await _readSuperClipboardFile(reader, Formats.jpeg);
        if (bytes != null && bytes.isNotEmpty) {
          LogUtil.iTag(logTag, '成功读取 JPEG 剪切板，大小: ${bytes.length} bytes');
          return ClipboardDataModel(
            type: ClipboardDataType.file,
            fileData: bytes,
            fileName: 'clipboard_image.jpg',
            mimeType: 'image/jpeg',
          );
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, 'super_clipboard 读取 JPEG 失败: $e', e, stackTrace);
      }
    }

    return null;
  }

  Future<Uint8List?> _readSuperClipboardFile(
    ClipboardDataReader reader,
    FileFormat format,
  ) async {
    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(format, (file) async {
      try {
        completer.complete(await file.readAll());
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, '读取剪切板文件流失败: $e', e, stackTrace);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }, onError: (error) {
      LogUtil.wTag(logTag, 'getFile 失败: $error');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    if (progress == null) {
      return null;
    }

    return completer.future;
  }

  Future<ClipboardDataModel?> _readFileFromSuperClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      LogUtil.wTag(logTag, '剪切板 API 不可用');
      return null;
    }

    final reader = await clipboard.read();
    LogUtil.dTag(logTag, '剪切板可用格式: ${reader.platformFormats}');

    if (!reader.canProvide(Formats.fileUri)) {
      return null;
    }

    LogUtil.dTag(logTag, '检测到文件 URI');
    try {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri == null) {
        return null;
      }

      return _readFileFromUri(uri);
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'super_clipboard 读取 fileUri 失败: $e', e, stackTrace);
      return null;
    }
  }

  Future<ClipboardDataModel?> _readTextFromSuperClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return null;
    }

    ClipboardDataReader reader;
    try {
      reader = await clipboard.read();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'super_clipboard 打开失败: $e', e, stackTrace);
      return null;
    }

    LogUtil.dTag(logTag, 'super_clipboard 可用格式: ${reader.platformFormats}');

    if (reader.canProvide(Formats.plainText)) {
      try {
        final text = await reader.readValue(Formats.plainText);
        if (text != null && text.trim().isNotEmpty) {
          LogUtil.iTag(logTag, '成功读取纯文本剪切板，长度: ${text.length}');
          return ClipboardDataModel(
            type: ClipboardDataType.text,
            textContent: text.trim(),
          );
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, 'super_clipboard 读取 plainText 失败: $e', e, stackTrace);
      }
    }

    if (reader.canProvide(Formats.htmlText)) {
      LogUtil.dTag(logTag, '检测到 HTML 剪切板，尝试提取文本');
      try {
        final html = await reader.readValue(Formats.htmlText);
        final text = _htmlToPlainText(html);
        if (text.isNotEmpty) {
          LogUtil.iTag(logTag, '成功从 HTML 剪切板提取文本，长度: ${text.length}');
          return ClipboardDataModel(
            type: ClipboardDataType.text,
            textContent: text,
          );
        }
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, 'super_clipboard 读取 htmlText 失败: $e', e, stackTrace);
      }
    }

    return null;
  }

  String _htmlToPlainText(String? html) {
    if (html == null || html.trim().isEmpty) {
      return '';
    }

    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    text = text.replaceAll(RegExp(r'[ \t\f\v]+'), ' ');
    text = text.replaceAll(RegExp(r'\n[ \t]+'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// 创建临时文件
  ///
  /// 将文件数据保存为临时文件，用于在文件管理器中粘贴
  ///
  /// 参数:
  /// - [fileData]: 文件字节数据
  /// - [fileName]: 文件名
  ///
  /// 返回: 临时文件的 URI，如果失败则返回 null
  Future<Uri?> _createTempFile(Uint8List fileData, String fileName) async {
    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();

      // 创建专门的剪切板文件目录
      final clipboardDir = Directory(
        path.join(tempDir.path, 'clipboard_files'),
      );
      if (!await clipboardDir.exists()) {
        await clipboardDir.create(recursive: true);
      }

      // 清理旧的临时文件（保留最近的N个）
      await _cleanupOldTempFiles(clipboardDir);

      // 使用原始文件名，添加时间戳确保唯一性
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = path.basenameWithoutExtension(fileName);
      final extension = path.extension(fileName);
      final uniqueFileName = '${baseName}_$timestamp$extension';
      final filePath = path.join(clipboardDir.path, uniqueFileName);

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(fileData);

      LogUtil.iTag(logTag, '创建临时文件: $filePath');
      return file.uri;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '创建临时文件失败: $e', e, stackTrace);
      return null;
    }
  }

  /// 清理旧的临时文件
  ///
  /// 保留最近的指定数量的文件，删除其他文件
  Future<void> _cleanupOldTempFiles(
    Directory directory, {
    int keepCount = AppConstants.maxClipboardKeepCount,
  }) async {
    try {
      final files = await directory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      if (files.length <= keepCount) {
        return;
      }

      // 按修改时间排序
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // 删除旧文件
      for (var i = keepCount; i < files.length; i++) {
        try {
          await files[i].delete();
          LogUtil.dTag(logTag, '删除旧临时文件: ${files[i].path}');
        } catch (e) {
          LogUtil.wTag(logTag, '删除临时文件失败: $e');
        }
      }
    } catch (e) {
      LogUtil.wTag(logTag, '清理临时文件失败: $e');
    }
  }

  /// 设置本地剪切板内容
  ///
  /// 将指定的内容写入剪切板（文本或文件）
  /// 对于文件，会同时写入文件URI，使其可以在文件管理器中粘贴
  /// 对于图片文件，还会写入图片格式，使其可以在图片编辑器中粘贴
  ///
  /// 注意：Android 平台对文件 URI 的支持有限，主要支持图片数据
  Future<bool> setClipboardContent(ClipboardDataModel data) async {
    try {
      LogUtil.dTag(logTag, '正在写入剪切板，类型: ${data.typeDescription}');

      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        LogUtil.wTag(logTag, '剪切板 API 不可用');
        return false;
      }

      final item = DataWriterItem();

      // 处理文本类型
      if (data.type == ClipboardDataType.text && data.textContent != null) {
        item.add(Formats.plainText(data.textContent!));
        await clipboard.write([item]);
        LogUtil.iTag(logTag, '成功写入文本剪切板');
        return true;
      }

      // 处理文件类型
      if (data.type == ClipboardDataType.file &&
          data.fileData != null &&
          data.fileName != null) {
        // 如果是图片文件，写入图片格式（所有平台都支持）
        if (data.isImage) {
          final mimeType = data.mimeType ?? '';
          bool imageAdded = false;

          if (mimeType.contains('png')) {
            item.add(Formats.png(data.fileData!));
            imageAdded = true;
            LogUtil.dTag(logTag, '添加 PNG 图片格式');
          } else if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
            item.add(Formats.jpeg(data.fileData!));
            imageAdded = true;
            LogUtil.dTag(logTag, '添加 JPEG 图片格式');
          } else if (mimeType.contains('bmp')) {
            // BMP 格式需要转换为 PNG
            try {
              item.add(Formats.png(data.fileData!));
              imageAdded = true;
              LogUtil.dTag(logTag, '添加 BMP 图片（作为 PNG）');
            } catch (e) {
              LogUtil.wTag(logTag, 'BMP 格式处理失败: $e');
            }
          }

          if (imageAdded) {
            // 对于图片，在非 Android 平台也尝试添加文件 URI
            if (!Platform.isAndroid) {
              try {
                final fileUri = await _createTempFile(
                  data.fileData!,
                  data.fileName!,
                );
                if (fileUri != null) {
                  item.add(Formats.fileUri(fileUri));
                  LogUtil.dTag(logTag, '添加文件 URI（非 Android 平台）');
                }
              } catch (e) {
                LogUtil.wTag(logTag, '添加文件 URI 失败（非关键错误）: $e');
              }
            }

            await clipboard.write([item]);
            LogUtil.iTag(logTag, '成功写入图片剪切板: ${data.fileName}');
            return true;
          }
        }

        // 对于非图片文件，只在非 Android 平台尝试写入文件 URI
        if (!Platform.isAndroid) {
          try {
            final fileUri = await _createTempFile(
              data.fileData!,
              data.fileName!,
            );
            if (fileUri != null) {
              item.add(Formats.fileUri(fileUri));
              await clipboard.write([item]);
              LogUtil.iTag(logTag, '成功写入文件剪切板: ${data.fileName}（支持文件管理器粘贴）');
              return true;
            } else {
              LogUtil.wTag(logTag, '创建临时文件失败');
              return false;
            }
          } catch (e, stackTrace) {
            LogUtil.eTag(logTag, '写入文件 URI 失败: $e', e, stackTrace);
            return false;
          }
        } else {
          // Android 平台不支持非图片文件的剪切板
          LogUtil.wTag(logTag, 'Android 平台不支持非图片文件的剪切板操作: ${data.fileName}');
          return false;
        }
      }

      LogUtil.wTag(logTag, '无效的剪切板数据');
      return false;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '写入剪切板失败: $e', e, stackTrace);
      return false;
    }
  }

  /// 请求目标设备的剪切板内容
  ///
  /// 向目标设备发送HTTP请求，请求获取其剪切板内容
  /// 目标设备会弹出确认对话框，用户同意后返回剪切板内容
  ///
  /// 参数:
  /// - [targetIP]: 目标设备的IP地址
  /// - [port]: 目标设备的端口号
  /// - [deviceName]: 本设备的名称（可选）
  /// - [secretKey]: 秘钥（可选）
  ///
  /// 返回: [OperationResult<ClipboardDataModel>] 包含剪切板内容或错误信息
  Future<OperationResult<ClipboardDataModel>> requestClipboardFromDevice({
    required String targetIP,
    required int port,
    String? deviceName,
    String? secretKey,
  }) async {
    LogUtil.iTag(logTag, '向 $targetIP:$port 请求剪切板内容...');

    final url = NetworkUtil.buildHttpUrl(
      targetIP,
      '/clipboard-request',
      targetPort: port,
    );

    // 构建请求体
    final requestBody = jsonEncode({
      'requesterDeviceName': deviceName ?? '未知设备',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // 构建请求头
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (secretKey != null && secretKey.isNotEmpty) {
      headers['X-Secret-Key'] = secretKey;
    }

    // 发送POST请求
    final result = await HttpHelper.post(
      url,
      headers: headers,
      body: requestBody,
      timeout: AppConstants.confirmTimeout,
    );

    if (!result.isSuccess) {
      LogUtil.eTag(logTag, '请求剪切板失败: ${result.errorMessage}');
      return OperationResult.failure(result.errorMessage ?? '请求失败');
    }

    final response = result.data!;

    // 处理成功响应
    if (HttpHelper.isSuccessResponse(response)) {
      return _parseClipboardResponse(response.body);
    }

    // 处理内容过大响应
    if (response.statusCode == 413) {
      final message = HttpHelper.extractErrorMessage(response, '剪切板内容过大');
      LogUtil.wTag(logTag, '剪切板内容过大: $message');
      return OperationResult.failure(message);
    }

    // 处理其他错误响应
    final errorMessage = HttpHelper.extractErrorMessage(
      response,
      '请求失败 (${response.statusCode})',
    );
    LogUtil.eTag(logTag, '请求失败: $errorMessage');
    return OperationResult.failure(errorMessage);
  }

  /// 同步目标设备的剪切板到本地
  ///
  /// 这是一个便捷方法，组合了请求和写入操作
  Future<OperationResult<ClipboardDataModel>> syncClipboardFromDevice({
    required String targetIP,
    required int port,
    String? deviceName,
    String? secretKey,
  }) async {
    // 1. 请求目标设备的剪切板
    final requestResult = await requestClipboardFromDevice(
      targetIP: targetIP,
      port: port,
      deviceName: deviceName,
      secretKey: secretKey,
    );

    if (!requestResult.isSuccess) {
      return OperationResult.failure(requestResult.errorMessage ?? '请求失败');
    }

    final clipboardData = requestResult.data!;

    // 2. 写入本地剪切板
    final writeSuccess = await setClipboardContent(clipboardData);

    if (writeSuccess) {
      LogUtil.iTag(logTag, '剪切板同步成功');
      return OperationResult.success(data: clipboardData);
    }

    return OperationResult.failure('写入本地剪切板失败');
  }
}
