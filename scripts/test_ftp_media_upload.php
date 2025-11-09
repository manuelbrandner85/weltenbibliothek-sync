<?php

$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Jolene2305';
$FTP_PASS = 'Piraten3007';
$FTP_REMOTE_PATH = '/chat/';

// Create a small test image
$testFile = sys_get_temp_dir() . '/test_image.jpg';
$img = imagecreatetruecolor(100, 100);
$color = imagecolorallocate($img, 255, 0, 0);
imagefilledrectangle($img, 0, 0, 100, 100, $color);
imagejpeg($img, $testFile, 90);
imagedestroy($img);

echo "Test-Datei erstellt: $testFile (" . filesize($testFile) . " bytes)\n\n";

// Test FTP upload
echo "🔗 Verbinde zu FTP...\n";
$conn = ftp_connect($FTP_HOST, $FTP_PORT, 10); // 10 seconds timeout
if (!$conn) {
    die("❌ FTP Verbindung fehlgeschlagen\n");
}
echo "✅ FTP verbunden\n";

echo "🔐 Login...\n";
if (!ftp_login($conn, $FTP_USER, $FTP_PASS)) {
    ftp_close($conn);
    die("❌ FTP Login fehlgeschlagen\n");
}
echo "✅ Login erfolgreich\n";

// Test passive mode
echo "📡 Aktiviere Passive Mode...\n";
if (ftp_pasv($conn, true)) {
    echo "✅ Passive Mode aktiviert\n";
} else {
    echo "⚠️  Passive Mode Warnung\n";
}

// Check current directory
$pwd = ftp_pwd($conn);
echo "📁 Aktuelles Verzeichnis: $pwd\n";

// Try to change to /chat/ directory
echo "📂 Wechsle zu /chat/...\n";
if (ftp_chdir($conn, '/chat/')) {
    echo "✅ Verzeichnis /chat/ existiert\n";
} else {
    echo "❌ Verzeichnis /chat/ nicht gefunden\n";
    echo "📝 Versuche Verzeichnis zu erstellen...\n";
    if (@ftp_mkdir($conn, '/chat/')) {
        echo "✅ Verzeichnis /chat/ erstellt\n";
    } else {
        echo "❌ Konnte /chat/ nicht erstellen\n";
    }
}

// Upload test file
$remotePath = '/chat/test_upload_' . time() . '.jpg';
echo "\n📤 Uploade Test-Datei zu: $remotePath\n";
echo "   Größe: " . filesize($testFile) . " bytes\n";

if (ftp_put($conn, $remotePath, $testFile, FTP_BINARY)) {
    echo "✅ Upload erfolgreich!\n";
    
    // Verify file exists
    $fileList = ftp_nlist($conn, '/chat/');
    echo "\n📋 Dateien in /chat/:\n";
    foreach ($fileList as $file) {
        echo "   - $file\n";
    }
    
    // Try to delete the test file
    echo "\n🗑️  Lösche Test-Datei...\n";
    if (ftp_delete($conn, $remotePath)) {
        echo "✅ Test-Datei gelöscht\n";
    } else {
        echo "⚠️  Konnte Test-Datei nicht löschen\n";
    }
} else {
    echo "❌ Upload fehlgeschlagen\n";
    echo "   FTP Error: " . error_get_last()['message'] . "\n";
}

ftp_close($conn);
unlink($testFile);

echo "\n✅ Test abgeschlossen\n";
