<?php
/**
 * 🔄 TELEGRAM CHAT BIDIREKTIONALE SYNCHRONISATION (MadelineProto)
 * ================================================================
 * 
 * Synchronisiert Chat-Nachrichten zwischen:
 * - Telegram-Chat (@Weltenbibliothekchat) ↔ Flutter-App (Firestore)
 * 
 * Features:
 * ✅ Nachrichten von Telegram → Firestore
 * ✅ Nachrichten von App (Firestore) → Telegram
 * ✅ Bearbeitungen synchronisieren (bidirektional)
 * ✅ Löschungen synchronisieren (bidirektional)
 * ✅ Telegram-Benutzernamen anzeigen
 * ✅ Medien-Upload zu FTP-Server (chat-Ordner)
 * ✅ Auto-Löschung nach 6 Stunden (konfigurierbar)
 * 
 * Telegram API:
 * - API ID: 25697241
 * - API Hash: 19cfb3819684da4571a91874ee22603a
 * - Session: session.madeline (bereits vorhanden)
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\EventHandler;

// ========================================
// KONFIGURATION
// ========================================

// Telegram Chat
$CHAT_USERNAME = '@Weltenbibliothekchat';

// FTP Server (Xlight)
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';
$FTP_REMOTE_PATH = '/chat/';  // Chat-Ordner im FTP
$HTTP_BASE_URL = "http://{$FTP_HOST}:8080/chat";  // HTTP-URL für Chat-Ordner

// Firebase
$FIREBASE_SDK = '/opt/flutter/firebase-admin-sdk.json';
$FIRESTORE_COLLECTION = 'chat_messages';

// Auto-Delete & Sync-Intervall
$DELETE_AFTER_HOURS = 6;       // Auto-Delete nach 6 Stunden (statt 24h)
$CHECK_INTERVAL_SECONDS = 3;   // Sync alle 3 Sekunden (statt 300s / 5 Min)

echo "\n";
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║  🔄 TELEGRAM CHAT BIDIREKTIONALE SYNCHRONISATION         ║\n";
echo "║     MadelineProto + Firestore + FTP Integration          ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// ========================================
// FIREBASE HELPER FUNKTIONEN
// ========================================

function getFirestore() {
    global $FIREBASE_SDK;
    
    static $db = null;
    if ($db !== null) {
        return $db;
    }
    
    // Initialize Firebase via Python
    $pythonCode = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()
PYTHON;
    
    $db = 'initialized';
    return $db;
}

function saveToFirestore($data) {
    global $FIREBASE_SDK, $FIRESTORE_COLLECTION;
    
    $dataJson = json_encode($data, JSON_UNESCAPED_UNICODE);
    
    $pythonScript = <<<PYTHON
import sys
import json
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()
data = json.loads('''$dataJson''')

# Add server timestamp
data['timestamp'] = firestore.SERVER_TIMESTAMP

# Save to Firestore
db.collection('$FIRESTORE_COLLECTION').add(data)
print("OK")
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'OK') !== false;
}

function getUnsyncedAppMessages() {
    global $FIREBASE_SDK, $FIRESTORE_COLLECTION;
    
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
    
    // Extract JSON from output (skip warnings)
    $lines = explode("\n", $output);
    $jsonLine = '';
    foreach ($lines as $line) {
        $trimmed = trim($line);
        if ($trimmed && ($trimmed[0] === '[' || $trimmed[0] === '{')) {
            $jsonLine = $trimmed;
            break;
        }
    }
    
    $messages = json_decode($jsonLine, true);
    
    return is_array($messages) ? $messages : [];
}

function markAsSynced($docId, $telegramMessageId) {
    global $FIREBASE_SDK, $FIRESTORE_COLLECTION;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()
doc_ref = db.collection('$FIRESTORE_COLLECTION').document('$docId')
doc_ref.update({
    'syncedToTelegram': True,
    'telegramMessageId': '$telegramMessageId',
    'syncedAt': firestore.SERVER_TIMESTAMP
})
print("OK")
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'OK') !== false;
}

function deleteOldMessages($hoursOld = 24) {
    global $FIREBASE_SDK, $FIRESTORE_COLLECTION;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Calculate cutoff time
delete_before = datetime.utcnow() - timedelta(hours=$hoursOld)

# Query old messages
query = (
    db.collection('$FIRESTORE_COLLECTION')
    .where('timestamp', '<', delete_before)
    .where('deleted', '==', False)
    .limit(50)
)

docs = query.get()
deleted_docs = []

for doc in docs:
    data = doc.to_dict()
    deleted_docs.append({
        'doc_id': doc.id,
        'messageId': data.get('messageId'),
        'ftpPath': data.get('ftpPath')
    })
    
    # Mark as deleted
    doc.reference.update({
        'deleted': True,
        'deletedAt': firestore.SERVER_TIMESTAMP,
        'autoDeleted': True
    })

print(json.dumps(deleted_docs))
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    $deletedDocs = json_decode($output, true);
    
    return is_array($deletedDocs) ? $deletedDocs : [];
}

// ========================================
// FTP HELPER FUNKTIONEN
// ========================================

function uploadToFTP($localPath, $remotePath) {
    global $FTP_HOST, $FTP_PORT, $FTP_USER, $FTP_PASS, $HTTP_BASE_URL;
    
    try {
        // Connect with longer timeout for large files
        $conn = ftp_connect($FTP_HOST, $FTP_PORT, 30);
        if (!$conn) {
            return null;
        }
        
        if (!ftp_login($conn, $FTP_USER, $FTP_PASS)) {
            @ftp_close($conn);
            return null;
        }
        
        // Passive mode for better compatibility
        @ftp_pasv($conn, true);
        
        // Set longer timeout for upload
        @ftp_set_option($conn, FTP_TIMEOUT_SEC, 90);
        
        // Upload file directly (directory /chat/ already exists)
        if (@ftp_put($conn, $remotePath, $localPath, FTP_BINARY)) {
            $size = @ftp_size($conn, $remotePath);
            @ftp_close($conn);
            
            // Build HTTP URL
            $filename = basename($remotePath);
            return $HTTP_BASE_URL . '/' . $filename;
        } else {
            @ftp_close($conn);
            return null;
        }
        
    } catch (Exception $e) {
        return null;
    }
}

function deleteFromFTP($remotePath) {
    global $FTP_HOST, $FTP_PORT, $FTP_USER, $FTP_PASS;
    
    try {
        $conn = ftp_connect($FTP_HOST, $FTP_PORT);
        if (!$conn) return false;
        
        if (!ftp_login($conn, $FTP_USER, $FTP_PASS)) {
            ftp_close($conn);
            return false;
        }
        
        ftp_pasv($conn, true);
        $result = @ftp_delete($conn, $remotePath);
        ftp_close($conn);
        
        return $result;
        
    } catch (Exception $e) {
        return false;
    }
}

// ========================================
// MADELINEPROTO INITIALIZATION
// ========================================

echo "🔧 Initialisiere MadelineProto...\n";

// MadelineProto 8.x Settings
$settings = new \danog\MadelineProto\Settings;
$settings->getLogger()->setLevel(Logger::NOTICE);
$settings->getAppInfo()
    ->setApiId(25697241)
    ->setApiHash('19cfb3819684da4571a91874ee22603a');

$MadelineProto = new API(__DIR__ . '/../../madeline_backend/session.madeline', $settings);
$MadelineProto->start();

echo "✅ MadelineProto verbunden\n";

// Get chat peer
echo "🔍 Suche Chat: $CHAT_USERNAME...\n";
$chatPeer = $MadelineProto->getInfo($CHAT_USERNAME);
$chatId = $chatPeer['bot_api_id'];
echo "✅ Chat ID: $chatId\n\n";

// ========================================
// MAIN SYNC LOOP
// ========================================

echo "🔄 Starte Synchronisations-Loop...\n";
echo "   📍 Chat: $CHAT_USERNAME\n";
echo "   🕐 Auto-Delete: {$DELETE_AFTER_HOURS}h\n";
echo "   ⏱️  Check-Intervall: {$CHECK_INTERVAL_SECONDS}s\n\n";

$lastMessageId = 0;
$loopCount = 0;

while (true) {
    $loopCount++;
    echo "════════════════════════════════════════════════════════════\n";
    echo "🔄 SYNC CYCLE #{$loopCount} - " . date('Y-m-d H:i:s') . "\n";
    echo "════════════════════════════════════════════════════════════\n\n";
    
    // ------------------------------------------------
    // 1. TELEGRAM → FIRESTORE (Neue Nachrichten)
    // ------------------------------------------------
    
    echo "📥 1. Telegram → Firestore (neue Nachrichten)...\n";
    
    try {
        $history = $MadelineProto->messages->getHistory([
            'peer' => $CHAT_USERNAME,
            'limit' => 10,
        ]);
        
        $messages = $history['messages'];
        $newCount = 0;
        
        foreach ($messages as $message) {
            $msgId = $message['id'];
            
            // Skip if already processed
            if ($msgId <= $lastMessageId) {
                continue;
            }
            
            // Extract user info - FIXED for channels
            $userId = null;
            
            // from_id can be a direct number (user_id) or array structure
            if (is_numeric($message['from_id'])) {
                $userId = $message['from_id'];
            } elseif (isset($message['from_id']['user_id'])) {
                $userId = $message['from_id']['user_id'];
            } elseif (isset($message['post_author'])) {
                // Channel post - use post_author as identifier
                $userId = 'channel_' . $message['post_author'];
            } elseif (isset($message['peer_id']['channel_id'])) {
                // Channel message without author - use channel ID
                $userId = 'channel_' . $message['peer_id']['channel_id'];
            }
            
            if (!$userId) {
                continue;
            }
            
            $userInfo = $MadelineProto->getInfo($userId);
            $username = $userInfo['User']['username'] ?? null;
            $firstName = $userInfo['User']['first_name'] ?? '';
            $lastName = $userInfo['User']['last_name'] ?? '';
            
            $text = $message['message'] ?? '';
            
            echo "   📨 Neue Nachricht #{$msgId} von @{$username}: " . substr($text, 0, 50) . "...\n";
            
            // Prepare Firestore data
            $firestoreData = [
                'messageId' => (string)$msgId,
                'telegramUserId' => (string)$userId,
                'telegramUsername' => $username,
                'telegramFirstName' => $firstName,
                'telegramLastName' => $lastName,
                'text' => $text,
                'source' => 'telegram',
                'edited' => false,
                'deleted' => false,
                'mediaUrl' => null,
                'mediaType' => null,
                'ftpPath' => null,
                'replyToId' => null,
            ];
            
            // Handle media if present
            if (isset($message['media'])) {
                echo "      🖼️ Medien erkannt, lade herunter...\n";
                
                try {
                    $tempFile = sys_get_temp_dir() . "/chat_media_{$msgId}";
                    $MadelineProto->downloadToFile($message['media'], $tempFile);
                    
                    // Determine media type
                    $mediaType = 'photo';
                    $fileExt = '.jpg';
                    
                    if (isset($message['media']['_'])) {
                        if ($message['media']['_'] === 'messageMediaDocument') {
                            $doc = $message['media']['document'];
                            $mimeType = $doc['mime_type'] ?? '';
                            
                            if (strpos($mimeType, 'video') !== false) {
                                $mediaType = 'video';
                                $fileExt = '.mp4';
                            } elseif (strpos($mimeType, 'audio') !== false) {
                                $mediaType = 'audio';
                                $fileExt = '.mp3';
                            } else {
                                $mediaType = 'document';
                                $fileExt = '.pdf';
                            }
                        }
                    }
                    
                    // Upload to FTP (chat-Ordner)
                    global $FTP_REMOTE_PATH;
                    $ftpPath = "{$FTP_REMOTE_PATH}{$mediaType}_{$msgId}{$fileExt}";
                    $mediaUrl = uploadToFTP($tempFile, $ftpPath);
                    
                    if ($mediaUrl) {
                        $firestoreData['mediaUrl'] = $mediaUrl;
                        $firestoreData['mediaType'] = $mediaType;
                        $firestoreData['ftpPath'] = $ftpPath;
                        echo "      ✅ Medien auf FTP hochgeladen\n";
                    } else {
                        echo "      ⚠️  Medien-Upload fehlgeschlagen, speichere nur Text\n";
                    }
                    
                    if (file_exists($tempFile)) {
                        unlink($tempFile);
                    }
                } catch (Exception $e) {
                    echo "      ⚠️  Medien-Fehler: " . $e->getMessage() . ", speichere nur Text\n";
                }
            }
            
            // Save to Firestore (always save, even if media upload failed)
            if (saveToFirestore($firestoreData)) {
                echo "      ✅ In Firestore gespeichert\n";
                $newCount++;
                $lastMessageId = $msgId;
            } else {
                echo "      ❌ Firestore Save fehlgeschlagen\n";
            }
        }
        
        echo "   ✅ {$newCount} neue Nachrichten verarbeitet\n\n";
        
    } catch (Exception $e) {
        echo "   ❌ Fehler: " . $e->getMessage() . "\n\n";
    }
    
    // ------------------------------------------------
    // 2. FIRESTORE → TELEGRAM (App-Nachrichten senden)
    // ------------------------------------------------
    
    echo "📤 2. Firestore → Telegram (App-Nachrichten)...\n";
    
    try {
        $appMessages = getUnsyncedAppMessages();
        
        if (count($appMessages) > 0) {
            echo "   🔍 DEBUG: " . count($appMessages) . " ungesyncte Nachrichten gefunden\n";
        }
        
        foreach ($appMessages as $msg) {
            $text = $msg['text'] ?? '';
            $docId = $msg['doc_id'];
            
            echo "   📨 Sende App-Nachricht: " . substr($text, 0, 50) . "...\n";
            
            // Send to Telegram
            $sentMsg = $MadelineProto->messages->sendMessage([
                'peer' => $CHAT_USERNAME,
                'message' => $text,
            ]);
            
            $telegramMsgId = $sentMsg['updates'][0]['id'] ?? null;
            
            if ($telegramMsgId) {
                markAsSynced($docId, $telegramMsgId);
                echo "      ✅ Zu Telegram gesendet (ID: {$telegramMsgId})\n";
            }
        }
        
        echo "   ✅ " . count($appMessages) . " App-Nachrichten gesendet\n\n";
        
    } catch (Exception $e) {
        echo "   ❌ Fehler: " . $e->getMessage() . "\n\n";
    }
    
    // ------------------------------------------------
    // 3. AUTO-DELETE (alte Nachrichten nach konfigurierbarer Zeit)
    // ------------------------------------------------
    
    echo "🗑️  3. Auto-Delete ({$DELETE_AFTER_HOURS}h Cleanup)...\n";
    
    try {
        $deletedDocs = deleteOldMessages($DELETE_AFTER_HOURS);
        
        foreach ($deletedDocs as $doc) {
            $telegramMsgId = $doc['messageId'];
            $ftpPath = $doc['ftpPath'];
            
            // Delete from Telegram
            if ($telegramMsgId) {
                try {
                    $MadelineProto->channels->deleteMessages([
                        'channel' => $CHAT_USERNAME,
                        'id' => [(int)$telegramMsgId],
                    ]);
                    echo "   ✅ Telegram Nachricht #{$telegramMsgId} gelöscht\n";
                } catch (Exception $e) {
                    echo "   ⚠️  Telegram Delete fehlgeschlagen: {$e->getMessage()}\n";
                }
            }
            
            // Delete from FTP
            if ($ftpPath) {
                if (deleteFromFTP($ftpPath)) {
                    echo "   ✅ FTP Datei gelöscht: {$ftpPath}\n";
                }
            }
        }
        
        echo "   ✅ " . count($deletedDocs) . " alte Nachrichten gelöscht\n\n";
        
    } catch (Exception $e) {
        echo "   ❌ Fehler: " . $e->getMessage() . "\n\n";
    }
    
    // Wait before next cycle
    echo "⏳ Warte {$CHECK_INTERVAL_SECONDS} Sekunden bis zum nächsten Zyklus...\n\n";
    sleep($CHECK_INTERVAL_SECONDS);
}

?>
