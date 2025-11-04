/**
 * Cloud Functions für Weltenbibliothek
 * Push Notifications bei neuen Chat-Nachrichten
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send notification when new message is created
 */
exports.sendChatNotification = functions.firestore
  .document('chat_rooms/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const chatRoomId = context.params.chatRoomId;
    const messageId = context.params.messageId;
    
    try {
      // Get chat room data
      const chatRoomDoc = await admin.firestore()
        .collection('chat_rooms')
        .doc(chatRoomId)
        .get();
      
      if (!chatRoomDoc.exists) {
        console.log('Chat room not found');
        return null;
      }
      
      const chatRoom = chatRoomDoc.data();
      const participants = chatRoom.participants || [];
      
      // Don't send notification to message sender
      const recipientIds = participants.filter(id => id !== message.senderId);
      
      if (recipientIds.length === 0) {
        console.log('No recipients for notification');
        return null;
      }
      
      // Get FCM tokens for all recipients
      const tokens = [];
      for (const userId of recipientIds) {
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();
        
        if (userDoc.exists && userDoc.data().fcmToken) {
          tokens.push(userDoc.data().fcmToken);
        }
      }
      
      if (tokens.length === 0) {
        console.log('No FCM tokens found');
        return null;
      }
      
      // Prepare notification
      const notification = {
        title: chatRoom.name || 'Neue Nachricht',
        body: message.type === 'image' 
          ? `${message.senderName} hat ein Bild gesendet 📸`
          : message.text || 'Neue Nachricht',
      };
      
      const data = {
        chatRoomId: chatRoomId,
        messageId: messageId,
        senderId: message.senderId,
        type: 'chat_message',
      };
      
      // Send notification to all tokens
      const payload = {
        notification: notification,
        data: data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'weltenbibliothek_chat',
            sound: 'default',
            priority: 'high',
          },
        },
      };
      
      const response = await admin.messaging().sendToDevice(tokens, payload);
      
      console.log(`Notification sent to ${tokens.length} devices`);
      console.log('Response:', response);
      
      return response;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Clean up old messages (optional)
 * Runs daily to delete messages older than 30 days
 */
exports.cleanupOldMessages = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    try {
      const chatRoomsSnapshot = await admin.firestore()
        .collection('chat_rooms')
        .get();
      
      let deletedCount = 0;
      
      for (const chatRoomDoc of chatRoomsSnapshot.docs) {
        const messagesSnapshot = await chatRoomDoc.ref
          .collection('messages')
          .where('timestamp', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
          .get();
        
        const batch = admin.firestore().batch();
        messagesSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        deletedCount += messagesSnapshot.size;
      }
      
      console.log(`Deleted ${deletedCount} old messages`);
      return null;
      
    } catch (error) {
      console.error('Error cleaning up messages:', error);
      return null;
    }
  });

/**
 * Update user online status on presence change
 */
exports.updateUserPresence = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // Check if isOnline status changed
    if (beforeData.isOnline !== afterData.isOnline) {
      console.log(`User ${context.params.userId} is now ${afterData.isOnline ? 'online' : 'offline'}`);
      
      // You can add additional logic here, e.g., notify friends
    }
    
    return null;
  });
