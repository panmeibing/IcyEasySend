import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// IP address input section widget
class IPInputSection extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorMessage;
  final bool isEnabled;
  final List<String> ipHistory;
  final String? serverAddress;
  final Function(String) onIPSelected;
  final Function(String) onIPDeleted;

  const IPInputSection({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorMessage,
    required this.isEnabled,
    required this.ipHistory,
    this.serverAddress,
    required this.onIPSelected,
    required this.onIPDeleted,
  });

  @override
  State<IPInputSection> createState() => _IPInputSectionState();
}

class _IPInputSectionState extends State<IPInputSection> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  /// Extract the network segment (first 3 octets) from server address
  /// Returns null if server address is invalid or not available
  String? _extractNetworkSegment() {
    if (widget.serverAddress == null || widget.serverAddress!.isEmpty) {
      return null;
    }

    // Server address format is typically "http://192.168.1.100:8080"
    // Extract the IP part
    final addressPattern = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
    final match = addressPattern.firstMatch(widget.serverAddress!);

    if (match == null) {
      return null;
    }

    final ip = match.group(1);
    if (ip == null) {
      return null;
    }

    // Split by dots and take first 3 octets
    final parts = ip.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.targetDeviceIP,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: l10n.ipHint,
            border: const OutlineInputBorder(),
            errorText: widget.errorMessage,
            errorMaxLines: 10,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasText)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: l10n.clear,
                    onPressed: () {
                      widget.controller.clear();
                    },
                  ),
                if (widget.ipHistory.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.history),
                    tooltip: l10n.history,
                    onSelected: widget.onIPSelected,
                    itemBuilder: (BuildContext context) {
                      return widget.ipHistory.map((String ip) {
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
                                  widget.onIPDeleted(ip);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
              ],
            ),
          ),
          keyboardType: TextInputType.number,
          enabled: widget.isEnabled,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // First button: local network segment if available
            if (_extractNetworkSegment() != null)
              _buildQuickIPButton(_extractNetworkSegment()!),
            // Fallback buttons
            _buildQuickIPButton('192.168.1.1'),
            _buildQuickIPButton('10.0.0.1'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickIPButton(String ip) {
    return OutlinedButton.icon(
      onPressed: widget.isEnabled ? () => widget.onIPSelected(ip) : null,
      icon: const Icon(Icons.touch_app, size: 16),
      label: Text(ip),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
