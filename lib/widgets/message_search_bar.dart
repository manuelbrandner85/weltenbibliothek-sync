import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

/// Message Search Bar - Durchsuche Nachrichten (Phase 5A)
class MessageSearchBar extends StatefulWidget {
  final String chatRoomId;
  final Function(ChatMessage) onMessageSelected;

  const MessageSearchBar({
    super.key,
    required this.chatRoomId,
    required this.onMessageSelected,
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  
  List<ChatMessage> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _chatService.searchMessages(
        chatRoomId: widget.chatRoomId,
        query: query,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suchfehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Nachrichten durchsuchen...',
                hintStyle: TextStyle(
                  color: AppTheme.textWhite.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.secondaryGold,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                // Debounced search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
            ),
          ),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppTheme.secondaryGold,
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final message = _searchResults[index];
                  return _buildSearchResultTile(message);
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Keine Nachrichten gefunden',
                style: TextStyle(
                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(ChatMessage message) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
        child: Text(
          message.senderName[0].toUpperCase(),
          style: const TextStyle(
            color: AppTheme.secondaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        message.senderName,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        message.text,
        style: TextStyle(
          color: AppTheme.textWhite.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        message.timeFormatted,
        style: TextStyle(
          color: AppTheme.textWhite.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
      onTap: () {
        widget.onMessageSelected(message);
      },
    );
  }
}
