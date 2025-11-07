import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PinnedMessagesBar - Top-Bar für gepinnte Nachrichten
class PinnedMessagesBar extends StatelessWidget {
  final VoidCallback? onTap;
  
  const PinnedMessagesBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_messages')
          .where('is_pinned', isEqualTo: true)
          .orderBy('pinned_at', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final pinnedMessage = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final text = pinnedMessage['text_clean'] ?? '';
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.push_pin, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
          ),
        );
      },
    );
  }
}
