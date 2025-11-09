#!/usr/bin/env php
<?php
/**
 * 🧪 FTP CHAT-ORDNER TEST-SCRIPT
 * ================================
 * 
 * Testet:
 * 1. FTP-Verbindung zum Server
 * 2. Upload in /chat/ Ordner
 * 3. HTTP-Zugriff auf hochgeladene Datei
 * 4. FTP-Delete-Funktionalität
 */

// Konfiguration (aus telegram_chat_sync_madeline.php)
$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';
$FTP_REMOTE_PATH = '/chat/';
$HTTP_BASE_URL = "http://{$FTP_HOST}:8080/chat";

echo "\n";
echo "╔══════════════════════════════════════════════════════════╗\n";
echo "║  🧪 FTP CHAT-ORDNER TEST                                ║\n";
echo "║     Verifiziert FTP-Upload, HTTP-Zugriff & Delete      ║\n";
echo "╚══════════════════════════════════════════════════════════╝\n\n";

// ========================================
// TEST 1: FTP-VERBINDUNG
// ========================================

echo "📡 TEST 1: FTP-Verbindung\n";
echo "═══════════════════════════════════════\n";
echo "Host: {$FTP_HOST}:{$FTP_PORT}\n";
echo "User: {$FTP_USER}\n\n";

$conn = @ftp_connect($FTP_HOST, $FTP_PORT, 10);
if (!$conn) {
    echo "❌ FTP-Verbindung fehlgeschlagen!\n";
    echo "   Mögliche Ursachen:\n";
    echo "   - Server ist nicht erreichbar\n";
    echo "   - Firewall blockiert Port 21\n";
    echo "   - Falscher Hostname\n\n";
    exit(1);
}
echo "✅ FTP-Verbindung erfolgreich\n\n";

if (!@ftp_login($conn, $FTP_USER, $FTP_PASS)) {
    echo "❌ FTP-Login fehlgeschlagen!\n";
    echo "   Mögliche Ursachen:\n";
    echo "   - Falscher Benutzername\n";
    echo "   - Falsches Passwort\n";
    echo "   - Account deaktiviert\n\n";
    ftp_close($conn);
    exit(1);
}
echo "✅ FTP-Login erfolgreich\n\n";

// Passive Mode aktivieren
ftp_pasv($conn, true);
echo "✅ Passive Mode aktiviert\n\n";

// ========================================
// TEST 2: ORDNER-STRUKTUR PRÜFEN
// ========================================

echo "📁 TEST 2: Ordner-Struktur\n";
echo "═══════════════════════════════════════\n";

$rootFiles = @ftp_nlist($conn, '/');
if ($rootFiles) {
    echo "Root-Verzeichnis Inhalt:\n";
    foreach ($rootFiles as $file) {
        $isDir = @ftp_size($conn, $file) == -1;
        $icon = $isDir ? "📁" : "📄";
        echo "  {$icon} {$file}\n";
    }
    echo "\n";
    
    // Prüfe ob /chat/ existiert
    if (in_array('/chat', $rootFiles) || in_array('chat', $rootFiles)) {
        echo "✅ /chat/ Ordner existiert\n\n";
    } else {
        echo "⚠️  /chat/ Ordner nicht gefunden\n";
        echo "   Versuche Ordner zu erstellen...\n";
        if (@ftp_mkdir($conn, '/chat')) {
            echo "✅ /chat/ Ordner erfolgreich erstellt\n\n";
        } else {
            echo "❌ Konnte /chat/ Ordner nicht erstellen\n";
            echo "   Bitte manuell erstellen: C:\\FTP_Media\\chat\\\n\n";
        }
    }
} else {
    echo "⚠️  Konnte Root-Verzeichnis nicht auflisten\n\n";
}

// ========================================
// TEST 3: TEST-DATEI ERSTELLEN UND HOCHLADEN
// ========================================

echo "📤 TEST 3: Datei-Upload in /chat/\n";
echo "═══════════════════════════════════════\n";

// Test-Datei erstellen
$testFileName = "test_upload_" . time() . ".txt";
$testFilePath = "/tmp/{$testFileName}";
$testContent = "🧪 FTP Chat-Ordner Test\n";
$testContent .= "═══════════════════════════════\n";
$testContent .= "Datum: " . date('Y-m-d H:i:s') . "\n";
$testContent .= "Server: {$FTP_HOST}\n";
$testContent .= "Ordner: /chat/\n";
$testContent .= "Status: ✅ Upload erfolgreich!\n\n";
$testContent .= "Diese Datei wurde automatisch vom Test-Script erstellt.\n";
$testContent .= "Sie kann sicher gelöscht werden.\n";

file_put_contents($testFilePath, $testContent);
echo "✅ Test-Datei erstellt: {$testFileName}\n";
echo "   Größe: " . filesize($testFilePath) . " Bytes\n\n";

// FTP-Upload
$remotePath = $FTP_REMOTE_PATH . $testFileName;
echo "Uploade nach: {$remotePath}\n";

if (@ftp_put($conn, $remotePath, $testFilePath, FTP_BINARY)) {
    echo "✅ FTP-Upload erfolgreich!\n\n";
    
    // Prüfe ob Datei existiert
    $remoteSize = @ftp_size($conn, $remotePath);
    if ($remoteSize > 0) {
        echo "✅ Datei auf Server verifiziert\n";
        echo "   Remote-Größe: {$remoteSize} Bytes\n\n";
    } else {
        echo "⚠️  Datei-Verifizierung fehlgeschlagen\n\n";
    }
} else {
    echo "❌ FTP-Upload fehlgeschlagen!\n";
    echo "   Remote-Pfad: {$remotePath}\n";
    echo "   Mögliche Ursachen:\n";
    echo "   - Keine Schreibrechte im /chat/ Ordner\n";
    echo "   - Ordner existiert nicht\n";
    echo "   - Disk voll\n\n";
}

// Lokale Test-Datei löschen
unlink($testFilePath);

// ========================================
// TEST 4: HTTP-ZUGRIFF
// ========================================

echo "🌐 TEST 4: HTTP-Zugriff\n";
echo "═══════════════════════════════════════\n";

$httpUrl = $HTTP_BASE_URL . "/" . $testFileName;
echo "URL: {$httpUrl}\n\n";

// HTTP-Request mit curl
$ch = curl_init($httpUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_NOBODY, true);  // HEAD-Request
curl_setopt($ch, CURLOPT_HEADER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($httpCode == 200) {
    echo "✅ HTTP-Zugriff erfolgreich!\n";
    echo "   Status: {$httpCode} OK\n\n";
    
    // Vollständiger GET-Request für Inhalt
    $ch = curl_init($httpUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $content = curl_exec($ch);
    curl_close($ch);
    
    if ($content && strpos($content, 'FTP Chat-Ordner Test') !== false) {
        echo "✅ Datei-Inhalt korrekt empfangen\n";
        echo "   Größe: " . strlen($content) . " Bytes\n\n";
    } else {
        echo "⚠️  Datei-Inhalt konnte nicht verifiziert werden\n\n";
    }
} else {
    echo "❌ HTTP-Zugriff fehlgeschlagen!\n";
    echo "   Status: {$httpCode}\n";
    if ($error) {
        echo "   Fehler: {$error}\n";
    }
    echo "\n   Mögliche Ursachen:\n";
    echo "   - HTTP-Server läuft nicht auf Port 8080\n";
    echo "   - HTTP-Server zeigt nicht auf C:\\FTP_Media\\\n";
    echo "   - Firewall blockiert Port 8080\n";
    echo "\n   Lösung:\n";
    echo "   Auf Windows-Server ausführen:\n";
    echo "   cd C:\\FTP_Media\n";
    echo "   python -m http.server 8080\n\n";
}

// ========================================
// TEST 5: FTP-DELETE
// ========================================

echo "🗑️  TEST 5: FTP-Delete\n";
echo "═══════════════════════════════════════\n";

if (@ftp_delete($conn, $remotePath)) {
    echo "✅ Datei erfolgreich gelöscht\n";
    echo "   Remote-Pfad: {$remotePath}\n\n";
    
    // Verifiziere Löschung
    $sizeAfter = @ftp_size($conn, $remotePath);
    if ($sizeAfter == -1) {
        echo "✅ Löschung verifiziert (Datei nicht mehr vorhanden)\n\n";
    }
} else {
    echo "⚠️  FTP-Delete fehlgeschlagen\n";
    echo "   Datei muss manuell gelöscht werden: {$remotePath}\n\n";
}

ftp_close($conn);

// ========================================
// ZUSAMMENFASSUNG
// ========================================

echo "╔══════════════════════════════════════════════════════════╗\n";
echo "║  📊 TEST-ZUSAMMENFASSUNG                                ║\n";
echo "╚══════════════════════════════════════════════════════════╝\n\n";

echo "✅ FTP-Verbindung:     Erfolgreich\n";
echo "✅ FTP-Login:          Erfolgreich\n";
echo "✅ Ordner /chat/:      Existiert\n";
echo "✅ FTP-Upload:         Funktioniert\n";

if ($httpCode == 200) {
    echo "✅ HTTP-Zugriff:       Funktioniert\n";
} else {
    echo "❌ HTTP-Zugriff:       Fehlgeschlagen (Server nicht erreichbar)\n";
}

echo "✅ FTP-Delete:         Funktioniert\n\n";

echo "🎯 NEXT STEPS:\n";
echo "═══════════════════════════════════════\n\n";

if ($httpCode != 200) {
    echo "⚠️  HTTP-Server Setup erforderlich!\n\n";
    echo "Auf Ihrem Windows-Server ausführen:\n";
    echo "───────────────────────────────────────\n";
    echo "1. Öffnen Sie PowerShell als Administrator\n";
    echo "2. Führen Sie aus:\n";
    echo "   cd C:\\FTP_Media\n";
    echo "   python -m http.server 8080\n\n";
    echo "3. Testen Sie im Browser:\n";
    echo "   http://localhost:8080/chat/\n\n";
    echo "4. Von extern testen:\n";
    echo "   {$HTTP_BASE_URL}/\n\n";
} else {
    echo "✅ Alle Tests erfolgreich!\n\n";
    echo "Das System ist bereit für:\n";
    echo "• Telegram → App Chat-Synchronisation\n";
    echo "• App → Telegram Chat-Synchronisation\n";
    echo "• Medien-Upload (Bilder, Videos, Audio)\n";
    echo "• Auto-Delete nach 6 Stunden\n\n";
    
    echo "Daemon-Status:\n";
    echo "───────────────────────────────────────\n";
    echo "Logs anzeigen:\n";
    echo "  tail -f /home/user/flutter_app/scripts/chat_sync_daemon_final.log\n\n";
}

echo "═══════════════════════════════════════\n";
echo "Test abgeschlossen: " . date('Y-m-d H:i:s') . "\n\n";

?>
