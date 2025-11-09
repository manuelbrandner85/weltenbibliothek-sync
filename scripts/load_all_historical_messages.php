<?php
/**
 * 📥 EINMALIGER HISTORISCHER DATEN-LOADER
 * ========================================
 * 
 * Lädt ALLE historischen Nachrichten von 5 Telegram-Kanälen:
 * 
 * 1. @WeltenbibliothekPDF        → pdf_messages
 * 2. @weltenbibliothekbilder     → bilder_messages
 * 3. @WeltenbibliothekWachauf    → wachauf_messages
 * 4. @ArchivWeltenBibliothek     → archiv_messages
 * 5. @WeltenbibliothekHoerbuch   → hoerbuch_messages
 * 
 * WICHTIG: NUR Content-Kanäle (READ-ONLY)
 * Chat-Kanal (@Weltenbibliothekchat) wird NICHT geladen!
 * 
 * Features:
 * ✅ Lädt ALLE Nachrichten (unbegrenzt)
 * ✅ Speichert Telegram-Benutzernamen
 * ✅ Speichert Medien-URLs (von FTP-Server)
 * ✅ Verhindert Duplikate
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\Settings;
use danog\MadelineProto\Settings\AppInfo;

// ========================================
// CONTENT-KANÄLE KONFIGURATION (NUR READ-ONLY)
// ========================================

$CHANNELS = [
    [
        'name' => 'PDFs',
        'username' => '@WeltenbibliothekPDF',
        'collection' => 'pdf_messages',
        'ftpFolder' => '/pdfs/',  // Alle Medien aus PDF-Kanal → /pdfs/
    ],
    [
        'name' => 'Bilder',
        'username' => '@weltenbibliothekbilder',
        'collection' => 'bilder_messages',
        'ftpFolder' => '/images/',  // Alle Medien aus Bilder-Kanal → /images/
    ],
    [
        'name' => 'Wach Auf',
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

// WICHTIG: Laden ALLER Nachrichten (keine Begrenzung)
$MAX_MESSAGES_PER_CHANNEL = 10000;  // Sehr hohe Grenze für vollständige Historie

echo "\n";
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║  📥 HISTORISCHER DATEN-LOADER (Einmalig)                 ║\n";
echo "║     Lädt ALLE Nachrichten von 5 Content-Kanälen          ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

echo "⚠️  HINWEIS: Dieser Vorgang kann mehrere Minuten dauern!\n";
echo "            Lädt bis zu {$MAX_MESSAGES_PER_CHANNEL} Nachrichten pro Kanal.\n\n";

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
    
    // Escape data for JSON
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
    
    # Decode base64 data
    data_json = base64.b64decode('$dataBase64').decode('utf-8')
    data = json.loads(data_json)

    # Add server timestamp
    data['timestamp'] = firestore.SERVER_TIMESTAMP

    # Save to Firestore
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

# Query für Nachricht mit dieser ID
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
// HAUPTPROGRAMM: Lade ALLE historischen Nachrichten
// ========================================

$totalLoaded = 0;
$totalSaved = 0;
$totalSkipped = 0;

foreach ($CHANNELS as $channel) {
    echo "════════════════════════════════════════════════════════════\n";
    echo "📥 LADE: {$channel['name']} ({$channel['username']})\n";
    echo "════════════════════════════════════════════════════════════\n\n";
    
    try {
        // Resolve Channel-ID
        $peer = $MadelineProto->getInfo($channel['username']);
        $chatId = $peer['bot_api_id'];
        
        echo "   ✅ Channel-ID: {$chatId}\n";
        echo "   📊 Lade historische Nachrichten...\n\n";
        
        $channelLoaded = 0;
        $channelSaved = 0;
        $channelSkipped = 0;
        $offsetId = 0;
        
        // Lade Nachrichten in Batches (100 pro Request)
        while ($channelLoaded < $MAX_MESSAGES_PER_CHANNEL) {
            try {
                $history = $MadelineProto->messages->getHistory([
                    'peer' => $channel['username'],
                    'limit' => 100,
                    'offset_id' => $offsetId,
                ]);
                
                $messages = $history['messages'];
                
                // Keine weiteren Nachrichten verfügbar
                if (empty($messages)) {
                    echo "   ✅ Alle verfügbaren Nachrichten geladen\n";
                    break;
                }
                
                $channelLoaded += count($messages);
                
                foreach ($messages as $message) {
                    $msgId = $message['id'];
                    
                    // Update offset für nächsten Batch
                    if ($msgId < $offsetId || $offsetId === 0) {
                        $offsetId = $msgId;
                    }
                    
                    // Prüfe ob Nachricht bereits existiert
                    if (messageExists($channel['collection'], (string)$msgId)) {
                        $channelSkipped++;
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
                        
                        // Fallback: Verwende Username wenn kein Name vorhanden
                        if (empty($fullName) && $username) {
                            $fullName = "@$username";
                        }
                        
                        // Letzter Fallback
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
                    
                    // Handle media if present
                    if (isset($message['media'])) {
                        try {
                            $tempFile = sys_get_temp_dir() . "/media_{$msgId}";
                            $MadelineProto->downloadToFile($message['media'], $tempFile);
                            
                            $mediaType = 'photo';
                            $fileExt = '.jpg';
                            $originalFileName = null;
                            
                            // Verwende den Kanal-spezifischen FTP-Ordner
                            $ftpFolder = $channel['ftpFolder'];
                            
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
                                    // Letzter Fallback: Message-ID
                                    $channelPrefix = str_replace(['@', 'Weltenbibliothek'], '', $channel['username']);
                                    $uniqueFilename = strtolower($channelPrefix) . "_{$msgId}{$fileExt}";
                                }
                            }
                            
                            // Begrenze Dateinamen-Länge auf 200 Zeichen
                            if (strlen($uniqueFilename) > 200) {
                                $nameWithoutExt = pathinfo($uniqueFilename, PATHINFO_FILENAME);
                                $extension = pathinfo($uniqueFilename, PATHINFO_EXTENSION);
                                $uniqueFilename = substr($nameWithoutExt, 0, 190) . "_{$msgId}." . $extension;
                            }
                            
                            // Upload to FTP im Kanal-spezifischen Ordner
                            $ftpPath = "{$ftpFolder}{$uniqueFilename}";
                            $mediaUrl = uploadToFTP($tempFile, $ftpPath);
                            
                            if ($mediaUrl) {
                                $firestoreData['mediaUrl'] = $mediaUrl;
                                $firestoreData['mediaType'] = $mediaType;
                                $firestoreData['ftpPath'] = $ftpPath;
                                $firestoreData['originalFileName'] = $originalFileName;
                                echo "      📁 {$mediaType} → {$ftpFolder} ({$uniqueFilename})\n";
                            }
                            
                            if (file_exists($tempFile)) {
                                unlink($tempFile);
                            }
                        } catch (Exception $e) {
                            // Ignore media errors, save text only
                            echo "      ⚠️  Medien-Fehler: " . $e->getMessage() . "\n";
                        }
                    }
                    
                    // Save to Firestore
                    if (saveToFirestore($channel['collection'], $firestoreData)) {
                        $channelSaved++;
                    }
                }
                
                echo "   📊 Fortschritt: {$channelLoaded} geladen, {$channelSaved} gespeichert, {$channelSkipped} übersprungen\n";
                
                // Pause zwischen Batches
                usleep(100000); // 0.1 Sekunden
                
            } catch (Exception $e) {
                echo "   ⚠️  Fehler beim Laden: " . $e->getMessage() . "\n";
                break;
            }
        }
        
        echo "\n   ✅ ABGESCHLOSSEN: {$channel['name']}\n";
        echo "      Gesamt geladen: {$channelLoaded}\n";
        echo "      Neu gespeichert: {$channelSaved}\n";
        echo "      Duplikate übersprungen: {$channelSkipped}\n\n";
        
        $totalLoaded += $channelLoaded;
        $totalSaved += $channelSaved;
        $totalSkipped += $channelSkipped;
        
    } catch (Exception $e) {
        echo "   ❌ Fehler: " . $e->getMessage() . "\n\n";
    }
}

// ========================================
// ZUSAMMENFASSUNG
// ========================================

echo "════════════════════════════════════════════════════════════\n";
echo "📊 ZUSAMMENFASSUNG\n";
echo "════════════════════════════════════════════════════════════\n\n";
echo "   Gesamt geladen:        {$totalLoaded} Nachrichten\n";
echo "   Neu gespeichert:       {$totalSaved} Nachrichten\n";
echo "   Duplikate übersprungen: {$totalSkipped} Nachrichten\n\n";
echo "✅ Historischer Daten-Import abgeschlossen!\n\n";

?>
