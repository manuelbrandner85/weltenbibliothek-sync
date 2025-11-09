#!/usr/bin/env php
<?php
/**
 * Test: Telegram-Nachrichten direkt abrufen
 */

require __DIR__ . '/../../madeline_backend/vendor/autoload.php';

use danog\MadelineProto\API;
use danog\MadelineProto\Logger;
use danog\MadelineProto\Settings;

echo "🔍 Teste Telegram-Nachrichten-Abruf...\n\n";

// MadelineProto initialisieren
$settings = new Settings;
$settings->getLogger()->setLevel(Logger::NOTICE);
$settings->getAppInfo()
    ->setApiId(25697241)
    ->setApiHash('19cfb3819684da4571a91874ee22603a');

$MadelineProto = new API(__DIR__ . '/../../madeline_backend/session.madeline', $settings);
$MadelineProto->start();

echo "✅ MadelineProto verbunden\n\n";

// Chat-ID
$CHAT_USERNAME = '@Weltenbibliothekchat';
$chatInfo = $MadelineProto->getInfo($CHAT_USERNAME);
$chatId = $chatInfo['bot_api_id'];

echo "✅ Chat gefunden: {$CHAT_USERNAME}\n";
echo "   Chat ID: {$chatId}\n\n";

// Letzte 10 Nachrichten abrufen
echo "📥 Letzte 10 Nachrichten:\n";
echo "════════════════════════════════════════\n\n";

try {
    $messages = $MadelineProto->messages->getHistory([
        'peer' => $CHAT_USERNAME,
        'limit' => 10,
        'offset_id' => 0,
        'offset_date' => 0,
        'add_offset' => 0,
        'max_id' => 0,
        'min_id' => 0,
        'hash' => 0
    ]);
    
    if (isset($messages['messages']) && count($messages['messages']) > 0) {
        $count = 0;
        foreach ($messages['messages'] as $msg) {
            if (isset($msg['message']) && $msg['message'] !== '') {
                $count++;
                $msgId = $msg['id'] ?? 'N/A';
                $date = isset($msg['date']) ? date('Y-m-d H:i:s', $msg['date']) : 'N/A';
                $text = $msg['message'];
                $from = 'N/A';
                
                if (isset($msg['from_id'])) {
                    if (isset($msg['from_id']['user_id'])) {
                        $userId = $msg['from_id']['user_id'];
                        try {
                            $userInfo = $MadelineProto->getInfo($userId);
                            $from = $userInfo['User']['username'] ?? $userInfo['User']['first_name'] ?? "User_{$userId}";
                        } catch (Exception $e) {
                            $from = "User_{$userId}";
                        }
                    }
                }
                
                echo "📨 Nachricht #{$count}\n";
                echo "   ID: {$msgId}\n";
                echo "   Von: {$from}\n";
                echo "   Datum: {$date}\n";
                echo "   Text: " . substr($text, 0, 100) . "\n";
                echo "\n";
            }
        }
        
        if ($count === 0) {
            echo "⚠️  Keine Text-Nachrichten gefunden (nur Medien/System-Nachrichten)\n\n";
        }
    } else {
        echo "⚠️  Keine Nachrichten gefunden\n\n";
    }
    
} catch (Exception $e) {
    echo "❌ Fehler beim Abrufen: " . $e->getMessage() . "\n\n";
}

echo "════════════════════════════════════════\n";
echo "Test abgeschlossen: " . date('Y-m-d H:i:s') . "\n\n";

?>
