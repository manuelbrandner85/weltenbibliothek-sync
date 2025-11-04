import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/live_audio_service.dart';
import 'chat_room_screen.dart';
import 'create_group_screen.dart';
import 'live_audio_chat_screen.dart';

/// Chat Liste Screen - zeigt alle verfügbaren Chat-Räume + Live Audio
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final LiveAudioService _audioService = LiveAudioService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 Tabs statt 2
    _chatService.initializeDefaultChatRooms();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateGroupScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text(
          'Gruppe erstellen',
          style: TextStyle(color: Colors.white),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Community Chat',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '🌍 Community', icon: Icon(Icons.public)),
            Tab(text: '💬 Meine Chats', icon: Icon(Icons.chat)),
            Tab(text: '🎙️ Live Audio', icon: Icon(Icons.mic)), // NEU
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommunityChatList(),
          _buildMyChatList(),
          _buildLiveAudioList(), // NEU
        ],
      ),
    );
  }

  Widget _buildCommunityChatList() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getCommunityChatRooms(),
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
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden der Chats',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTheme.bodySmall.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Community-Chats verfügbar',
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chats werden automatisch erstellt',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            return _buildChatRoomCard(chatRooms[index]);
          },
        );
      },
    );
  }

  Widget _buildMyChatList() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Noch keine Chats',
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tritt einem Community-Chat bei',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            return _buildChatRoomCard(chatRooms[index]);
          },
        );
      },
    );
  }

  Widget _buildChatRoomCard(ChatRoom chatRoom) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.1),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
              ),
            );
          },
          onLongPress: () => _showDeleteChatRoomDialog(chatRoom),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.secondaryGold,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chatRoom.name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.name,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chatRoom.lastMessage != null)
                            Text(
                              chatRoom.lastMessage!.timeFormatted,
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chatRoom.lastMessage?.text ?? chatRoom.description,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Unread Badge
                if (chatRoom.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chatRoom.unreadCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// NEU: Live Audio Rooms List
  Widget _buildLiveAudioList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _audioService.getActiveAudioRooms(),
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
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Fehler beim Laden', style: AppTheme.bodyMedium),
              ],
            ),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_none, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('Keine aktiven Live-Räume', style: AppTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  'Erstelle einen neuen Live Audio Raum!',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createLiveRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Live-Raum erstellen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length + 1, // +1 for create button
          itemBuilder: (context, index) {
            // Create button at top
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _createLiveRoom,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Neuen Live-Raum erstellen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              );
            }

            return _buildLiveRoomCard(rooms[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildLiveRoomCard(Map<String, dynamic> room) {
    final roomId = room['id'] as String;
    final name = room['name'] as String? ?? 'Unbekannter Raum';
    final description = room['description'] as String? ?? '';
    final hostName = room['hostName'] as String? ?? 'Unbekannt';
    final hostId = room['hostId'] as String?;
    final participants = (room['activeParticipants'] as List?)?.length ?? 0;
    final maxParticipants = room['maxParticipants'] as int? ?? 200;
    final speakingUsers = (room['speakingUsers'] as List?)?.length ?? 0;
    final isHost = hostId == _audioService.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.1),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveAudioChatScreen(
                  roomId: roomId,
                  roomName: name,
                ),
              ),
            );
          },
          onLongPress: isHost ? () => _showDeleteRoomDialog(roomId, name) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'HOST',
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👤 $hostName',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryGold),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$participants / $maxParticipants',
                            style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                          ),
                          if (speakingUsers > 0) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.graphic_eq, size: 14, color: AppTheme.secondaryGold),
                            const SizedBox(width: 4),
                            Text(
                              '$speakingUsers sprechen',
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryGold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Join Button
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createLiveRoom() {
    showDialog(
      context: context,
      builder: (context) => _CreateLiveRoomDialog(),
    );
  }

  void _showDeleteRoomDialog(String roomId, String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Raum löschen', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du den Raum "$roomName" wirklich löschen?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _audioService.endAudioRoom(roomId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Raum gelöscht'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatRoomDialog(ChatRoom chatRoom) {
    // Nur Ersteller können löschen (für benutzerdefinierte Chat-Räume)
    final isCreator = chatRoom.participants.first == _chatService.currentUserId;
    final isDefaultRoom = chatRoom.type == ChatRoomType.community;
    
    // Standard-Community-Räume können nicht gelöscht werden
    if (isDefaultRoom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Standard-Räume können nicht gelöscht werden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!isCreator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Nur der Ersteller kann diesen Raum löschen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Chat-Raum löschen', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du den Chat-Raum "${chatRoom.name}" wirklich löschen?\n\nAlle Nachrichten werden permanent gelöscht.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Delete chat room from Firestore
                await _chatService.deleteChatRoom(chatRoom.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Chat-Raum gelöscht'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Create Live Room Dialog
class _CreateLiveRoomDialog extends StatefulWidget {
  @override
  State<_CreateLiveRoomDialog> createState() => _CreateLiveRoomDialogState();
}

class _CreateLiveRoomDialogState extends State<_CreateLiveRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final LiveAudioService _audioService = LiveAudioService();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final roomId = await _audioService.createAudioRoom(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        maxParticipants: 200, // ERHÖHT auf 200
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveAudioChatScreen(
              roomId: roomId,
              roomName: _nameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text('Live-Raum erstellen', style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Raum Name',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.mic, color: AppTheme.secondaryGold),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Namen eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: AppTheme.secondaryGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Max. 200 Teilnehmer',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryGold),
                    ),
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
          child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Erstellen'),
        ),
      ],
    );
  }
}
