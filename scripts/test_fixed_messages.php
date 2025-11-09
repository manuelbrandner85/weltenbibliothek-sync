<?php

$FIREBASE_SDK = '/opt/flutter/firebase-admin-sdk.json';
$FIRESTORE_COLLECTION = 'chat_messages';

$pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Query for app messages not synced to Telegram
query = (
    db.collection('$FIRESTORE_COLLECTION')
    .where('source', '==', 'app')
    .where('syncedToTelegram', '==', False)
    .limit(10)
)

docs = query.get()
messages = []

for doc in docs:
    data = doc.to_dict()
    # Convert timestamp to string for JSON serialization
    if 'timestamp' in data and data['timestamp']:
        data['timestamp'] = str(data['timestamp'])
    data['doc_id'] = doc.id
    messages.append(data)

print(json.dumps(messages))
PYTHON;

$output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");

echo "Raw output:\n$output\n\n";

$messages = json_decode($output, true);

if (is_array($messages) && count($messages) > 0) {
    echo "✅ Gefunden: " . count($messages) . " ungesyncte App-Nachrichten\n";
    foreach ($messages as $msg) {
        echo "   - Text: " . ($msg['text'] ?? 'N/A') . "\n";
        echo "     doc_id: " . ($msg['doc_id'] ?? 'N/A') . "\n";
    }
} else {
    echo "❌ Keine Nachrichten gefunden oder JSON-Fehler\n";
}

