#!/usr/bin/env php
<?php
/**
 * Erstellt /chat/ Ordner über FTP
 */

$FTP_HOST = 'Weltenbibliothek.ddns.net';
$FTP_PORT = 21;
$FTP_USER = 'Weltenbibliothek';
$FTP_PASS = 'Jolene2305';

echo "🔧 Erstelle /chat/ Ordner über FTP...\n\n";

$conn = ftp_connect($FTP_HOST, $FTP_PORT);
ftp_login($conn, $FTP_USER, $FTP_PASS);
ftp_pasv($conn, true);

// Versuche verschiedene Pfade
$paths = ['/chat', 'chat', './chat'];

foreach ($paths as $path) {
    echo "Versuche: {$path}\n";
    if (@ftp_mkdir($conn, $path)) {
        echo "✅ Ordner erstellt: {$path}\n\n";
        
        // Versuche Berechtigungen zu setzen (chmod)
        if (@ftp_chmod($conn, 0777, $path)) {
            echo "✅ Berechtigungen gesetzt (777)\n\n";
        }
        
        ftp_close($conn);
        exit(0);
    }
}

echo "⚠️  Konnte Ordner nicht erstellen\n";
echo "   Bitte manuell auf dem Server erstellen:\n";
echo "   C:\\FTP_Media\\chat\\\n\n";

ftp_close($conn);
?>
