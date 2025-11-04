import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

/// Message Action Sheet - Zeigt Aktionen für Nachrichten (Phase 5)
/// 
/// Version 2.6.0: Moderator-Funktionen hinzugefügt
class MessageActionSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final bool isModerator;
  final bool isSuperAdmin;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onForward;
  final VoidCallback onReport;
  final VoidCallback onDelete;
  final VoidCallback? onMuteUser;
  final VoidCallback? onBlockUser;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.isModerator = false,
    this.isSuperAdmin = false,
    required this.onReply,
    required this.onEdit,
    required this.onPin,
    required this.onForward,
    required this.onReport,
    required this.onDelete,
    this.onMuteUser,
    this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.backgroundDark,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.secondaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nachricht Aktionen',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // Actions
            _buildActionTile(
              icon: Icons.reply,
              title: 'Antworten',
              subtitle: 'Auf diese Nachricht antworten',
              color: AppTheme.primaryPurple,
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),

            if (isOwnMessage) ...[
              _buildActionTile(
                icon: Icons.edit,
                title: 'Bearbeiten',
                subtitle: 'Nachricht ändern',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
            ],

            _buildActionTile(
              icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              title: message.isPinned ? 'Entpinnen' : 'Anpinnen',
              subtitle: message.isPinned 
                  ? 'Nachricht von oben entfernen' 
                  : 'Oben im Chat anzeigen',
              color: AppTheme.secondaryGold,
              onTap: () {
                Navigator.pop(context);
                onPin();
              },
            ),

            _buildActionTile(
              icon: Icons.forward,
              title: 'Weiterleiten',
              subtitle: 'In anderen Chat senden',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                onForward();
              },
            ),

            if (!isOwnMessage) ...[
              _buildActionTile(
                icon: Icons.flag_outlined,
                title: 'Melden',
                subtitle: 'Unangemessenen Inhalt melden',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),
            ],

            // MODERATOR/ADMIN ACTIONS
            if (isModerator && !isOwnMessage) ...[
              const Divider(color: Colors.white24, height: 1),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isSuperAdmin ? Icons.admin_panel_settings : Icons.shield,
                      color: isSuperAdmin ? AppTheme.secondaryGold : AppTheme.accentBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSuperAdmin ? '👑 ADMIN-AKTIONEN' : '🛡️ MODERATOR-AKTIONEN',
                      style: TextStyle(
                        color: isSuperAdmin ? AppTheme.secondaryGold : AppTheme.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (onMuteUser != null)
                _buildActionTile(
                  icon: Icons.volume_off,
                  title: 'User Stummschalten',
                  subtitle: 'User für 60 Minuten stummschalten',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    onMuteUser!();
                  },
                ),
              
              if (isSuperAdmin && onBlockUser != null)
                _buildActionTile(
                  icon: Icons.block,
                  title: 'User Blockieren',
                  subtitle: 'User dauerhaft blockieren',
                  color: Colors.red.shade900,
                  onTap: () {
                    Navigator.pop(context);
                    onBlockUser!();
                  },
                ),
            ],
            
            if (isOwnMessage || isModerator) ...[
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'Löschen',
                subtitle: isModerator && !isOwnMessage 
                    ? 'Als Moderator löschen' 
                    : 'Nachricht entfernen',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],

            const SizedBox(height: 8),

            // Cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Abbrechen',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textWhite.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textWhite.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }

  /// Zeige Action Sheet
  static Future<void> show({
    required BuildContext context,
    required ChatMessage message,
    required bool isOwnMessage,
    bool isModerator = false,
    bool isSuperAdmin = false,
    required Function() onReply,
    required Function() onEdit,
    required Function() onPin,
    required Function() onForward,
    required Function() onReport,
    required Function() onDelete,
    Function()? onMuteUser,
    Function()? onBlockUser,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MessageActionSheet(
        message: message,
        isOwnMessage: isOwnMessage,
        isModerator: isModerator,
        isSuperAdmin: isSuperAdmin,
        onReply: onReply,
        onEdit: onEdit,
        onPin: onPin,
        onForward: onForward,
        onReport: onReport,
        onDelete: onDelete,
        onMuteUser: onMuteUser,
        onBlockUser: onBlockUser,
      ),
    );
  }
}
