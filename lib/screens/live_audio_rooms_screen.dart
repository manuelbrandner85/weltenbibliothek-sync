import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/live_audio_service.dart';
import 'live_audio_chat_screen.dart';

/// Live Audio Rooms List Screen
class LiveAudioRoomsScreen extends StatefulWidget {
  const LiveAudioRoomsScreen({super.key});

  @override
  State<LiveAudioRoomsScreen> createState() => _LiveAudioRoomsScreenState();
}

class _LiveAudioRoomsScreenState extends State<LiveAudioRoomsScreen> {
  final LiveAudioService _audioService = LiveAudioService();

  void _createRoom() {
    showDialog(
      context: context,
      builder: (context) => _CreateRoomDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('🎙️ Live Audio Räume', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.secondaryGold, size: 28),
            onPressed: _createRoom,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _audioService.getActiveAudioRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryGold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Fehler beim Laden',
                style: AppTheme.bodyMedium.copyWith(color: Colors.red),
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
                  Text('Keine aktiven Räume', style: AppTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle einen neuen Audio-Raum!',
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Raum erstellen'),
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
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(room);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomId = room['id'] as String;
    final name = room['name'] as String? ?? 'Unbekannter Raum';
    final description = room['description'] as String? ?? '';
    final hostName = room['hostName'] as String? ?? 'Unbekannt';
    final participants = (room['activeParticipants'] as List?)?.length ?? 0;
    final maxParticipants = room['maxParticipants'] as int? ?? 20;
    final speakingUsers = (room['speakingUsers'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.primaryPurple.withValues(alpha: 0.2),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTheme.headlineSmall.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: AppTheme.secondaryGold),
                              const SizedBox(width: 4),
                              Text(
                                hostName,
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryGold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (speakingUsers > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.graphic_eq, size: 14, color: AppTheme.secondaryGold),
                            const SizedBox(width: 4),
                            Text(
                              '$speakingUsers',
                              style: const TextStyle(
                                color: AppTheme.secondaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$participants / $maxParticipants Teilnehmer',
                            style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Beitreten',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
      ),
    );
  }
}

/// Create Room Dialog
class _CreateRoomDialog extends StatefulWidget {
  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
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
        maxParticipants: 20,
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
      title: const Text('Audio-Raum erstellen', style: TextStyle(color: Colors.white)),
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
