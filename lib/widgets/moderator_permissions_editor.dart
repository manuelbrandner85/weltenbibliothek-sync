import 'package:flutter/material.dart';
import '../models/moderator_permissions.dart';
import '../config/app_theme.dart';

/// Widget zur Bearbeitung von Moderator-Berechtigungen
class ModeratorPermissionsEditor extends StatefulWidget {
  final ModeratorPermissions initialPermissions;
  final Function(ModeratorPermissions) onPermissionsChanged;
  final bool enabled;

  const ModeratorPermissionsEditor({
    super.key,
    required this.initialPermissions,
    required this.onPermissionsChanged,
    this.enabled = true,
  });

  @override
  State<ModeratorPermissionsEditor> createState() =>
      _ModeratorPermissionsEditorState();
}

class _ModeratorPermissionsEditorState
    extends State<ModeratorPermissionsEditor> {
  late ModeratorPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
  }

  void _updatePermission(ModeratorPermissions newPermissions) {
    setState(() {
      _permissions = newPermissions;
    });
    widget.onPermissionsChanged(_permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset-Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton(
              'Standard',
              ModeratorPermissions.standard(),
              Icons.person,
              Colors.blue,
            ),
            _buildPresetButton(
              'Erweitert',
              ModeratorPermissions.extended(),
              Icons.verified_user,
              Colors.orange,
            ),
            _buildPresetButton(
              'Vollständig',
              ModeratorPermissions.full(),
              Icons.admin_panel_settings,
              Colors.green,
            ),
            _buildPresetButton(
              'Keine',
              ModeratorPermissions.none(),
              Icons.block,
              Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.primaryPurple),
        const SizedBox(height: 16),

        // Individual Permissions
        const Text(
          'Individuelle Berechtigungen',
          style: TextStyle(
            color: AppTheme.secondaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildPermissionTile(
          icon: Icons.delete,
          title: 'Nachrichten löschen',
          description:
              'Moderator kann unangemessene Nachrichten aus Chats entfernen',
          value: _permissions.canDeleteMessages,
          onChanged: (value) {
            _updatePermission(
              _permissions.copyWith(canDeleteMessages: value),
            );
          },
        ),

        _buildPermissionTile(
          icon: Icons.volume_off,
          title: 'User muten',
          description:
              'Moderator kann User für bestimmte Zeit stumm schalten',
          value: _permissions.canMuteUsers,
          onChanged: (value) {
            _updatePermission(
              _permissions.copyWith(canMuteUsers: value),
            );
          },
        ),

        _buildPermissionTile(
          icon: Icons.block,
          title: 'User blockieren',
          description:
              'Moderator kann User dauerhaft vom System blockieren',
          value: _permissions.canBlockUsers,
          onChanged: (value) {
            _updatePermission(
              _permissions.copyWith(canBlockUsers: value),
            );
          },
        ),

        _buildPermissionTile(
          icon: Icons.person_off,
          title: 'User löschen',
          description:
              'Moderator kann User-Accounts komplett aus dem System entfernen',
          value: _permissions.canDeleteUsers,
          onChanged: (value) {
            _updatePermission(
              _permissions.copyWith(canDeleteUsers: value),
            );
          },
        ),

        _buildPermissionTile(
          icon: Icons.history,
          title: 'Logs einsehen',
          description:
              'Moderator kann Moderations-Logs und Aktivitäten einsehen',
          value: _permissions.canViewLogs,
          onChanged: (value) {
            _updatePermission(
              _permissions.copyWith(canViewLogs: value),
            );
          },
        ),

        // Permission Count Summary
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryPurple),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: AppTheme.secondaryGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_permissions.permissionCount} von 5 Berechtigungen erteilt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    String label,
    ModeratorPermissions preset,
    IconData icon,
    Color color,
  ) {
    final isSelected = _permissions.toMap().toString() == preset.toMap().toString();

    return ElevatedButton.icon(
      onPressed: widget.enabled
          ? () {
              _updatePermission(preset);
            }
          : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : AppTheme.cardDark,
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        side: BorderSide(
          color: isSelected ? color : AppTheme.primaryPurple,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: widget.enabled ? onChanged : null,
        title: Row(
          children: [
            Icon(icon, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 28, top: 4),
          child: Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        activeColor: AppTheme.secondaryGold,
        activeTrackColor: AppTheme.secondaryGold.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Dialog zur Rechtevergabe bei Moderator-Ernennung
class ModeratorPermissionsDialog extends StatefulWidget {
  final String userName;
  final ModeratorPermissions? initialPermissions;

  const ModeratorPermissionsDialog({
    super.key,
    required this.userName,
    this.initialPermissions,
  });

  @override
  State<ModeratorPermissionsDialog> createState() =>
      _ModeratorPermissionsDialogState();
}

class _ModeratorPermissionsDialogState
    extends State<ModeratorPermissionsDialog> {
  late ModeratorPermissions _selectedPermissions;

  @override
  void initState() {
    super.initState();
    _selectedPermissions =
        widget.initialPermissions ?? ModeratorPermissions.standard();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundDark,
      title: Row(
        children: [
          const Icon(Icons.shield, color: AppTheme.secondaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Moderator-Rechte für ${widget.userName}',
              style: const TextStyle(color: AppTheme.secondaryGold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentBlue),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.accentBlue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wähle die Berechtigungen, die dieser Moderator erhalten soll.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModeratorPermissionsEditor(
                initialPermissions: _selectedPermissions,
                onPermissionsChanged: (permissions) {
                  setState(() {
                    _selectedPermissions = permissions;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedPermissions);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryGold,
          ),
          child: const Text('Bestätigen'),
        ),
      ],
    );
  }
}
