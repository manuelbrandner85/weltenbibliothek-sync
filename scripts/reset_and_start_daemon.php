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

echo "✅ MadelineProto verbunden\n";

// Get chat ID
$peer = $MadelineProto->getInfo('@Weltenbibliothekchat');
$chatId = $peer['bot_api_id'];
echo "✅ Chat ID: {$chatId}\n";

// Get LATEST message to set lastMessageId properly
$history = $MadelineProto->messages->getHistory([
    'peer' => '@Weltenbibliothekchat',
    'limit' => 1,
]);

$latestMsgId = $history['messages'][0]['id'] ?? 0;
echo "📌 Neueste Message ID: {$latestMsgId}\n";
echo "🔄 Daemon wird mit lastMessageId = {$latestMsgId} starten\n";
echo "   (Alle zukünftigen Nachrichten mit ID > {$latestMsgId} werden verarbeitet)\n\n";

echo "✅ Reset erfolgreich! Starte nun den Daemon...\n";
