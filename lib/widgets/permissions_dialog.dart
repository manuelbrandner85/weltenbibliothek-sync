import 'package:flutter/material.dart';
import '../models/moderator_permissions.dart';
import '../config/app_theme.dart';

/// Dialog zur Verwaltung von Moderator-Berechtigungen
class PermissionsDialog extends StatefulWidget {
  final ModeratorPermissions initialPermissions;
  final String userName;
  final bool isNewModerator; // true = Ernennung, false = Aktualisierung

  const PermissionsDialog({
    super.key,
    required this.initialPermissions,
    required this.userName,
    this.isNewModerator = false,
  });

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  late ModeratorPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      title: Row(
        children: [
          const Icon(Icons.shield, color: AppTheme.secondaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isNewModerator
                  ? 'Moderator-Rechte vergeben'
                  : 'Rechte bearbeiten',
              style: const TextStyle(color: AppTheme.secondaryGold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info-Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryPurple),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.secondaryGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isNewModerator
                          ? 'Wähle die Berechtigungen für "${ widget.userName}"'
                          : 'Aktualisiere die Berechtigungen für "${widget.userName}"',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schnellauswahl-Presets
            const Text(
              'Schnellauswahl:',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  'Standard',
                  ModeratorPermissions.standard(),
                  Icons.star_outline,
                ),
                _buildPresetChip(
                  'Erweitert',
                  ModeratorPermissions.extended(),
                  Icons.star_half,
                ),
                _buildPresetChip(
                  'Vollständig',
                  ModeratorPermissions.full(),
                  Icons.star,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Individuelle Berechtigungen
            const Text(
              'Individuelle Berechtigungen:',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            _buildPermissionTile(
              icon: Icons.delete,
              title: 'Nachrichten löschen',
              description: 'Kann unangebrachte Nachrichten in Chats löschen',
              value: _permissions.canDeleteMessages,
              onChanged: (value) {
                setState(() {
                  _permissions = _permissions.copyWith(
                    canDeleteMessages: value,
                  );
                });
              },
            ),

            _buildPermissionTile(
              icon: Icons.volume_off,
              title: 'User stummschalten',
              description: 'Kann User temporär stumm schalten',
              value: _permissions.canMuteUsers,
              onChanged: (value) {
                setState(() {
                  _permissions = _permissions.copyWith(
                    canMuteUsers: value,
                  );
                });
              },
            ),

            _buildPermissionTile(
              icon: Icons.block,
              title: 'User blockieren',
              description: 'Kann User permanent blockieren',
              value: _permissions.canBlockUsers,
              onChanged: (value) {
                setState(() {
                  _permissions = _permissions.copyWith(
                    canBlockUsers: value,
                  );
                });
              },
            ),

            _buildPermissionTile(
              icon: Icons.person_remove,
              title: 'User löschen',
              description: 'Kann User-Accounts vollständig löschen',
              value: _permissions.canDeleteUsers,
              onChanged: (value) {
                setState(() {
                  _permissions = _permissions.copyWith(
                    canDeleteUsers: value,
                  );
                });
              },
            ),

            _buildPermissionTile(
              icon: Icons.history,
              title: 'Logs einsehen',
              description: 'Kann Moderations-Logs und Reports einsehen',
              value: _permissions.canViewLogs,
              onChanged: (value) {
                setState(() {
                  _permissions = _permissions.copyWith(
                    canViewLogs: value,
                  );
                });
              },
            ),

            const SizedBox(height: 16),

            // Anzahl der erteilten Berechtigungen
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.secondaryGold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_permissions.permissionCount} von 5 Berechtigungen erteilt',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen',
              style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryGold,
            foregroundColor: AppTheme.backgroundDark,
          ),
          icon: const Icon(Icons.check),
          label: Text(widget.isNewModerator ? 'Ernennen' : 'Speichern'),
          onPressed: () {
            // Mindestens eine Berechtigung muss erteilt sein
            if (!_permissions.hasAnyPermission) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mindestens eine Berechtigung muss erteilt werden'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, _permissions);
          },
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    String label,
    ModeratorPermissions preset,
    IconData icon,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryGold),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: false,
      backgroundColor: AppTheme.backgroundDark,
      selectedColor: AppTheme.primaryPurple,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      onSelected: (selected) {
        setState(() {
          _permissions = preset;
        });
      },
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryPurple.withValues(alpha: 0.2)
            : AppTheme.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? AppTheme.primaryPurple : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        secondary: Icon(
          icon,
          color: value ? AppTheme.secondaryGold : Colors.white.withValues(alpha: 0.5),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: value ? Colors.white : Colors.white70,
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        activeColor: AppTheme.secondaryGold,
        checkColor: AppTheme.backgroundDark,
      ),
    );
  }
}
