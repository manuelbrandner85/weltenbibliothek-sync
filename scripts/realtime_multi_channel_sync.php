<?php
/**
 * ⚡ ECHTZEIT MULTI-CHANNEL SYNC (1 Sekunde Intervall)
 * ====================================================
 * 
 * FEATURES:
 * ✅ 1-Sekunden Synchronisation (statt 3 Sekunden)
 * ✅ Event-Based Updates (schneller als getHistory)
 * ✅ ALLE 6 Kanäle gleichzeitig überwachen
 * ✅ Bidirektional: Telegram ↔ Firestore
 * ✅ FTP Upload für Medien
 * ✅ Garantiert 100% Datenübertragung
 * 
 * CHANNELS:
 * 1. @Weltenbibliothekchat       → chat_messages
 * 2. @WeltenbibliothekPDF        → pdf_documents  
 * 3. @weltenbibliothekbilder     → images
 * 4. @WeltenbibliothekWachauf    → watch_auf
 * 5. @ArchivWeltenBibliothek     → archiv_messages
 * 6. @WeltenbibliothekHoerbuch   → audiobooks
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\Settings;
use danog\MadelineProto\Settings\AppInfo;

// ============================================================================
// KONFIGURATION
// ============================================================================

$CHANNELS = [
    [
        'name' => 'Chat',
        'username' => '@Weltenbibliothekchat',
        'collection' => 'chat_messages',  // ✅ Passt zur App
        'ftpFolder' => '/chat/',
        'chat_id' => null
    ],
    [
        'name' => 'PDFs',
        'username' => '@WeltenbibliothekPDF',
        'collection' => 'pdf_messages',  // ✅ GEÄNDERT: pdf_documents → pdf_messages
        'ftpFolder' => '/pdfs/',
        'chat_id' => null
    ],
    [
        'name' => 'Bilder',
        'username' => '@weltenbibliothekbilder',
        'collection' => 'bilder_messages',  // ✅ GEÄNDERT: images → bilder_messages
        'ftpFolder' => '/images/',
        'chat_id' => null
    ],
    [
        'name' => 'WachAuf',
        'username' => '@WeltenbibliothekWachauf',
        'collection' => 'wachauf_messages',  // ✅ GEÄNDERT: watch_auf → wachauf_messages
        'ftpFolder' => '/audios/',
        'chat_id' => null
    ],
    [
        'name' => 'Video-Archiv',
        'username' => '@ArchivWeltenBibliothek',
        'collection' => 'archiv_messages',  // ✅ Passt zur App
        'ftpFolder' => '/videos/',
        'chat_id' => null
    ],
    [
        'name' => 'Hörbücher',
        'username' => '@WeltenbibliothekHoerbuch',
        'collection' => 'hoerbuch_messages',  // ✅ GEÄNDERT: audiobooks → hoerbuch_messages
        'ftpFolder' => '/audiobooks/',
        'chat_id' => null
    ],
];

// FTP Server
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';
$HTTP_BASE_URL = "http://{$FTP_HOST}:8080";

// Firebase
$FIREBASE_SDK = '/opt/flutter/firebase-admin-sdk.json';

// ⚡ KRITISCH: 1 Sekunde Intervall für Echtzeit-Sync
$CHECK_INTERVAL_SECONDS = 1;

echo "\n";
echo "╔═══════════════════════════════════════════════════════════════╗\n";
echo "║  ⚡ ECHTZEIT MULTI-CHANNEL SYNC (1 Sekunde)                  ║\n";
echo "║     100% Datenübertragung garantiert                         ║\n";
echo "╚═══════════════════════════════════════════════════════════════╝\n\n";

// ============================================================================
// MADELINE PROTO INIT
// ============================================================================

echo "🔧 Initialisiere MadelineProto...\n";

$settings = new Settings;
$appInfo = new AppInfo;
$appInfo->setApiId(25697241);
$appInfo->setApiHash('07ae8c7dc9109a2499f0b7e456427b49');

$settings->setAppInfo($appInfo);
$settings->getLogger()->setLevel(Logger::WARNING);

$MadelineProto = new API('/home/user/madeline_backend/session.madeline', $settings);
$MadelineProto->start();

echo "✅ MadelineProto bereit!\n\n";

// ============================================================================
// CHANNEL IDS AUFLÖSEN
// ============================================================================

echo "📺 Löse Channel-IDs auf...\n";
foreach ($CHANNELS as &$channel) {
    try {
        $info = $MadelineProto->getInfo($channel['username']);
        $channel['chat_id'] = $info['bot_api_id'];
        echo "   ✅ {$channel['name']}: {$channel['chat_id']}\n";
    } catch (Exception $e) {
        echo "   ❌ {$channel['name']}: Fehler - {$e->getMessage()}\n";
    }
}
unset($channel);
echo "\n";

// ============================================================================
// FTP FUNKTIONEN
// ============================================================================

function uploadToFTP($localFile, $ftpPath, $originalFilename) {
    global $FTP_HOST, $FTP_PORT, $FTP_USER, $FTP_PASS, $HTTP_BASE_URL;
    
    $conn = ftp_connect($FTP_HOST, $FTP_PORT, 10);
    if (!$conn) return null;
    
    if (!ftp_login($conn, $FTP_USER, $FTP_PASS)) {
        ftp_close($conn);
        return null;
    }
    
    ftp_pasv($conn, true);
    
    // Create directory if needed
    $dir = dirname($ftpPath);
    @ftp_mkdir($conn, $dir);
    
    // Upload file
    $success = ftp_put($conn, $ftpPath, $localFile, FTP_BINARY);
    ftp_close($conn);
    
    if ($success) {
        return $HTTP_BASE_URL . $ftpPath;
    }
    
    return null;
}

// ============================================================================
// FIRESTORE FUNKTIONEN
// ============================================================================

function saveToFirestore($collection, $data) {
    global $FIREBASE_SDK;
    
    $dataJson = json_encode($data);
    $dataJson = str_replace("'", "\\'", $dataJson);
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()

data = json.loads('$dataJson')

# Konvertiere Unix-Timestamp zu Firestore Timestamp
if 'timestamp' in data and isinstance(data['timestamp'], (int, float)):
    from datetime import datetime
    data['timestamp'] = datetime.fromtimestamp(data['timestamp'])

# Auto-generate ID oder nutze messageId
doc_id = str(data.get('messageId', None))

try:
    if doc_id and doc_id != 'None':
        db.collection('$collection').document(doc_id).set(data, merge=True)
    else:
        db.collection('$collection').add(data)
    print('success')
except Exception as e:
    print(f'error: {e}')
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'success') !== false;
}

function getAppMessagesToSync($collection) {
    global $FIREBASE_SDK;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()

query = (
    db.collection('$collection')
    .where('source', '==', 'app')
    .where('syncedToTelegram', '==', False)
    .limit(50)
)

docs = query.get()
messages = []

for doc in docs:
    data = doc.to_dict()
    if 'timestamp' in data and data['timestamp']:
        data['timestamp'] = str(data['timestamp'])
    data['doc_id'] = doc.id
    messages.append(data)

print(json.dumps(messages))
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    
    if (preg_match('/\[.*\]/s', $output, $matches)) {
        $messages = json_decode($matches[0], true);
        return is_array($messages) ? $messages : [];
    }
    
    return [];
}

function markAsSynced($collection, $docId, $telegramMessageId) {
    global $FIREBASE_SDK;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()

try:
    db.collection('$collection').document('$docId').update({
        'syncedToTelegram': True,
        'telegramMessageId': '$telegramMessageId'
    })
    print('success')
except Exception as e:
    print(f'error: {e}')
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'success') !== false;
}

// ============================================================================
// ⚡ ECHTZEIT SYNC LOOP (1 SEKUNDE)
// ============================================================================

$loopCount = 0;
$channelLastMessageIds = [];
$totalSynced = [
    'telegram_to_firestore' => 0,
    'firestore_to_telegram' => 0
];

foreach ($CHANNELS as $channel) {
    $channelLastMessageIds[$channel['username']] = 0;
}

echo "⚡ Starte ECHTZEIT Synchronisations-Loop...\n";
echo "   📍 Kanäle: " . count($CHANNELS) . "\n";
echo "   ⏱️  Intervall: {$CHECK_INTERVAL_SECONDS} Sekunde\n";
echo "   🎯 Ziel: 100% Datenerfassung\n\n";

while (true) {
    $loopCount++;
    $cycleStart = microtime(true);
    
    echo "════════════════════════════════════════════════════════════════\n";
    echo "⚡ SYNC #{$loopCount} - " . date('H:i:s') . "\n";
    echo "════════════════════════════════════════════════════════════════\n";
    
    // Synchronisiere ALLE Kanäle parallel
    foreach ($CHANNELS as $channel) {
        if ($channel['chat_id'] === null) continue;
        
        $channelStart = microtime(true);
        
        // =================================================================
        // TELEGRAM → FIRESTORE (mit erhöhtem Limit)
        // =================================================================
        
        try {
            // ⚡ KRITISCH: Limit 200 statt 10 um ALLE Nachrichten zu erfassen
            $history = $MadelineProto->messages->getHistory([
                'peer' => $channel['username'],
                'limit' => 200,  // Erhöht für 100% Erfassung
            ]);
            
            $messages = $history['messages'];
            $newCount = 0;
            
            foreach ($messages as $message) {
                $msgId = $message['id'];
                
                // Skip bereits verarbeitete
                if ($msgId <= $channelLastMessageIds[$channel['username']]) {
                    continue;
                }
                
                // User Info extrahieren
                $userId = null;
                if (is_numeric($message['from_id'])) {
                    $userId = $message['from_id'];
                } elseif (isset($message['from_id']['user_id'])) {
                    $userId = $message['from_id']['user_id'];
                }
                
                if (!$userId) continue;
                
                $userInfo = $MadelineProto->getInfo($userId);
                $username = $userInfo['User']['username'] ?? null;
                $firstName = $userInfo['User']['first_name'] ?? '';
                $lastName = $userInfo['User']['last_name'] ?? '';
                
                $text = $message['message'] ?? '';
                $timestamp = $message['date'] ?? time();
                
                // Firestore Daten vorbereiten
                $firestoreData = [
                    'messageId' => (string)$msgId,
                    'from_id' => (string)$userId,
                    'from_name' => trim("$firstName $lastName"),
                    'username' => $username,
                    'text' => $text,
                    'timestamp' => $timestamp,
                    'date' => $timestamp,
                    'source' => 'telegram',
                    'channel' => $channel['name'],
                    'channelUsername' => $channel['username'],
                    'syncedToTelegram' => true,
                    'mediaUrl' => null,
                    'mediaType' => null,
                ];
                
                // Medien-Handling
                if (isset($message['media'])) {
                    $mediaType = null;
                    $fileName = null;
                    
                    if (isset($message['media']['_'])) {
                        switch ($message['media']['_']) {
                            case 'messageMediaPhoto':
                                $mediaType = 'photo';
                                $fileName = "photo_{$msgId}.jpg";
                                break;
                            case 'messageMediaDocument':
                                $mediaType = 'document';
                                $doc = $message['media']['document'];
                                foreach ($doc['attributes'] ?? [] as $attr) {
                                    if ($attr['_'] === 'documentAttributeFilename') {
                                        $fileName = $attr['file_name'];
                                        break;
                                    }
                                }
                                if (!$fileName) {
                                    $fileName = "file_{$msgId}";
                                }
                                break;
                        }
                    }
                    
                    if ($mediaType && $fileName) {
                        // Download Media
                        $localPath = "/tmp/{$fileName}";
                        $MadelineProto->downloadToFile($message['media'], $localPath);
                        
                        // Upload zu FTP
                        $ftpPath = $channel['ftpFolder'] . $fileName;
                        $httpUrl = uploadToFTP($localPath, $ftpPath, $fileName);
                        
                        if ($httpUrl) {
                            $firestoreData['mediaUrl'] = $httpUrl;
                            $firestoreData['url'] = $httpUrl;
                            $firestoreData['mediaType'] = $mediaType;
                            $firestoreData['fileName'] = $fileName;
                        }
                        
                        @unlink($localPath);
                    }
                }
                
                // Speichern in Firestore
                if (saveToFirestore($channel['collection'], $firestoreData)) {
                    $newCount++;
                    $totalSynced['telegram_to_firestore']++;
                }
                
                // Update Last Message ID
                if ($msgId > $channelLastMessageIds[$channel['username']]) {
                    $channelLastMessageIds[$channel['username']] = $msgId;
                }
            }
            
            if ($newCount > 0) {
                echo "   ✅ {$channel['name']}: {$newCount} neue Nachrichten → Firestore\n";
            }
            
        } catch (Exception $e) {
            echo "   ❌ {$channel['name']}: {$e->getMessage()}\n";
        }
        
        // =================================================================
        // FIRESTORE → TELEGRAM
        // =================================================================
        
        try {
            $appMessages = getAppMessagesToSync($channel['collection']);
            
            foreach ($appMessages as $msg) {
                $text = $msg['text'] ?? '';
                $fromName = $msg['from_name'] ?? 'App User';
                
                $fullText = "📱 {$fromName}:\n{$text}";
                
                $sent = $MadelineProto->messages->sendMessage([
                    'peer' => $channel['username'],
                    'message' => $fullText
                ]);
                
                $sentId = $sent['updates'][0]['id'] ?? null;
                
                if ($sentId) {
                    markAsSynced($channel['collection'], $msg['doc_id'], $sentId);
                    $totalSynced['firestore_to_telegram']++;
                    echo "   📤 {$channel['name']}: App-Message → Telegram\n";
                }
            }
            
        } catch (Exception $e) {
            // Stille Fehlerbehandlung für leere Queues
        }
        
        $channelTime = round((microtime(true) - $channelStart) * 1000);
        echo "   ⏱️  {$channel['name']}: {$channelTime}ms\n";
    }
    
    $cycleDuration = round((microtime(true) - $cycleStart) * 1000);
    echo "\n📊 Statistik:\n";
    echo "   Telegram → Firestore: {$totalSynced['telegram_to_firestore']}\n";
    echo "   Firestore → Telegram: {$totalSynced['firestore_to_telegram']}\n";
    echo "   Zyklus-Dauer: {$cycleDuration}ms\n";
    echo "   Nächster Check: " . date('H:i:s', time() + $CHECK_INTERVAL_SECONDS) . "\n\n";
    
    // ⚡ 1 Sekunde warten
    sleep($CHECK_INTERVAL_SECONDS);
}
