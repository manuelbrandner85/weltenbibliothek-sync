<?php
/**
 * 🔄 MULTI-CHANNEL TELEGRAM SYNCHRONISATION (MadelineProto)
 * ==========================================================
 * 
 * Synchronisiert 6 Telegram-Kanäle mit Firestore Collections:
 * 
 * 1. @Weltenbibliothekchat       → chat_messages
 * 2. @WeltenbibliothekPDF        → pdf_documents
 * 3. @weltenbibliothekbilder     → images
 * 4. @WeltenbibliothekWachauf    → wachauf_content
 * 5. @ArchivWeltenBibliothek     → archive_items
 * 6. @WeltenbibliothekHoerbuch   → audiobooks
 * 
 * Features pro Kanal:
 * ✅ Telegram → Firestore (neue Nachrichten)
 * ✅ Firestore → Telegram (App-Nachrichten)
 * ✅ Medien-Upload zu FTP-Server
 * ✅ Auto-Delete nach 6 Stunden
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\Settings;
use danog\MadelineProto\Settings\AppInfo;

// ========================================
// MULTI-CHANNEL KONFIGURATION
// ========================================

$CHANNELS = [
    [
        'name' => 'Chat',
        'username' => '@Weltenbibliothekchat',
        'collection' => 'chat_messages',
        'ftpFolder' => '/chat/',  // ALLE Chat-Medien → /chat/
    ],
    [
        'name' => 'PDFs',
        'username' => '@WeltenbibliothekPDF',
        'collection' => 'pdf_messages',
        'ftpFolder' => '/pdfs/',  // ALLE Medien aus PDF-Kanal → /pdfs/
    ],
    [
        'name' => 'Bilder',
        'username' => '@weltenbibliothekbilder',
        'collection' => 'bilder_messages',
        'ftpFolder' => '/images/',  // ALLE Medien aus Bilder-Kanal → /images/
    ],
    [
        'name' => 'WachAuf',
        'username' => '@WeltenbibliothekWachauf',
        'collection' => 'wachauf_messages',
        'ftpFolder' => '/audios/',  // Audio/Videos aus WachAuf → /audios/
    ],
    [
        'name' => 'Video-Archiv',
        'username' => '@ArchivWeltenBibliothek',
        'collection' => 'archiv_messages',
        'ftpFolder' => '/videos/',  // Videos aus Archiv → /videos/
    ],
    [
        'name' => 'Hörbücher',
        'username' => '@WeltenbibliothekHoerbuch',
        'collection' => 'hoerbuch_messages',
        'ftpFolder' => '/audios/',  // Audio aus Hörbücher → /audios/
    ],
];

// FTP Server (Xlight)
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';
$HTTP_BASE_URL = "http://{$FTP_HOST}:8080";

// Firebase
$FIREBASE_SDK = '/opt/flutter/firebase-admin-sdk.json';

// Auto-Delete & Sync-Intervall
$DELETE_AFTER_HOURS = 6;
$CHECK_INTERVAL_SECONDS = 1;

echo "\n";
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║  🔄 MULTI-CHANNEL TELEGRAM SYNCHRONISATION               ║\n";
echo "║     6 Kanäle → Firestore + FTP Integration               ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// ========================================
// MADELINE PROTO INITIALISIERUNG
// ========================================

echo "🔧 Initialisiere MadelineProto...\n";

$settings = new Settings;
$appInfo = new AppInfo;
$appInfo->setApiId(25697241);
$appInfo->setApiHash('19cfb3819684da4571a91874ee22603a');
$settings->setAppInfo($appInfo);

// Use existing session
$sessionPath = __DIR__ . '/session.madeline';

if (!file_exists($sessionPath)) {
    die("❌ Session nicht gefunden! Bitte zuerst telegram_chat_sync_madeline.php ausführen.\n");
}

$MadelineProto = new API($sessionPath, $settings);
$MadelineProto->start();

echo "✅ MadelineProto verbunden (bestehende Session)\n\n";

// Resolve alle Channel-IDs
echo "🔍 Resolving Channel-IDs...\n";
foreach ($CHANNELS as &$channel) {
    try {
        $peer = $MadelineProto->getInfo($channel['username']);
        $channel['chat_id'] = $peer['bot_api_id'];
        echo "   ✅ {$channel['name']}: {$channel['chat_id']}\n";
    } catch (Exception $e) {
        echo "   ❌ {$channel['name']}: Fehler - " . $e->getMessage() . "\n";
        $channel['chat_id'] = null;
    }
}
echo "\n";

// ========================================
// HELPER FUNKTIONEN
// ========================================

function uploadToFTP($localPath, $remotePath) {
    global $FTP_HOST, $FTP_PORT, $FTP_USER, $FTP_PASS, $HTTP_BASE_URL;
    
    try {
        $conn = ftp_connect($FTP_HOST, $FTP_PORT, 30);
        if (!$conn) return null;
        
        if (!ftp_login($conn, $FTP_USER, $FTP_PASS)) {
            @ftp_close($conn);
            return null;
        }
        
        @ftp_pasv($conn, true);
        @ftp_set_option($conn, FTP_TIMEOUT_SEC, 90);
        
        if (@ftp_put($conn, $remotePath, $localPath, FTP_BINARY)) {
            @ftp_close($conn);
            $filename = basename($remotePath);
            $dir = dirname($remotePath);
            return $HTTP_BASE_URL . $dir . '/' . $filename;
        } else {
            @ftp_close($conn);
            return null;
        }
    } catch (Exception $e) {
        return null;
    }
}

function saveToFirestore($collection, $data) {
    global $FIREBASE_SDK;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()
data = json.loads('''$data''')

try:
    db.collection('$collection').add(data)
    print('success')
except Exception as e:
    print(f'error: {{e}}')
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'success') !== false;
}

function getUnsyncedAppMessages($collection) {
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
    .limit(10)
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
    
    // Extract only JSON part from output
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
    print(f'error: {{e}}')
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'success') !== false;
}

// ========================================
// MULTI-CHANNEL SYNC LOOP
// ========================================

$loopCount = 0;
$channelLastMessageIds = [];

foreach ($CHANNELS as $channel) {
    $channelLastMessageIds[$channel['username']] = 0;
}

echo "🔄 Starte Multi-Channel Synchronisations-Loop...\n";
echo "   📍 Kanäle: " . count($CHANNELS) . "\n";
echo "   🕐 Auto-Delete: {$DELETE_AFTER_HOURS}h\n";
echo "   ⏱️  Check-Intervall: {$CHECK_INTERVAL_SECONDS}s\n\n";

while (true) {
    $loopCount++;
    
    echo "════════════════════════════════════════════════════════════\n";
    echo "🔄 SYNC CYCLE #{$loopCount} - " . date('Y-m-d H:i:s') . "\n";
    echo "════════════════════════════════════════════════════════════\n\n";
    
    // Synchronisiere jeden Kanal
    foreach ($CHANNELS as $channel) {
        if ($channel['chat_id'] === null) continue;
        
        echo "📺 Kanal: {$channel['name']} ({$channel['username']})\n";
        
        // 1. TELEGRAM → FIRESTORE
        try {
            // KRITISCH: Höheres Limit um 100% der Daten zu erfassen
            // Bei 3 Sekunden Intervall können theoretisch viele Nachrichten ankommen
            $history = $MadelineProto->messages->getHistory([
                'peer' => $channel['username'],
                'limit' => 100,  // Erhöht von 10 auf 100
            ]);
            
            $messages = $history['messages'];
            $newCount = 0;
            
            foreach ($messages as $message) {
                $msgId = $message['id'];
                
                // Skip if already processed
                if ($msgId <= $channelLastMessageIds[$channel['username']]) {
                    continue;
                }
                
                // Extract user info
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
                
                // Prepare Firestore data
                $firestoreData = [
                    'messageId' => (string)$msgId,
                    'telegramUserId' => (string)$userId,
                    'telegramUsername' => $username,
                    'telegramFirstName' => $firstName,
                    'telegramLastName' => $lastName,
                    'text' => $text,
                    'source' => 'telegram',
                    'channel' => $channel['name'],
                    'channelUsername' => $channel['username'],
                    'edited' => false,
                    'deleted' => false,
                    'mediaUrl' => null,
                    'mediaType' => null,
                    'ftpPath' => null,
                    'originalFileName' => null,
                    'syncedToTelegram' => true,
                    'replyToId' => null,
                ];
                
                // Handle media if present
                if (isset($message['media'])) {
                    try {
                        $tempFile = sys_get_temp_dir() . "/media_{$channel['name']}_{$msgId}";
                        $MadelineProto->downloadToFile($message['media'], $tempFile);
                        
                        $mediaType = 'photo';
                        $fileExt = '.jpg';
                        $originalFileName = null;
                        
                        if (isset($message['media']['_'])) {
                            if ($message['media']['_'] === 'messageMediaDocument') {
                                $doc = $message['media']['document'];
                                $mimeType = $doc['mime_type'] ?? '';
                                
                                // Hole Original-Dateinamen aus Telegram
                                if (isset($doc['attributes'])) {
                                    foreach ($doc['attributes'] as $attr) {
                                        if (isset($attr['_']) && $attr['_'] === 'documentAttributeFilename') {
                                            $originalFileName = $attr['file_name'] ?? null;
                                            break;
                                        }
                                    }
                                }
                                
                                if (strpos($mimeType, 'video') !== false) {
                                    $mediaType = 'video';
                                    $fileExt = '.mp4';
                                } elseif (strpos($mimeType, 'audio') !== false) {
                                    $mediaType = 'audio';
                                    $fileExt = '.mp3';
                                } elseif (strpos($mimeType, 'pdf') !== false) {
                                    $mediaType = 'document';
                                    $fileExt = '.pdf';
                                } else {
                                    $mediaType = 'document';
                                    $fileExt = '.pdf';
                                }
                            }
                        }
                        
                        // Erstelle Dateinamen basierend auf Telegram-Titel
                        if ($originalFileName && !empty($originalFileName)) {
                            $cleanFileName = preg_replace('/[^a-zA-Z0-9_\-äöüÄÖÜß\.]/', '_', $originalFileName);
                            $uniqueFilename = $cleanFileName;
                        } else {
                            $textSnippet = substr($text, 0, 50);
                            $cleanText = preg_replace('/[^a-zA-Z0-9_\-äöüÄÖÜß]/', '_', $textSnippet);
                            $cleanText = trim($cleanText, '_');
                            
                            if (!empty($cleanText)) {
                                $uniqueFilename = $cleanText . "_{$msgId}{$fileExt}";
                            } else {
                                $channelPrefix = str_replace(['@', 'Weltenbibliothek'], '', $channel['username']);
                                $uniqueFilename = strtolower($channelPrefix) . "_{$msgId}{$fileExt}";
                            }
                        }
                        
                        // Begrenze Länge
                        if (strlen($uniqueFilename) > 200) {
                            $nameWithoutExt = pathinfo($uniqueFilename, PATHINFO_FILENAME);
                            $extension = pathinfo($uniqueFilename, PATHINFO_EXTENSION);
                            $uniqueFilename = substr($nameWithoutExt, 0, 190) . "_{$msgId}." . $extension;
                        }
                        
                        // Upload to FTP
                        $ftpPath = "{$channel['ftpFolder']}{$uniqueFilename}";
                        $mediaUrl = uploadToFTP($tempFile, $ftpPath);
                        
                        if ($mediaUrl) {
                            $firestoreData['mediaUrl'] = $mediaUrl;
                            $firestoreData['mediaType'] = $mediaType;
                            $firestoreData['ftpPath'] = $ftpPath;
                            $firestoreData['originalFileName'] = $originalFileName;
                        }
                        
                        if (file_exists($tempFile)) {
                            unlink($tempFile);
                        }
                    } catch (Exception $e) {
                        // Medien-Fehler ignorieren
                    }
                }
                
                // Save to Firestore
                $dataJson = json_encode($firestoreData, JSON_UNESCAPED_UNICODE);
                if (saveToFirestore($channel['collection'], $dataJson)) {
                    $newCount++;
                    $channelLastMessageIds[$channel['username']] = $msgId;
                }
            }
            
            echo "   ✅ {$newCount} neue Nachrichten synchronisiert\n";
            
        } catch (Exception $e) {
            echo "   ❌ Fehler: " . $e->getMessage() . "\n";
        }
        
        // 2. FIRESTORE → TELEGRAM
        try {
            $appMessages = getUnsyncedAppMessages($channel['collection']);
            
            foreach ($appMessages as $msg) {
                $text = $msg['text'] ?? '';
                $docId = $msg['doc_id'];
                
                $sentMsg = $MadelineProto->messages->sendMessage([
                    'peer' => $channel['username'],
                    'message' => $text,
                ]);
                
                $telegramMsgId = $sentMsg['updates'][0]['id'] ?? null;
                
                if ($telegramMsgId) {
                    markAsSynced($channel['collection'], $docId, $telegramMsgId);
                }
            }
            
            if (count($appMessages) > 0) {
                echo "   ✅ " . count($appMessages) . " App-Nachrichten gesendet\n";
            }
            
        } catch (Exception $e) {
            echo "   ❌ App-Sync Fehler: " . $e->getMessage() . "\n";
        }
        
        echo "\n";
    }
    
    echo "⏳ Warte {$CHECK_INTERVAL_SECONDS} Sekunden bis zum nächsten Zyklus...\n\n";
    sleep($CHECK_INTERVAL_SECONDS);
}
