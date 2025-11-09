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

echo "Abrufen der letzten Nachricht...\n\n";

$history = $MadelineProto->messages->getHistory([
    'peer' => '@Weltenbibliothekchat',
    'limit' => 1,
]);

$message = $history['messages'][0] ?? null;

if ($message) {
    echo "=== MESSAGE STRUCTURE ===\n";
    echo json_encode($message, JSON_PRETTY_PRINT);
} else {
    echo "Keine Nachricht gefunden\n";
}
