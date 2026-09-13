import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../transport/transport_channel.dart';
import '../home_ui.dart';

/// A peer placed on the orbit ring at a fixed angle (degrees, 0 = east).
class OrbitSatellite {
  static const int maxVisible = 8;

  final PeerRef peer;
  final double angleDegrees;

  const OrbitSatellite({
    required this.peer,
    required this.angleDegrees,
  });

  /// Random ring angle, avoiding the bottom scan FAB and crowding.
  static double pickAngle(
    List<OrbitSatellite> existing, {
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    // Avoid roughly the bottom sector where the scan chip sits (≈ 55°..125°).
    const avoidStart = 55.0;
    const avoidEnd = 125.0;
    const minSeparation = 40.0;

    for (var attempt = 0; attempt < 48; attempt++) {
      final deg = rng.nextDouble() * 360.0 - 180.0;
      if (deg > avoidStart && deg < avoidEnd) continue;
      final clear = existing.every(
        (s) => _angleDelta(s.angleDegrees, deg) >= minSeparation,
      );
      if (clear) return deg;
    }

    for (var attempt = 0; attempt < 24; attempt++) {
      final deg = rng.nextDouble() * 360.0 - 180.0;
      if (deg <= avoidStart || deg >= avoidEnd) return deg;
    }
    return -90.0;
  }

  static double _angleDelta(double a, double b) {
    var d = (a - b).abs() % 360.0;
    if (d > 180.0) d = 360.0 - d;
    return d;
  }
}

/// Circular discovery canvas: file core + peer satellites + scan FAB.
class OrbitCanvas extends StatelessWidget {
  final bool isServerRunning;
  final bool isSending;
  final List<TransferFileItem> selectedItems;
  final List<OrbitSatellite> satellites;
  final PeerRef? selectedPeer;
  final VoidCallback onCoreTap;
  final VoidCallback onScan;
  final ValueChanged<PeerRef> onPeerSelected;

  const OrbitCanvas({
    super.key,
    required this.isServerRunning,
    required this.isSending,
    required this.selectedItems,
    required this.satellites,
    required this.selectedPeer,
    required this.onCoreTap,
    required this.onScan,
    required this.onPeerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasFiles = selectedItems.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        // Use most of the available area so the radar reads as the hero.
        final size = (side * 0.98).clamp(280.0, 560.0);
        final coreSize = (size * 0.40).clamp(148.0, 200.0);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _OrbitRingsPainter()),
                ),
                ..._buildSatellites(size),
                Center(
                  child: _OrbitCore(
                    size: coreSize,
                    enabled: isServerRunning && !isSending,
                    hasFiles: hasFiles,
                    title: hasFiles
                        ? l10n.filesSelected(selectedItems.length)
                        : l10n.selectFiles,
                    subtitle: hasFiles ? '' : l10n.dragDropHint,
                    count: selectedItems.length,
                    onTap: isServerRunning && !isSending ? onCoreTap : null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -4,
                  child: Center(
                    child: _ScanFab(
                      label: l10n.scanDevices,
                      enabled: isServerRunning && !isSending,
                      onPressed: onScan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSatellites(double size) {
    if (satellites.isEmpty) return const [];
    final avatar = (size * 0.12).clamp(48.0, 58.0);
    final chipWidth = avatar + 16;
    final widgets = <Widget>[];
    for (final slot in satellites) {
      final rad = slot.angleDegrees * math.pi / 180;
      final cx = size / 2 + math.cos(rad) * size * 0.42;
      final cy = size / 2 + math.sin(rad) * size * 0.42;
      widgets.add(
        Positioned(
          left: cx - chipWidth / 2,
          top: cy - (avatar / 2 + 22),
          child: _SatelliteChip(
            peer: slot.peer,
            avatarSize: avatar,
            selected: selectedPeer?.isSameRoute(slot.peer) ?? false,
            onTap: () => onPeerSelected(slot.peer),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _OrbitRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = HomeUi.borderSoft.withValues(alpha: 0.9);
    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = HomeUi.primary.withValues(alpha: 0.28);

    canvas.drawCircle(center, size.width * 0.46, outer);

    final r = size.width * 0.32;
    const dash = 7.0;
    const gap = 5.0;
    final circ = 2 * math.pi * r;
    var drawn = 0.0;
    while (drawn < circ) {
      final start = drawn / r;
      final sweep = dash / r;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start - math.pi / 2,
        sweep,
        false,
        dashed,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrbitCore extends StatelessWidget {
  final double size;
  final bool enabled;
  final bool hasFiles;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback? onTap;

  const _OrbitCore({
    required this.size,
    required this.enabled,
    required this.hasFiles,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = (size * 0.20).clamp(26.0, 34.0);
    final titleSize = (size * 0.095).clamp(13.0, 15.5);
    final subSize = (size * 0.075).clamp(11.0, 12.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasFiles ? Colors.white : null,
            gradient: hasFiles
                ? null
                : const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    radius: 1.05,
                    colors: [Colors.white, HomeUi.primarySoft],
                  ),
            border: Border.all(
              color: HomeUi.primary.withValues(alpha: enabled ? 0.45 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeUi.primary.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasFiles
                            ? Icons.folder_open_rounded
                            : Icons.upload_rounded,
                        color: enabled
                            ? HomeUi.primary
                            : HomeUi.inkMuted.withValues(alpha: 0.5),
                        size: iconSize,
                      ),
                      SizedBox(height: size * 0.04),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: enabled ? HomeUi.ink : HomeUi.inkMuted,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            color: HomeUi.inkMuted.withValues(
                              alpha: enabled ? 1 : 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasFiles)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HomeUi.primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SatelliteChip extends StatelessWidget {
  final PeerRef peer;
  final double avatarSize;
  final bool selected;
  final VoidCallback onTap;

  const _SatelliteChip({
    required this.peer,
    required this.avatarSize,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = peer.deviceName?.trim().isNotEmpty == true
        ? peer.deviceName!
        : (peer.lan?.ip ?? peer.deviceId ?? '?');
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final labelWidth = avatarSize + 16;

    return SizedBox(
      width: labelWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? HomeUi.primary : Colors.white,
                  border: Border.all(
                    color: selected ? HomeUi.primary : HomeUi.borderSoft,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? HomeUi.primary.withValues(alpha: 0.28)
                          : HomeUi.ink.withValues(alpha: 0.08),
                      blurRadius: selected ? 12 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: (avatarSize * 0.34).clamp(15.0, 20.0),
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : HomeUi.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeUi.ink,
                ),
              ),
              if (peer.channelLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  peer.channelLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? HomeUi.primary : HomeUi.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ScanFab({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeUi.primarySoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? HomeUi.primaryDeep
                  : HomeUi.inkMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
