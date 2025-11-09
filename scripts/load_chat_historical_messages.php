<?php
/**
 * 📥 CHAT-GRUPPE HISTORISCHER DATEN-LOADER
 * ==========================================
 * 
 * Lädt ALLE historischen Nachrichten NUR von der Chat-Gruppe:
 * - @Weltenbibliothekchat → chat_messages
 * 
 * Alle Medien werden in /chat/ hochgeladen:
 * - C:\FTP_Media\chat\
 * 
 * Features:
 * ✅ Lädt ALLE Chat-Nachrichten (unbegrenzt)
 * ✅ Speichert Telegram-Benutzernamen
 * ✅ Alle Medien → /chat/ Ordner
 * ✅ Verhindert Duplikate
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\Settings;
use danog\MadelineProto\Settings\AppInfo;

// ========================================
// CHAT-GRUPPE KONFIGURATION
// ========================================

$CHAT_CONFIG = [
    'name' => 'Chat-Gruppe',
    'username' => '@Weltenbibliothekchat',
    'collection' => 'chat_messages',
    'ftpFolder' => '/chat/',  // ALLE Chat-Medien → /chat/
];

// FTP Server (Xlight)
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';
$HTTP_BASE_URL = "http://{$FTP_HOST}:8080";

// Firebase
$FIREBASE_SDK = '/opt/flutter/firebase-admin-sdk.json';

// WICHTIG: Laden ALLER Nachrichten (keine Begrenzung)
$MAX_MESSAGES = 10000;  // Sehr hohe Grenze für vollständige Historie

echo "\n";
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║  📥 CHAT-GRUPPE HISTORISCHER DATEN-LOADER               ║\n";
echo "║     Lädt ALLE Nachrichten von @Weltenbibliothekchat      ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

echo "📍 Chat: {$CHAT_CONFIG['username']}\n";
echo "📁 Medien-Ordner: {$CHAT_CONFIG['ftpFolder']}\n";
echo "📊 Max. Nachrichten: {$MAX_MESSAGES}\n\n";

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

echo "✅ MadelineProto verbunden\n\n";

// ========================================
// FIREBASE HELPER FUNKTIONEN
// ========================================

function saveToFirestore($collection, $data) {
    global $FIREBASE_SDK;
    
    $dataJson = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $dataBase64 = base64_encode($dataJson);
    
    $pythonScript = <<<PYTHON
import sys
import json
import base64
import firebase_admin
from firebase_admin import credentials, firestore

try:
    if not firebase_admin._apps:
        cred = credentials.Certificate('$FIREBASE_SDK')
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    
    data_json = base64.b64decode('$dataBase64').decode('utf-8')
    data = json.loads(data_json)
    data['timestamp'] = firestore.SERVER_TIMESTAMP
    
    db.collection('$collection').add(data)
    print("OK")
except Exception as e:
    print(f"ERROR: {str(e)}", file=sys.stderr)
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'OK') !== false;
}

function messageExists($collection, $messageId) {
    global $FIREBASE_SDK;
    
    $pythonScript = <<<PYTHON
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('$FIREBASE_SDK')
    firebase_admin.initialize_app(cred)

db = firestore.client()
query = db.collection('$collection').where('messageId', '==', '$messageId').limit(1).get()

if len(list(query)) > 0:
    print("EXISTS")
else:
    print("NEW")
PYTHON;
    
    $output = shell_exec("python3 -c " . escapeshellarg($pythonScript) . " 2>&1");
    return strpos($output, 'EXISTS') !== false;
}

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
            $folder = dirname($remotePath);
            return $HTTP_BASE_URL . $folder . '/' . $filename;
        } else {
            @ftp_close($conn);
            return null;
        }
        
    } catch (Exception $e) {
        return null;
    }
}

// ========================================
// HAUPTPROGRAMM: Lade ALLE Chat-Nachrichten
// ========================================

echo "════════════════════════════════════════════════════════════\n";
echo "📥 LADE: {$CHAT_CONFIG['name']} ({$CHAT_CONFIG['username']})\n";
echo "════════════════════════════════════════════════════════════\n\n";

try {
    // Resolve Chat-ID
    $peer = $MadelineProto->getInfo($CHAT_CONFIG['username']);
    $chatId = $peer['bot_api_id'];
    
    echo "   ✅ Chat-ID: {$chatId}\n";
    echo "   📊 Lade historische Nachrichten...\n\n";
    
    $totalLoaded = 0;
    $totalSaved = 0;
    $totalSkipped = 0;
    $offsetId = 0;
    
    // Lade Nachrichten in Batches (100 pro Request)
    while ($totalLoaded < $MAX_MESSAGES) {
        try {
            $history = $MadelineProto->messages->getHistory([
                'peer' => $CHAT_CONFIG['username'],
                'limit' => 100,
                'offset_id' => $offsetId,
            ]);
            
            $messages = $history['messages'];
            
            // Keine weiteren Nachrichten verfügbar
            if (empty($messages)) {
                echo "   ✅ Alle verfügbaren Nachrichten geladen\n";
                break;
            }
            
            $totalLoaded += count($messages);
            
            foreach ($messages as $message) {
                $msgId = $message['id'];
                
                // Update offset für nächsten Batch
                if ($msgId < $offsetId || $offsetId === 0) {
                    $offsetId = $msgId;
                }
                
                // Prüfe ob Nachricht bereits existiert
                if (messageExists($CHAT_CONFIG['collection'], (string)$msgId)) {
                    $totalSkipped++;
                    continue;
                }
                
                // Extract user info
                $userId = null;
                
                if (is_numeric($message['from_id'])) {
                    $userId = $message['from_id'];
                } elseif (isset($message['from_id']['user_id'])) {
                    $userId = $message['from_id']['user_id'];
                } elseif (isset($message['post_author'])) {
                    $userId = 'channel_' . $message['post_author'];
                } elseif (isset($message['peer_id']['channel_id'])) {
                    $userId = 'channel_' . $message['peer_id']['channel_id'];
                }
                
                if (!$userId) {
                    continue;
                }
                
                // Get user info
                try {
                    $userInfo = $MadelineProto->getInfo($userId);
                    $username = $userInfo['User']['username'] ?? null;
                    $firstName = $userInfo['User']['first_name'] ?? '';
                    $lastName = $userInfo['User']['last_name'] ?? '';
                    $fullName = trim("$firstName $lastName");
                    
                    if (empty($fullName) && $username) {
                        $fullName = "@$username";
                    }
                    
                    if (empty($fullName)) {
                        $fullName = "Weltenbibliothek";
                    }
                } catch (Exception $e) {
                    $username = null;
                    $firstName = '';
                    $lastName = '';
                    $fullName = "Weltenbibliothek";
                }
                
                $text = $message['message'] ?? '';
                $date = $message['date'] ?? time();
                
                // Prepare Firestore data
                $firestoreData = [
                    'messageId' => (string)$msgId,
                    'text' => $text,
                    'from_id' => (string)$userId,
                    'from_name' => $fullName,
                    'telegramUsername' => $username,
                    'telegramFirstName' => $firstName,
                    'telegramLastName' => $lastName,
                    'date' => $date,
                    'source' => 'telegram',
                    'edited' => false,
                    'deleted' => false,
                    'mediaUrl' => null,
                    'mediaType' => null,
                    'ftpPath' => null,
                ];
                
                // Handle media if present - ALLE Medien gehen nach /chat/
                if (isset($message['media'])) {
                    try {
                        $tempFile = sys_get_temp_dir() . "/chat_media_{$msgId}";
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
                                } elseif (strpos($mimeType, 'audio') !== false || 
                                          strpos($mimeType, 'ogg') !== false ||
                                          strpos($mimeType, 'mpeg') !== false) {
                                    $mediaType = 'audio';
                                    $fileExt = '.mp3';
                                } else {
                                    $mediaType = 'document';
                                    $fileExt = '.pdf';
                                }
                            }
                        }
                        
                        // Erstelle Dateinamen basierend auf Telegram-Titel
                        if ($originalFileName && !empty($originalFileName)) {
                            // Verwende Original-Dateinamen aus Telegram
                            $cleanFileName = preg_replace('/[^a-zA-Z0-9_\-äöüÄÖÜß\.]/', '_', $originalFileName);
                            $uniqueFilename = $cleanFileName;
                        } else {
                            // Fallback: Verwende Nachrichtentext als Dateiname (erste 50 Zeichen)
                            $textSnippet = substr($text, 0, 50);
                            $cleanText = preg_replace('/[^a-zA-Z0-9_\-äöüÄÖÜß]/', '_', $textSnippet);
                            $cleanText = trim($cleanText, '_');
                            
                            if (!empty($cleanText)) {
                                $uniqueFilename = $cleanText . "_{$msgId}{$fileExt}";
                            } else {
                                // Letzter Fallback: chat_<messageId>.<ext>
                                $uniqueFilename = "chat_{$msgId}{$fileExt}";
                            }
                        }
                        
                        // Begrenze Dateinamen-Länge auf 200 Zeichen
                        if (strlen($uniqueFilename) > 200) {
                            $nameWithoutExt = pathinfo($uniqueFilename, PATHINFO_FILENAME);
                            $extension = pathinfo($uniqueFilename, PATHINFO_EXTENSION);
                            $uniqueFilename = substr($nameWithoutExt, 0, 190) . "_{$msgId}." . $extension;
                        }
                        
                        // WICHTIG: Alle Chat-Medien → /chat/ Ordner
                        $ftpPath = "{$CHAT_CONFIG['ftpFolder']}{$uniqueFilename}";
                        $mediaUrl = uploadToFTP($tempFile, $ftpPath);
                        
                        if ($mediaUrl) {
                            $firestoreData['mediaUrl'] = $mediaUrl;
                            $firestoreData['mediaType'] = $mediaType;
                            $firestoreData['ftpPath'] = $ftpPath;
                            $firestoreData['originalFileName'] = $originalFileName;
                            echo "      📁 {$mediaType} → /chat/ ({$uniqueFilename})\n";
                        }
                        
                        if (file_exists($tempFile)) {
                            unlink($tempFile);
                        }
                    } catch (Exception $e) {
                        echo "      ⚠️  Medien-Fehler: " . $e->getMessage() . "\n";
                    }
                }
                
                // Save to Firestore
                if (saveToFirestore($CHAT_CONFIG['collection'], $firestoreData)) {
                    $totalSaved++;
                }
            }
            
            echo "   📊 Fortschritt: {$totalLoaded} geladen, {$totalSaved} gespeichert, {$totalSkipped} übersprungen\n";
            
            // Pause zwischen Batches
            usleep(100000); // 0.1 Sekunden
            
        } catch (Exception $e) {
            echo "   ⚠️  Fehler beim Laden: " . $e->getMessage() . "\n";
            break;
        }
    }
    
    echo "\n   ✅ ABGESCHLOSSEN: {$CHAT_CONFIG['name']}\n";
    echo "      Gesamt geladen: {$totalLoaded}\n";
    echo "      Neu gespeichert: {$totalSaved}\n";
    echo "      Duplikate übersprungen: {$totalSkipped}\n\n";
    
} catch (Exception $e) {
    echo "   ❌ Fehler: " . $e->getMessage() . "\n\n";
}

// ========================================
// ZUSAMMENFASSUNG
// ========================================

echo "════════════════════════════════════════════════════════════\n";
echo "📊 ZUSAMMENFASSUNG\n";
echo "════════════════════════════════════════════════════════════\n\n";
echo "   Chat-Gruppe: @Weltenbibliothekchat\n";
echo "   Gesamt geladen: {$totalLoaded} Nachrichten\n";
echo "   Neu gespeichert: {$totalSaved} Nachrichten\n";
echo "   Duplikate: {$totalSkipped} Nachrichten\n";
echo "   Medien-Ordner: /chat/\n\n";
echo "✅ Chat-Gruppe Daten-Import abgeschlossen!\n\n";

?>
