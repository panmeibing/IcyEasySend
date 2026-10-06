import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

const Color _accent = Color(0xFF2196F3);

/// Icon badge and title at the top of a settings card.
class SettingsCardHeader extends StatelessWidget {
  const SettingsCardHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Name and one-line explanation of a single setting.
class SettingTitle extends StatelessWidget {
  const SettingTitle({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// Tinted note under a setting; [warning] when the current value is risky.
class SettingHint extends StatelessWidget {
  const SettingHint(this.text, {super.key, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (warning ? const Color(0xFFFFA726) : _accent).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 16,
            color: warning ? const Color(0xFFF57C00) : const Color(0xFF1976D2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: warning ? const Color(0xFFE65100) : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A setting that is simply on or off.
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingTitle(title: title, description: description),
        ),
        Switch(value: value, onChanged: onChanged, activeTrackColor: _accent),
      ],
    );
  }
}

/// Edit, or save and cancel while editing.
///
/// [extra] sits after the edit button when not editing.
class SettingEditActions extends StatelessWidget {
  const SettingEditActions({
    super.key,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.editTooltip,
    this.extra = const [],
  });

  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? editTooltip;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isEditing
          ? [
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                onPressed: onSave,
                tooltip: l10n.save,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                onPressed: onCancel,
                tooltip: l10n.cancel,
              ),
            ]
          : [
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                onPressed: onEdit,
                tooltip: editTooltip ?? l10n.edit,
              ),
              ...extra,
            ],
    );
  }
}

/// A setting shown as a value until the user chooses to edit it.
class EditableSetting extends StatelessWidget {
  const EditableSetting({
    super.key,
    required this.title,
    required this.description,
    required this.isEditing,
    required this.editor,
    required this.display,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final String description;
  final bool isEditing;
  final Widget editor;
  final Widget display;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingTitle(title: title, description: description),
              const SizedBox(height: 12),
              isEditing ? editor : display,
            ],
          ),
        ),
        const SizedBox(width: 8),
        SettingEditActions(
          isEditing: isEditing,
          onEdit: onEdit,
          onSave: onSave,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

/// The current value of an [EditableSetting]; greyed out when [active] is
/// false, e.g. nothing has been set.
class SettingValueChip extends StatelessWidget {
  const SettingValueChip({
    super.key,
    required this.icon,
    required this.label,
    this.active = true,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _accent : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined field used by the editors in settings cards.
InputDecoration settingInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
