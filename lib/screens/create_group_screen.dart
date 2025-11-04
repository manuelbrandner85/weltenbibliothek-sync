import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';
import '../models/chat_models.dart';

/// Create Group Screen - Erstelle neue Gruppen (Phase 2)
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _selectedMemberIds = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Gruppennamen ein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final chatRoomId = await _chatService.createGroupChat(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        memberIds: _selectedMemberIds,
      );

      if (mounted) {
        // Navigiere zum neuen Gruppen-Chat
        final chatRoom = ChatRoom(
          id: chatRoomId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          participants: [_chatService.currentUserId!, ..._selectedMemberIds],
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
          type: ChatRoomType.group,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chatRoom: chatRoom),
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
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Neue Gruppe erstellen',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupIcon(),
              const SizedBox(height: 32),
              _buildGroupNameField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 32),
              _buildMembersSection(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupIcon() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple,
              AppTheme.secondaryGold,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.group_add,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGroupNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Gruppenname',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'z.B. Mysterie-Forscher',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryPurple,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Beschreibung (optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Worum geht es in dieser Gruppe?',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryPurple,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Mitglieder hinzufügen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedMemberIds.length} ausgewählt',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Mitglieder-Auswahl kommt in der nächsten Version',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tipp: Erstelle die Gruppe jetzt und lade Freunde später über den Chat ein!',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createGroup,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check, color: Colors.white),
        label: Text(
          _isCreating ? 'Erstelle Gruppe...' : 'Gruppe erstellen',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey[800],
        ),
      ),
    );
  }
}
