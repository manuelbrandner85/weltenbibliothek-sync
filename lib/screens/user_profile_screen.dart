import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../config/app_theme.dart';
import 'chat_room_screen.dart';
import '../models/chat_models.dart';

/// User Profile Screen - Zeigt Profil eines Users (Phase 1)
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _chatService.getUserData(widget.userId);
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isOwnProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.userId;

  String get _displayName =>
      _userData?['displayName'] ?? widget.userName ?? 'Unbekannter User';

  String get _userEmail => _userData?['email'] ?? '';

  String get _userBio =>
      _userData?['bio'] ?? 'Mitglied der Weltenbibliothek Community';

  String get _avatarUrl => _userData?['photoURL'] ?? widget.userAvatar ?? '';

  int get _messageCount => _userData?['messageCount'] ?? 0;

  int get _joinedDaysAgo {
    final joinDate = _userData?['createdAt'];
    if (joinDate == null) return 0;
    final date = (joinDate as dynamic).toDate();
    return DateTime.now().difference(date).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildStats(),
                      const SizedBox(height: 24),
                      _buildBio(),
                      const SizedBox(height: 24),
                      if (!_isOwnProfile) _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryPurple,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryPurple.withValues(alpha: 0.7),
                AppTheme.secondaryGold.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Mystische Muster im Hintergrund
              Positioned(
                top: 20,
                right: 20,
                child: Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 30,
                child: Icon(
                  Icons.blur_circular,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          _isOwnProfile ? 'Mein Profil' : 'User Profil',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.secondaryGold,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppTheme.primaryPurple,
            backgroundImage:
                _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
            child: _avatarUrl.isEmpty
                ? Text(
                    _displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          _displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_userEmail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.chat_bubble,
            label: 'Nachrichten',
            value: _messageCount.toString(),
          ),
          _buildStatItem(
            icon: Icons.calendar_today,
            label: 'Dabei seit',
            value: '$_joinedDaysAgo Tagen',
          ),
          _buildStatItem(
            icon: Icons.star,
            label: 'Level',
            value: _getUserLevel().toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
          Icon(icon, color: AppTheme.secondaryGold, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Über mich',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _userBio,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Private Chat Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startPrivateChat,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Private Nachricht senden',
                style: TextStyle(
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Weitere Aktionen
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Profil melden
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Melde-Funktion kommt bald!'),
                  ),
                );
              },
              icon: Icon(Icons.flag, color: Colors.grey[400]),
              label: Text(
                'Profil melden',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[800]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startPrivateChat() async {
    try {
      // Zeige Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Erstelle oder finde Private Chat
      final chatRoomId =
          await _chatService.getOrCreatePrivateChat(widget.userId);

      // Schließe Loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigiere zum Chat
      final chatRoom = ChatRoom(
        id: chatRoomId,
        name: _displayName,
        description: 'Private Konversation',
        participants: [FirebaseAuth.instance.currentUser!.uid, widget.userId],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        type: ChatRoomType.private,
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      // Schließe Loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Zeige Fehler
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getUserLevel() {
    // Basierend auf Nachrichten-Anzahl
    if (_messageCount < 10) return 1;
    if (_messageCount < 50) return 2;
    if (_messageCount < 100) return 3;
    if (_messageCount < 250) return 4;
    return 5;
  }
}
