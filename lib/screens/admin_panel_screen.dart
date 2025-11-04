import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../config/app_theme.dart';
import '../models/moderator_permissions.dart';
import '../widgets/moderator_permissions_editor.dart';

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
    _tabController = TabController(length: 6, vsync: this); // ✨ NEU: 6 Tabs (+ Wiederherstellung)
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Moderatoren'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'User'),
            Tab(icon: Icon(Icons.restore), text: 'Wiederherstellen'), // ✨ NEU
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
          _buildUserManagementTab(),
          _buildRestoreUsersTab(), // ✨ NEU
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
    final permissionsMap = moderator['permissions'] as Map<String, dynamic>?;
    final permissions = permissionsMap != null 
        ? ModeratorPermissions.fromMap(permissionsMap)
        : ModeratorPermissions.standard();

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
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
            // Permissions Summary
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.secondaryGold, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${permissions.permissionCount} Berechtigungen',
                  style: const TextStyle(
                    color: AppTheme.secondaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onSelected: (value) {
            switch (value) {
              case 'edit_permissions':
                _showEditPermissionsDialog(userId, displayName, permissions);
                break;
              case 'demote':
                _showDemoteModeratorDialog(userId, displayName);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_permissions',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.secondaryGold, size: 20),
                  SizedBox(width: 8),
                  Text('Rechte bearbeiten', style: TextStyle(color: AppTheme.secondaryGold)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'demote',
              child: Row(
                children: [
                  Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Rechte entziehen', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        children: [
          // Permission Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktive Berechtigungen:',
                  style: TextStyle(
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (permissions.permissionsList.isEmpty)
                  const Text(
                    'Keine Berechtigungen erteilt',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ...permissions.permissionsList.map((perm) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(perm, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
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
                final targetDisplayName = usersSnapshot.docs.first.data()['displayName'] as String? ?? 'Unbekannt';
                final currentUserId = _authService.currentUserId!;

                // Zeige Rechte-Auswahl-Dialog
                if (!mounted) return;
                final permissions = await showDialog<ModeratorPermissions>(
                  context: context,
                  builder: (context) => ModeratorPermissionsDialog(
                    userName: targetDisplayName,
                    initialPermissions: ModeratorPermissions.standard(),
                  ),
                );

                if (permissions == null) return; // User hat abgebrochen

                await _adminService.promoteModerator(
                    targetUserId, currentUserId,
                    permissions: permissions);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Moderator erfolgreich ernannt mit Rechten'),
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

  void _showEditPermissionsDialog(String userId, String displayName, ModeratorPermissions currentPermissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppTheme.secondaryGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rechte bearbeiten: $displayName',
                style: const TextStyle(color: AppTheme.secondaryGold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: ModeratorPermissionsEditor(
              initialPermissions: currentPermissions,
              onPermissionsChanged: (newPermissions) async {
                // Optional: Live-Update während der Bearbeitung
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true); // Signal für Update

              // Warten auf finalisierte Permissions
              final newPermissions = await showDialog<ModeratorPermissions>(
                context: context,
                builder: (context) => ModeratorPermissionsDialog(
                  userName: displayName,
                  initialPermissions: currentPermissions,
                ),
              );

              if (newPermissions == null) return;

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.updateModeratorPermissions(
                  userId,
                  currentUserId,
                  newPermissions,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Moderator-Rechte aktualisiert'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
            ),
            child: const Text('Speichern'),
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
  // USER-MANAGEMENT TAB
  // ========================================

  Widget _buildUserManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Fehler: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text('Keine User gefunden',
                style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;
            
            return _buildUserManagementCard(userId, userData);
          },
        );
      },
    );
  }

  Widget _buildUserManagementCard(String userId, Map<String, dynamic> userData) {
    final displayName = userData['displayName'] as String? ?? 'Unbekannt';
    final username = userData['username'] as String? ?? 'unbekannt';
    final email = userData['email'] as String? ?? '';
    final photoURL = userData['photoURL'] as String?;
    final role = userData['role'] as String? ?? 'user';
    final isBlocked = userData['is_blocked'] as bool? ?? false;
    final isMuted = userData['is_muted'] as bool? ?? false;

    // Don't show delete option for super admin
    final isSuperAdmin = role == 'super_admin';

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
            Flexible(
              child: Text(displayName,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            if (role == 'super_admin')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '👑 ADMIN',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            if (role == 'moderator')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🛡️ MOD',
                  style: TextStyle(color: Colors.white, fontSize: 9),
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
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
            if (isBlocked)
              const Text('🚫 Blockiert',
                  style: TextStyle(color: Colors.red, fontSize: 11)),
            if (isMuted)
              const Text('🔇 Stummgeschaltet',
                  style: TextStyle(color: Colors.orange, fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<String>(
                icon: Icon(
                  isSuperAdmin ? Icons.admin_panel_settings : Icons.more_vert,
                  color: isSuperAdmin ? AppTheme.secondaryGold : Colors.white70,
                ),
                color: AppTheme.surfaceDark,
                onSelected: (value) {
                  switch (value) {
                    case 'promote_admin':
                      _showPromoteToAdminDialog(userId, displayName);
                      break;
                    case 'demote_admin':
                      _showDemoteFromAdminDialog(userId, displayName);
                      break;
                    case 'delete':
                      _showDeleteUserDialog(userId, displayName);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // Admin-Rechte vergeben (nur wenn User kein Admin ist)
                  if (role != 'super_admin')
                    const PopupMenuItem(
                      value: 'promote_admin',
                      child: Row(
                        children: [
                          Icon(Icons.shield, color: AppTheme.secondaryGold, size: 20),
                          SizedBox(width: 8),
                          Text('Zum Admin ernennen',
                              style: TextStyle(color: AppTheme.secondaryGold)),
                        ],
                      ),
                    ),
                  
                  // Admin-Rechte entziehen (nur wenn User Admin ist, aber nicht man selbst)
                  if (role == 'super_admin' && userId != _authService.currentUserId)
                    const PopupMenuItem(
                      value: 'demote_admin',
                      child: Row(
                        children: [
                          Icon(Icons.remove_moderator, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Admin-Rechte entziehen',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  
                  // Trennlinie wenn Admin-Optionen vorhanden
                  if (role != 'super_admin' || (role == 'super_admin' && userId != _authService.currentUserId))
                    const PopupMenuDivider(),
                  
                  // User löschen (nicht bei Super-Admin)
                  if (!isSuperAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('User komplett löschen',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showDeleteUserDialog(String userId, String displayName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('User komplett löschen', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ACHTUNG: Diese Aktion löscht "$displayName" VOLLSTÄNDIG aus Firebase!',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gelöscht werden:\n• User-Profil\n• Alle Nachrichten\n• Alle erstellten Räume\n• Alle Teilnahmen',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diese Aktion kann NICHT rückgängig gemacht werden!',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Grund (optional)',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'z.B. Spam, Verstoß gegen Regeln',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              // Reason wird im Log gespeichert, aber nicht hier verarbeitet
              
              reasonController.dispose();
              Navigator.pop(context);

              // ✨ NEU: Progress-Dialog statt ewigem Spinner
              String currentStep = 'Initialisiere Löschung...';
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      backgroundColor: AppTheme.cardDark,
                      title: const Row(
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.secondaryGold,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 16),
                          Text('Lösche User...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStep,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bitte warten...',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );

              try {
                final currentUserId = _authService.currentUserId!;
                
                // ✨ Rufe deleteUserCompletely mit Progress-Callback auf
                await _adminService.deleteUserCompletely(
                  targetUserId: userId,
                  adminUserId: currentUserId,
                  onProgress: (step) {
                    // Update Progress-Dialog
                    if (mounted) {
                      // Workaround: Schließe und öffne Dialog mit neuem Text
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Row(
                            children: [
                              step.contains('✅') 
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const CircularProgressIndicator(
                                    color: AppTheme.secondaryGold,
                                    strokeWidth: 2,
                                  ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text('Lösche User...', 
                                  style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );

                // Warte kurz damit User den Erfolg sieht
                await Future.delayed(const Duration(seconds: 2));

                if (!mounted) return;
                Navigator.pop(context); // Close progress

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ User vollständig gelöscht'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close progress

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ENDGÜLTIG LÖSCHEN',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 👑 ADMIN-RECHTE VERWALTUNG
  // ========================================

  void _showPromoteToAdminDialog(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppTheme.secondaryGold),
            SizedBox(width: 8),
            Text('Zum Admin ernennen?', style: TextStyle(color: AppTheme.secondaryGold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du "$displayName" zum Super-Admin ernennen?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.secondaryGold.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.secondaryGold, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Super-Admin Rechte:',
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Moderatoren ernennen/entfernen\n'
                    '• Andere Admins ernennen\n'
                    '• User blockieren/löschen\n'
                    '• Logs verwalten\n'
                    '• Alle Admin-Funktionen',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.promoteToSuperAdmin(userId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ $displayName wurde zum Admin ernannt'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
            ),
            child: const Text('Zum Admin ernennen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDemoteFromAdminDialog(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.remove_moderator, color: Colors.orange),
            SizedBox(width: 8),
            Text('Admin-Rechte entziehen?', style: TextStyle(color: Colors.orange)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du "$displayName" die Admin-Rechte entziehen?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Was passiert:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• User wird zu normalem User\n'
                    '• Verliert alle Admin-Rechte\n'
                    '• Erhält Benachrichtigung\n'
                    '• Aktion wird geloggt',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.demoteSuperAdmin(userId, currentUserId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Admin-Rechte von $displayName entfernt'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Rechte entziehen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔄 WIEDERHERSTELLUNG TAB (NEU)
  // ========================================

  Widget _buildRestoreUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getDeletedUsers(),
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
                Text('Fehler: ${snapshot.error}', 
                  style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        final deletedUsers = snapshot.data ?? [];

        if (deletedUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Keine gelöschten User',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deletedUsers.length,
          itemBuilder: (context, index) {
            final user = deletedUsers[index];
            final userId = user['user_id'] as String;
            final deletedAt = user['deleted_at'] as Timestamp?;

            return Card(
              color: AppTheme.cardDark,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryPurple,
                  child: Icon(Icons.person_off, color: Colors.white),
                ),
                title: Text(
                  'User ID: ${userId.substring(0, 8)}...',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Gelöscht: ${deletedAt != null ? _formatTimestamp(deletedAt) : 'Unbekannt'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () => _showRestoreUserDialog(userId),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Wiederherstellen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRestoreUserDialog(String userId) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text('User wiederherstellen', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Der User erhält neue Zugangsdaten und eine Benachrichtigung.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Anzeigename',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'z.B. Max Mustermann',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Neue Email',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'user@example.com',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Temporäres Passwort',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Min. 6 Zeichen',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              emailController.dispose();
              passwordController.dispose();
              nameController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final password = passwordController.text;
              final name = nameController.text.trim();

              if (email.isEmpty || password.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte alle Felder ausfüllen'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwort muss mindestens 6 Zeichen lang sein'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              emailController.dispose();
              passwordController.dispose();
              nameController.dispose();
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.secondaryGold),
                ),
              );

              try {
                final currentUserId = _authService.currentUserId!;
                await _adminService.restoreUser(
                  targetUserId: userId,
                  adminUserId: currentUserId,
                  newEmail: email,
                  temporaryPassword: password,
                  displayName: name,
                );

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ User erfolgreich wiederhergestellt'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {}); // Refresh list
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Wiederherstellen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
    final blockedBy = user['blocked_by'] as String?;

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<Map<String, String>>(
        future: _getUserDisplayInfo(userId, blockedBy),
        builder: (context, snapshot) {
          final displayName = snapshot.data?['userName'] ?? 'Lädt...';
          final blockedByName = snapshot.data?['blockedByName'] ?? '';

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.block, color: Colors.white),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🚫 Grund: $reason',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                if (blockedAt != null)
                  Text(
                    'Blockiert: ${_formatDate(blockedAt.toDate())}${blockedByName.isNotEmpty ? ' von $blockedByName' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Entblocken'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showUnblockUserDialog(userId, displayName),
            ),
          );
        },
      ),
    );
  }

  /// ✨ NEU: Lade Benutzernamen + Rolle
  Future<Map<String, String>> _getUserDisplayInfo(String userId, String? actionByUserId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      String userName = 'User ID: ${userId.substring(0, 8)}...';
      if (userDoc.exists) {
        final displayName = userDoc.data()?['displayName'] as String?;
        final role = await _adminService.getUserRole(userId);
        final roleBadge = role == UserRole.superAdmin
            ? '👑 '
            : role == UserRole.moderator
                ? '🛡️ '
                : '';
        userName = '$roleBadge${displayName ?? userName}';
      }

      String actionByName = '';
      if (actionByUserId != null) {
        final actionByDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(actionByUserId)
            .get();
        if (actionByDoc.exists) {
          final displayName = actionByDoc.data()?['displayName'] as String?;
          final role = await _adminService.getUserRole(actionByUserId);
          final roleBadge = role == UserRole.superAdmin ? '👑 ' : '🛡️ ';
          actionByName = '$roleBadge${displayName ?? ''}';
        }
      }

      return {'userName': userName, 'blockedByName': actionByName};
    } catch (e) {
      return {
        'userName': 'User ID: ${userId.substring(0, 8)}...',
        'blockedByName': ''
      };
    }
  }

  void _showUnblockUserDialog(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('User entblocken?', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du "$displayName" entblocken?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Was passiert:',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• User kann sich wieder anmelden\n'
                    '• Block-Eintrag wird entfernt\n'
                    '• User erhält Benachrichtigung\n'
                    '• Aktion wird im Log gespeichert',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
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
    final mutedBy = user['muted_by'] as String?;

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<Map<String, String>>(
        future: _getUserDisplayInfo(userId, mutedBy),
        builder: (context, snapshot) {
          final displayName = snapshot.data?['userName'] ?? 'Lädt...';
          final mutedByName = snapshot.data?['blockedByName'] ?? '';

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.volume_off, color: Colors.white),
            ),
            title: Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔇 Grund: $reason',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dauer: $durationMinutes Min',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (muteEnd != null)
                  Text(
                    'Bis: ${_formatDate(muteEnd.toDate())}${mutedByName.isNotEmpty ? ' von $mutedByName' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('Entstummen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showUnmuteUserDialog(userId, displayName),
            ),
          );
        },
      ),
    );
  }

  void _showUnmuteUserDialog(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.volume_up, color: Colors.green),
            SizedBox(width: 8),
            Text('User entstummen?', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du "$displayName" entstummen?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Was passiert:',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• User kann wieder Nachrichten senden\n'
                    '• Mute-Eintrag wird entfernt\n'
                    '• User erhält Benachrichtigung\n'
                    '• Aktion wird im Log gespeichert',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
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
    final logId = log['logId'] as String?; // ✨ NEU: Log-ID für Löschung
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
      case 'delete_user_completely':
        icon = Icons.person_off;
        color = Colors.red;
        actionText = 'User gelöscht';
        break;
      case 'restore_user':
        icon = Icons.restore;
        color = Colors.green;
        actionText = 'User wiederhergestellt';
        break;
      case 'promote_to_super_admin':
        icon = Icons.shield;
        color = AppTheme.secondaryGold;
        actionText = 'Zum Admin ernannt';
        break;
      case 'demote_from_super_admin':
        icon = Icons.remove_moderator;
        color = Colors.orange;
        actionText = 'Admin-Rechte entfernt';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        actionText = action.replaceAll('_', ' ');
    }

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<String>(
        future: _getModeratorDisplayName(moderatorId),
        builder: (context, snapshot) {
          final moderatorName = snapshot.data ?? 'Lädt...';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(actionText, style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'von $moderatorName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                if (reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Grund: $reason',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(timestamp.toDate()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: logId != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteLogDialog(logId),
                  )
                : null,
          );
        },
      ),
    );
  }

  /// ✨ NEU: Hole Moderator-Namen + Rolle
  Future<String> _getModeratorDisplayName(String moderatorId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(moderatorId)
          .get();

      if (userDoc.exists) {
        final displayName = userDoc.data()?['displayName'] as String?;
        final role = await _adminService.getUserRole(moderatorId);
        final roleBadge = role == UserRole.superAdmin
            ? '👑 '
            : role == UserRole.moderator
                ? '🛡️ '
                : '';
        return '$roleBadge${displayName ?? 'User ID: ${moderatorId.substring(0, 8)}...'}';
      }
      return 'User ID: ${moderatorId.substring(0, 8)}...';
    } catch (e) {
      return 'User ID: ${moderatorId.substring(0, 8)}...';
    }
  }

  /// ✨ NEU: Log löschen (nur Super-Admin)
  void _showDeleteLogDialog(String logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Log löschen?', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du diesen Log-Eintrag löschen?',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Nur Super-Admins können Logs löschen.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Prüfe Super-Admin-Rechte
                final currentUserId = _authService.currentUserId!;
                final isSuperAdmin = await _adminService.isSuperAdmin(currentUserId);

                if (!isSuperAdmin) {
                  throw Exception('Nur Super-Admins können Logs löschen');
                }

                // Lösche Log
                await FirebaseFirestore.instance
                    .collection('moderation_logs')
                    .doc(logId)
                    .delete();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Log gelöscht'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
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
