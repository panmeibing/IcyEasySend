import 'package:flutter/material.dart';

/// IP address input section widget
class IPInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorMessage;
  final bool isEnabled;
  final List<String> ipHistory;
  final VoidCallback onDiagnostics;
  final Function(String) onIPSelected;
  final Function(String) onIPDeleted;

  const IPInputSection({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorMessage,
    required this.isEnabled,
    required this.ipHistory,
    required this.onDiagnostics,
    required this.onIPSelected,
    required this.onIPDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '目标设备 IP 地址',
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
                  hintText: '例如: 192.168.1.100',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                  errorMaxLines: 10,
                  suffixIcon: ipHistory.isNotEmpty
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.history),
                          tooltip: '历史记录',
                          onSelected: onIPSelected,
                          itemBuilder: (BuildContext context) {
                            return ipHistory.map((String ip) {
                              return PopupMenuItem<String>(
                                value: ip,
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(ip)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        onIPDeleted(ip);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                        )
                      : null,
                ),
                keyboardType: TextInputType.number,
                enabled: isEnabled,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isEnabled ? onDiagnostics : null,
              icon: const Icon(Icons.network_check),
              tooltip: '网络诊断',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickIPButton('192.168.1.1'),
            _buildQuickIPButton('192.168.0.1'),
            _buildQuickIPButton('10.0.0.1'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickIPButton(String ip) {
    return OutlinedButton.icon(
      onPressed: isEnabled ? () => onIPSelected(ip) : null,
      icon: const Icon(Icons.touch_app, size: 16),
      label: Text(ip),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
