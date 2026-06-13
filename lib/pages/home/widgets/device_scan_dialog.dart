import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/discovered_device.dart';
import '../../../services/device_discovery_service.dart';

/// Dialog for scanning and selecting a device on the local network.
class DeviceScanDialog extends StatefulWidget {
  final Set<String> localIps;

  const DeviceScanDialog({
    super.key,
    required this.localIps,
  });

  @override
  State<DeviceScanDialog> createState() => _DeviceScanDialogState();
}

class _DeviceScanDialogState extends State<DeviceScanDialog> {
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();

  final List<DiscoveredDevice> _devices = [];
  bool _isScanning = true;
  int _scannedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _discoveryService.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _scannedCount = 0;
      _totalCount = 0;
    });

    try {
      final devices = await _discoveryService.scan(
        localIps: widget.localIps,
        onProgress: (scanned, total, found) {
          if (!mounted) return;
          setState(() {
            _scannedCount = scanned;
            _totalCount = total;
            _devices
              ..clear()
              ..addAll(found);
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _devices
          ..clear()
          ..addAll(devices);
        _isScanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _selectDevice(DiscoveredDevice device) {
    Navigator.of(context).pop(device);
  }

  void _cancel() {
    _discoveryService.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.devices, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.scanDevicesTitle)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isScanning) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                _totalCount > 0
                    ? l10n.scanProgress(
                        _scannedCount,
                        _totalCount,
                        _devices.length,
                      )
                    : l10n.scanningDevices,
                textAlign: TextAlign.center,
              ),
              if (_devices.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDeviceList(),
              ],
            ] else if (_devices.isEmpty) ...[
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                l10n.noDevicesFound,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noDevicesFoundHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ] else ...[
              Text(
                l10n.scanDevicesFound(_devices.length),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              _buildDeviceList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? _cancel : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (!_isScanning)
          ElevatedButton(
            onPressed: _startScan,
            child: Text(l10n.rescan),
          ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _devices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(Icons.computer, color: Colors.blue),
            ),
            title: Text(
              device.deviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(device.displayAddress),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectDevice(device),
          );
        },
      ),
    );
  }
}
