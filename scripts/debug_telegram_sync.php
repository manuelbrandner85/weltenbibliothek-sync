<?php
use danog\MadelineProto\Settings;
use danog\MadelineProto\Settings\AppInfo;

require_once '/opt/weltenbibliothek/backend/vendor/autoload.php';

$settings = new Settings;
$appInfo = new AppInfo;
$appInfo->setApiId(25697241);
$appInfo->setApiHash('19cfb3819684da4571a91874ee22603a');
$settings->setAppInfo($appInfo);

$MadelineProto = new \danog\MadelineProto\API('session.madeline', $settings);
$MadelineProto->start();

echo "🔍 Abrufen der letzten 10 Nachrichten...\n\n";

$history = $MadelineProto->messages->getHistory([
    'peer' => '@Weltenbibliothekchat',
    'limit' => 10,
]);

echo "Anzahl Nachrichten: " . count($history['messages']) . "\n\n";

$lastMessageId = 0;
foreach ($history['messages'] as $message) {
    $msgId = $message['id'];
    
    echo "Message ID: {$msgId}\n";
    echo "LastMessageId: {$lastMessageId}\n";
    echo "Condition ($msgId <= $lastMessageId): " . ($msgId <= $lastMessageId ? 'TRUE (SKIP)' : 'FALSE (PROCESS)') . "\n";
    
    // Check user info
    $userId = $message['from_id']['user_id'] ?? null;
    echo "User ID: " . ($userId ?? 'NULL') . "\n";
    
    $text = $message['message'] ?? '';
    echo "Text: " . substr($text, 0, 50) . "\n";
    
    echo "\n---\n\n";
}
