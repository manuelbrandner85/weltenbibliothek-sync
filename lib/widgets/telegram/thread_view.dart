import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/telegram_service.dart';
import 'message_card_v4.dart';

/// ThreadView - Thread/Reply-Ansicht für Konversationen
/// 
/// FEATURES:
/// - Hierarchische Anzeige von Antworten
/// - Original-Nachricht hervorgehoben
/// - Thread-Timeline mit Linien
/// - Schnellantwort-Funktion
/// - Thread-Statistiken
class ThreadView extends StatelessWidget {
  final String threadId;
  final String currentUserId;
  
  const ThreadView({
    super.key,
    required this.threadId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread-Ansicht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger rebuild
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('telegram_messages')
            .where('thread_id', isEqualTo: threadId)
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }
          
          final messages = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['doc_id'] = doc.id;
            return data;
          }).toList();
          
          // Find root message (no reply_to)
          final rootMessage = messages.firstWhere(
            (m) => m['reply_to'] == null,
            orElse: () => messages.first,
          );
          
          final replies = messages.where((m) => m['reply_to'] != null).toList();
          
          return Column(
            children: [
              // Thread Statistics
              _buildThreadStats(messages.length, replies.length),
              
              const Divider(height: 1),
              
              // Messages List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Root Message
                    _buildRootMessage(context, rootMessage),
                    
                    const SizedBox(height: 16),
                    
                    // Replies Header
                    if (replies.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.reply_all, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '${replies.length} Antworten',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Replies
                      ...replies.map((reply) => _buildReplyMessage(context, reply)),
                    ],
                  ],
                ),
              ),
              
              // Quick Reply Input
              _buildQuickReply(context, rootMessage),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThreadStats(int totalMessages, int repliesCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.message, '$totalMessages', 'Nachrichten'),
          _buildStatItem(Icons.reply, '$repliesCount', 'Antworten'),
          _buildStatItem(Icons.person, '${repliesCount + 1}', 'Teilnehmer'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRootMessage(BuildContext context, Map<String, dynamic> message) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.chat_bubble, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Text(
                  'Original-Nachricht',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          MessageCardV4(
            message: message,
            currentUserId: currentUserId,
            showActions: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyMessage(BuildContext context, Map<String, dynamic> message) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thread Line
          Container(
            width: 2,
            height: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(width: 8),
          
          // Reply Arrow
          Icon(Icons.subdirectory_arrow_right, color: Colors.grey[400]),
          const SizedBox(width: 8),
          
          // Message Card
          Expanded(
            child: MessageCardV4(
              message: message,
              currentUserId: currentUserId,
              showActions: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReply(BuildContext context, Map<String, dynamic> rootMessage) {
    final controller = TextEditingController();
    final telegramService = Provider.of<TelegramService>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Schnellantwort...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) async {
                  if (text.trim().isNotEmpty) {
                    await _sendReply(
                      context,
                      telegramService,
                      rootMessage,
                      text.trim(),
                    );
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _sendReply(
                    context,
                    telegramService,
                    rootMessage,
                    controller.text.trim(),
                  );
                  controller.clear();
                }
              },
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply(
    BuildContext context,
    TelegramService service,
    Map<String, dynamic> rootMessage,
    String text,
  ) async {
    final success = await service.sendMessage(
      rootMessage['telegram_chat_id'],
      text,
      replyTo: rootMessage['telegram_message_id'],
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ Antwort gesendet'
              : '❌ Fehler beim Senden',
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Kein Thread gefunden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dieser Thread wurde möglicherweise gelöscht',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
