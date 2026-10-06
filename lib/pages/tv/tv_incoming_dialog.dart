import 'package:flutter/material.dart';

import '../home/home_ui.dart';
import 'tv_widgets.dart';

class TvIncomingFile {
  final String name;
  final String sizeLabel;
  final double progress;
  final String status;
  final bool showProgress;
  final bool completed;
  final bool failed;

  const TvIncomingFile({
    required this.name,
    required this.sizeLabel,
    required this.progress,
    required this.status,
    required this.showProgress,
    required this.completed,
    required this.failed,
  });
}

/// Horizontal receive confirmation. Actions stay on the right while the file
/// list scrolls. The accept button takes the initial focus.
class TvIncomingDialog extends StatelessWidget {
  final String title;
  final String senderLine;
  final String totalLine;
  final String? speedLine;
  final String? etaLine;
  final String? countdown;
  final String? statusLine;
  final List<TvIncomingFile> files;
  final bool showActions;
  final String acceptLabel;
  final String rejectLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TvIncomingDialog({
    super.key,
    required this.title,
    required this.senderLine,
    required this.totalLine,
    required this.files,
    required this.showActions,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
    this.speedLine,
    this.etaLine,
    this.countdown,
    this.statusLine,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: HomeUi.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      senderLine,
                      style: const TextStyle(fontSize: 18, color: HomeUi.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalLine,
                      style: const TextStyle(
                        fontSize: 16,
                        color: HomeUi.inkMuted,
                      ),
                    ),
                    if (speedLine != null) ...[
                      const SizedBox(height: 4),
                      Text(speedLine!, style: const TextStyle(fontSize: 16)),
                    ],
                    if (etaLine != null) ...[
                      const SizedBox(height: 2),
                      Text(etaLine!, style: const TextStyle(fontSize: 16)),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: ExcludeFocus(
                        child: ListView.separated(
                          itemCount: files.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  file.sizeLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: HomeUi.inkMuted,
                                  ),
                                ),
                                if (file.showProgress) ...[
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(value: file.progress),
                                  const SizedBox(height: 2),
                                  Text(
                                    file.status,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: file.failed
                                          ? HomeUi.stoppedAccent
                                          : file.completed
                                          ? HomeUi.runningAccent
                                          : HomeUi.primary,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    if (countdown != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        countdown!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: HomeUi.inkMuted,
                        ),
                      ),
                    ],
                    if (statusLine != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        statusLine!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: 28),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TvButton(
                      label: acceptLabel,
                      primary: true,
                      autofocus: true,
                      onPressed: onAccept,
                    ),
                    const SizedBox(height: 12),
                    TvButton(label: rejectLabel, onPressed: onReject),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
