/// 文件传输数据结果
class TransferData {
  final String? savedPath;
  final int bytesTransferred;

  TransferData({
    this.savedPath,
    required this.bytesTransferred,
  });
}