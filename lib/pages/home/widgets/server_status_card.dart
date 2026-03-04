import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/toast_helper.dart';

/// Server status indicator widget
class ServerStatusCard extends StatelessWidget {
  final bool isServerRunning;
  final String? serverAddress;

  const ServerStatusCard({
    super.key,
    required this.isServerRunning,
    this.serverAddress,
  });

  @override
  Widget build(BuildContext context) {
    // Parse IP and port from serverAddress
    String? ip;
    String? port;
    if (serverAddress != null) {
      final parts = serverAddress!.split(':');
      if (parts.length == 2) {
        ip = parts[0];
        port = parts[1];
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isServerRunning
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isServerRunning
              ? const Color(0xFF2196F3)
              : const Color(0xFFE53935),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isServerRunning
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isServerRunning ? '服务器运行中' : '服务器已停止',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isServerRunning
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          if (isServerRunning && ip != null && port != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本机IP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ip,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF212121),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _copyToClipboard(context, ip!),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2196F3,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '端口',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      port,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Copy text to clipboard
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ToastHelper.showSuccess(context, 'IP地址已复制: $text');
    }
  }
}
