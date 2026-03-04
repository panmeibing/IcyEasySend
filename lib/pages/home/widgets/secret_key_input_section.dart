import 'package:flutter/material.dart';

import '../../../utils/dialog_helper.dart';

/// Secret key input section widget
class SecretKeyInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isEnabled;
  final VoidCallback onClear;

  const SecretKeyInputSection({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isEnabled,
    required this.onClear,
  });

  /// Show help dialog with secret key information
  void _showHelpDialog(BuildContext context) {
    DialogHelper.showCustomDialog(
      context,
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Color(0xFF2196F3)),
          SizedBox(width: 8),
          Text('关于秘钥'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '秘钥功能说明',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '如果目标设备设置了秘钥，输入正确的秘钥后可以跳过确认框，直接传输文件或同步剪切板。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '使用步骤：',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. 目标设备在设置页面中设置本机秘钥\n'
              '2. 在此输入框中输入目标设备的秘钥\n'
              '3. 发送文件或请求剪切板时，如果秘钥正确，对方会自动接受',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '提示：留空则使用传统的手动确认方式',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '目标设备秘钥（可选）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '正确的秘钥可跳过对方确认',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showHelpDialog(context),
                        icon: const Icon(Icons.help_outline),
                        tooltip: '秘钥说明',
                        iconSize: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                enabled: isEnabled,
                obscureText: true,
                maxLength: 20,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return null; // Hide the counter
                    },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isEnabled && controller.text.isNotEmpty
                  ? onClear
                  : null,
              icon: const Icon(Icons.clear),
              tooltip: '清空秘钥',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade50,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
