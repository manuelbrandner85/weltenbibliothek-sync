import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../models/telegram_playlist_model.dart';
import '../services/auth_service.dart';

/// Telegram Playlist Manager Screen
/// 
/// Features:
/// - Eigene Playlists erstellen und verwalten
/// - Öffentliche Playlists entdecken
/// - Playlists teilen
/// - Kollaborative Playlists
/// - Smart-Playlists mit Auto-Filter
class TelegramPlaylistScreen extends StatefulWidget {
  const TelegramPlaylistScreen({super.key});

  @override
  State<TelegramPlaylistScreen> createState() => _TelegramPlaylistScreenState();
}

class _TelegramPlaylistScreenState extends State<TelegramPlaylistScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: AppTheme.backgroundDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.folder), text: 'Meine Playlists'),
            Tab(icon: Icon(Icons.public), text: 'Öffentlich'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPlaylists(),
          _buildPublicPlaylists(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlaylist,
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.add),
        label: const Text('Neue Playlist'),
      ),
    );
  }

  Widget _buildMyPlaylists() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return const Center(child: Text('Bitte anmelden'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_playlists')
          .where('owner_id', isEqualTo: userId)
          .orderBy('updated_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = snapshot.data!.docs
            .map((doc) => TelegramPlaylist.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Keine Playlists vorhanden',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Erstelle deine erste Playlist!',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            return _buildPlaylistCard(playlists[index], isOwner: true);
          },
        );
      },
    );
  }

  Widget _buildPublicPlaylists() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_playlists')
          .where('is_public', isEqualTo: true)
          .orderBy('view_count', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = snapshot.data!.docs
            .map((doc) => TelegramPlaylist.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public_off, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Keine öffentlichen Playlists',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            return _buildPlaylistCard(playlists[index], isOwner: false);
          },
        );
      },
    );
  }

  Widget _buildPlaylistCard(TelegramPlaylist playlist, {required bool isOwner}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.secondaryGold.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _openPlaylist(playlist),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Cover Image oder Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.secondaryGold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: playlist.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              playlist.coverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.playlist_play,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                playlist.name,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwner)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                color: AppTheme.surfaceDark,
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editPlaylist(playlist);
                                      break;
                                    case 'share':
                                      _sharePlaylist(playlist);
                                      break;
                                    case 'delete':
                                      _deletePlaylist(playlist);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Bearbeiten'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share, size: 20),
                                        SizedBox(width: 8),
                                        Text('Teilen'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Löschen', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'von ${playlist.ownerName}',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (playlist.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  playlist.description,
                  style: AppTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.video_library,
                    '${playlist.messageIds.length}',
                    'Inhalte',
                  ),
                  const SizedBox(width: 8),
                  if (playlist.isPublic) ...[
                    _buildStatChip(
                      Icons.visibility,
                      '${playlist.viewCount}',
                      'Aufrufe',
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (playlist.isPublic)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 12, color: Colors.green[300]),
                          const SizedBox(width: 4),
                          Text(
                            'Öffentlich',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryPurple),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewPlaylist() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Neue Playlist', style: AppTheme.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Playlist-Name',
                    labelStyle: AppTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: AppTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    labelStyle: AppTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Öffentlich'),
                  subtitle: const Text('Andere können diese Playlist sehen'),
                  value: isPublic,
                  activeColor: AppTheme.primaryPurple,
                  onChanged: (value) {
                    setState(() => isPublic = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Name eingeben')),
                  );
                  return;
                }

                final userId = _authService.currentUserId;
                if (userId == null) return;

                try {
                  await FirebaseFirestore.instance
                      .collection('telegram_playlists')
                      .add({
                    'name': name,
                    'description': descController.text.trim(),
                    'owner_id': userId,
                    'owner_name': _authService.currentUserId ?? 'Unbekannt',
                    'message_ids': [],
                    'created_at': FieldValue.serverTimestamp(),
                    'updated_at': FieldValue.serverTimestamp(),
                    'is_public': isPublic,
                    'collaborators': [],
                    'view_count': 0,
                    'share_count': 0,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Playlist erstellt')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaylist(TelegramPlaylist playlist) {
    // TODO: Navigate to playlist detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Öffne Playlist: ${playlist.name}')),
    );
  }

  void _editPlaylist(TelegramPlaylist playlist) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bearbeitungs-Feature wird implementiert')),
    );
  }

  void _sharePlaylist(TelegramPlaylist playlist) {
    // TODO: Share playlist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teilen-Feature wird implementiert')),
    );
  }

  Future<void> _deletePlaylist(TelegramPlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Playlist löschen?'),
        content: Text('Möchtest du "${playlist.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('telegram_playlists')
            .doc(playlist.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Playlist gelöscht')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}
