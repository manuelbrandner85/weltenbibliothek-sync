
// ☁️ FIREBASE CLOUD FUNCTION - Automatische 24h Chat-Löschung
// Platziere diese Datei in: cloud_functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Läuft jeden Tag um 02:00 UTC
exports.deleteOldChatMessages = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const cutoffTime = new Date();
    cutoffTime.setHours(cutoffTime.getHours() - 24);
    
    console.log('🗑️ Lösche Chat-Nachrichten älter als:', cutoffTime);
    
    const messagesRef = db.collection('telegram_messages');
    const oldMessages = await messagesRef
      .where('timestamp', '<', cutoffTime)
      .get();
    
    const batch = db.batch();
    let count = 0;
    
    oldMessages.forEach(doc => {
      batch.delete(doc.ref);
      count++;
    });
    
    await batch.commit();
    console.log(`✅ ${count} alte Nachrichten gelöscht`);
    
    return null;
  });

// Deployment:
// cd cloud_functions
// npm install firebase-functions firebase-admin
// firebase deploy --only functions
