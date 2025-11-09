<?php

// CORRECT CREDENTIALS from daemon
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';  // CORRECTED
$FTP_PASS = 'Jolene2305';         // CORRECTED

// Create a simple test file
$testFile = sys_get_temp_dir() . '/test_media.txt';
file_put_contents($testFile, 'FTP Media Test - ' . date('Y-m-d H:i:s'));
echo "Test-Datei erstellt: $testFile (" . filesize($testFile) . " bytes)\n\n";

// Test FTP upload
echo "🔗 Verbinde zu FTP...\n";
$conn = ftp_connect($FTP_HOST, $FTP_PORT, 10);
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
    
    // List files
    $files = ftp_nlist($conn, '.');
    echo "\n📋 Dateien in /chat/:\n";
    if ($files && count($files) > 0) {
        foreach ($files as $file) {
            echo "   - $file\n";
        }
    } else {
        echo "   (leer)\n";
    }
} else {
    echo "❌ Verzeichnis /chat/ nicht gefunden\n";
}

// Upload test file
$remotePath = '/chat/test_media_' . time() . '.txt';
echo "\n📤 Uploade Test-Datei zu: $remotePath\n";
echo "   Größe: " . filesize($testFile) . " bytes\n";

if (ftp_put($conn, $remotePath, $testFile, FTP_BINARY)) {
    echo "✅ Upload erfolgreich!\n";
    
    // Verify file size
    $size = ftp_size($conn, $remotePath);
    echo "   Remote Dateigröße: $size bytes\n";
    
    // Build HTTP URL
    $httpUrl = "http://{$FTP_HOST}:8080/chat/" . basename($remotePath);
    echo "   HTTP URL: $httpUrl\n";
    
    // Try to delete the test file
    echo "\n🗑️  Lösche Test-Datei...\n";
    if (ftp_delete($conn, $remotePath)) {
        echo "✅ Test-Datei gelöscht\n";
    } else {
        echo "⚠️  Konnte Test-Datei nicht löschen\n";
    }
} else {
    echo "❌ Upload fehlgeschlagen\n";
    $error = error_get_last();
    if ($error) {
        echo "   Error: " . $error['message'] . "\n";
    }
}

ftp_close($conn);
unlink($testFile);

echo "\n✅ Test abgeschlossen\n";
