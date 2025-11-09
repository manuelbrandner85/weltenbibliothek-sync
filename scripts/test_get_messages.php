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
    data['doc_id'] = doc.id
    messages.append(data)

print(json.dumps(messages))
PYTHON;

echo "Executing Python script...\n";
$output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");

echo "Raw output:\n";
echo $output . "\n\n";

$messages = json_decode($output, true);

echo "Decoded messages:\n";
var_dump($messages);

echo "\nIs array: " . (is_array($messages) ? 'Yes' : 'No') . "\n";
echo "Count: " . (is_array($messages) ? count($messages) : 0) . "\n";

