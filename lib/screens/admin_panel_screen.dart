import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../config/app_theme.dart';

/// Admin-Panel für Super-Admin
/// 
/// Funktionen:
/// - Moderatoren ernennen/entfernen
/// - Blockierte User anzeigen
/// - Stummgeschaltete User anzeigen
/// - Moderation-Logs anzeigen
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.secondaryGold),
            SizedBox(width: 8),
            Text('👑 Admin-Panel'),
          ],
        ),
        backgroundColor: AppTheme.primaryPurple,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Moderatoren'),
            Tab(icon: Icon(Icons.block), text: 'Blockiert'),
            Tab(icon: Icon(Icons.volume_off), text: 'Stumm'),
            Tab(icon: Icon(Icons.history), text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModeratorsTab(),
          _buildBlockedUsersTab(),
          _buildMutedUsersTab(),
          _buildModerationLogsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModeratorDialog,
        backgroundColor: AppTheme.secondaryGold,
        icon: const Icon(Icons.person_add),
        label: const Text('Moderator ernennen'),
      ),
    );
  }

  // ========================================
  // MODERATOREN TAB
  // ========================================

  Widget _buildModeratorsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getAllModerators(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Fehler: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        final moderators = snapshot.data ?? [];

        if (moderators.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Keine Moderatoren ernannt',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tippe auf + um einen Moderator zu ernennen',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: moderators.length,
            itemBuilder: (context, index) {
              final moderator = moderators[index];
              return _buildModeratorCard(moderator);
            },
          ),
        );
      },
    );
  }

  Widget _buildModeratorCard(Map<String, dynamic> moderator) {
    final userId = moderator['userId'] as String;
    final displayName = moderator['displayName'] as String? ?? 'Unbekannt';
    final username = moderator['username'] as String? ?? 'unbekannt';
    final email = moderator['email'] as String? ?? '';
    final photoURL = moderator['photoURL'] as String?;
    final promotedAt = moderator['promoted_at'] as Timestamp?;

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple,
          backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
          child: photoURL == null
              ? Text(displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Row(
          children: [
            Text(displayName, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🛡️ MODERATOR',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@$username', style: const TextStyle(color: Colors.white70)),
            if (email.isNotEmpty)
              Text(email,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12)),
            if (promotedAt != null)
              Text(
                'Ernannt: ${_formatDate(promotedAt.toDate())}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _showDemoteModeratorDialog(userId, displayName),
        ),
      ),
    );
  }

  void _showAddModeratorDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Moderator ernennen',
            style: TextStyle(color: AppTheme.secondaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gib die Email-Adresse des Users ein, den du zum Moderator ernennen möchtest.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email-Adresse',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon:
                    const Icon(Icons.email, color: AppTheme.secondaryGold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.secondaryGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Bitte Email eingeben'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(context);

              try {
                // Finde User via Email
                final usersSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (usersSnapshot.docs.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User nicht gefunden'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                final targetUserId = usersSnapshot.docs.first.id;
                final currentUserId = _authService.currentUserId!;

                await _adminService.promoteModerator(
                    targetUserId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Moderator erfolgreich ernannt'),
                      backgroundColor: Colors.green),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Ernennen',
                style: TextStyle(color: AppTheme.backgroundDark)),
          ),
        ],
      ),
    );
  }

  void _showDemoteModeratorDialog(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Moderator-Rechte entziehen?',
            style: TextStyle(color: Colors.red)),
        content: Text(
          'Möchtest du die Moderator-Rechte von "$displayName" wirklich entziehen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.demoteModerator(userId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Moderator-Rechte entzogen'),
                      backgroundColor: Colors.green),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child:
                const Text('Entziehen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BLOCKIERTE USER TAB
  // ========================================

  Widget _buildBlockedUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getBlockedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        final blockedUsers = snapshot.data ?? [];

        if (blockedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block,
                    size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Keine blockierten User',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: blockedUsers.length,
          itemBuilder: (context, index) {
            final user = blockedUsers[index];
            return _buildBlockedUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildBlockedUserCard(Map<String, dynamic> user) {
    final userId = user['userId'] as String;
    final reason = user['reason'] as String? ?? 'Kein Grund angegeben';
    final blockedAt = user['blocked_at'] as Timestamp?;

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.block, color: Colors.white),
        ),
        title: Text('User: $userId',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grund: $reason',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (blockedAt != null)
              Text(
                'Blockiert: ${_formatDate(blockedAt.toDate())}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _showUnblockUserDialog(userId),
        ),
      ),
    );
  }

  void _showUnblockUserDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('User entblocken?',
            style: TextStyle(color: Colors.green)),
        content: Text(
          'Möchtest du den User "$userId" wirklich entblocken?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.unblockUser(userId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ User entblockt'),
                      backgroundColor: Colors.green),
                );

                setState(() {});
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Entblocken',
                style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // STUMMGESCHALTETE USER TAB
  // ========================================

  Widget _buildMutedUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getMutedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        final mutedUsers = snapshot.data ?? [];

        if (mutedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_off,
                    size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Keine stummgeschalteten User',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mutedUsers.length,
          itemBuilder: (context, index) {
            final user = mutedUsers[index];
            return _buildMutedUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildMutedUserCard(Map<String, dynamic> user) {
    final userId = user['userId'] as String;
    final reason = user['reason'] as String? ?? 'Kein Grund angegeben';
    final muteEnd = user['mute_end'] as Timestamp?;
    final durationMinutes = user['duration_minutes'] as int? ?? 0;

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.volume_off, color: Colors.white),
        ),
        title: Text('User: $userId',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grund: $reason',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Dauer: $durationMinutes Minuten',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (muteEnd != null)
              Text(
                'Bis: ${_formatDate(muteEnd.toDate())}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up, color: Colors.green),
          onPressed: () => _showUnmuteUserDialog(userId),
        ),
      ),
    );
  }

  void _showUnmuteUserDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('User entstummen?',
            style: TextStyle(color: Colors.green)),
        content: Text(
          'Möchtest du den User "$userId" wirklich entstummen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.unmuteUser(userId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ User entstummt'),
                      backgroundColor: Colors.green),
                );

                setState(() {});
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Entstummen',
                style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // MODERATION LOGS TAB
  // ========================================

  Widget _buildModerationLogsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getModerationLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,
                    size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Keine Moderation-Logs',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogCard(log);
          },
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? 'unknown';
    final moderatorId = log['moderator_id'] as String? ??
        log['admin_id'] as String? ??
        'unknown';
    final reason = log['reason'] as String?;
    final timestamp = log['timestamp'] as Timestamp?;

    IconData icon;
    Color color;
    String actionText;

    switch (action) {
      case 'delete_message':
        icon = Icons.delete;
        color = Colors.red;
        actionText = 'Nachricht gelöscht';
        break;
      case 'edit_message':
        icon = Icons.edit;
        color = Colors.blue;
        actionText = 'Nachricht bearbeitet';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        actionText = action;
    }

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(actionText, style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moderator: $moderatorId',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12)),
            if (reason != null)
              Text('Grund: $reason',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (timestamp != null)
              Text(
                _formatDate(timestamp.toDate()),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min.';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std.';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? 'en' : ''}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
