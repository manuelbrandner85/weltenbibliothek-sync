#!/usr/bin/env python3
"""
Weltenbibliothek Media HTTP Server
===================================

Dieser Server liefert die hochgeladenen Telegram-Medien über HTTP aus.

Funktionen:
- Läuft auf Port 8080
- Serviert Dateien aus dem FTP-Upload-Verzeichnis
- CORS-Header für Flutter Web-Zugriff
- Automatisches Logging
- Unterstützt: Bilder, Videos, PDFs, Audio

Installation auf Windows:
1. Python 3 installieren (python.org)
2. Dieses Script nach C:\Weltenbibliothek\media_http_server.py kopieren
3. FTP_ROOT_PATH anpassen (Zeile 30)
4. Script ausführen: python media_http_server.py

Als Windows-Dienst (optional):
- NSSM verwenden: nssm install WeltenbibliothekMedia
- Pfad: C:\Python\python.exe
- Arguments: C:\Weltenbibliothek\media_http_server.py
"""

import http.server
import socketserver
import os
import sys
from datetime import datetime

# ========================================
# KONFIGURATION - HIER ANPASSEN!
# ========================================

# WICHTIG: Passe diesen Pfad an dein FTP-Upload-Verzeichnis an!
# Beispiele:
#   Windows: "C:\\xlight\\Weltenbibliothek"
#   Windows: "D:\\FTP\\uploads"
FTP_ROOT_PATH = "C:\\xlight\\Weltenbibliothek"  # <-- HIER ANPASSEN!

# Server Port (Standard: 8080)
PORT = 8080

# Server Host (0.0.0.0 = alle Netzwerk-Interfaces)
HOST = "0.0.0.0"

# ========================================
# HTTP SERVER MIT CORS
# ========================================

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP Request Handler mit CORS-Unterstützung"""
    
    def __init__(self, *args, **kwargs):
        # Setze das Root-Verzeichnis
        super().__init__(*args, directory=FTP_ROOT_PATH, **kwargs)
    
    def end_headers(self):
        """Füge CORS-Header hinzu"""
        # CORS für alle Origins erlauben
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        
        # Cache-Control für bessere Performance
        self.send_header('Cache-Control', 'public, max-age=86400')
        
        # Content-Type basierend auf Dateiendung
        if self.path.endswith('.jpg') or self.path.endswith('.jpeg'):
            self.send_header('Content-Type', 'image/jpeg')
        elif self.path.endswith('.png'):
            self.send_header('Content-Type', 'image/png')
        elif self.path.endswith('.mp4'):
            self.send_header('Content-Type', 'video/mp4')
        elif self.path.endswith('.pdf'):
            self.send_header('Content-Type', 'application/pdf')
        elif self.path.endswith('.mp3'):
            self.send_header('Content-Type', 'audio/mpeg')
        
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS preflight"""
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom logging mit Timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        sys.stdout.write(f"[{timestamp}] {format % args}\n")
        sys.stdout.flush()

# ========================================
# SERVER STARTEN
# ========================================

def main():
    """Hauptfunktion - Startet den HTTP Server"""
    
    print("=" * 70)
    print("🚀 WELTENBIBLIOTHEK MEDIA HTTP SERVER")
    print("=" * 70)
    print()
    
    # Prüfe ob FTP-Verzeichnis existiert
    if not os.path.exists(FTP_ROOT_PATH):
        print(f"❌ FEHLER: FTP-Verzeichnis nicht gefunden!")
        print(f"   Pfad: {FTP_ROOT_PATH}")
        print()
        print("LÖSUNG:")
        print("1. Öffne diese Datei in einem Texteditor")
        print("2. Ändere FTP_ROOT_PATH (Zeile 30) zu deinem FTP-Upload-Verzeichnis")
        print("3. Speichere und starte das Script erneut")
        print()
        input("Drücke ENTER zum Beenden...")
        sys.exit(1)
    
    print(f"📁 FTP Root: {FTP_ROOT_PATH}")
    print(f"🌐 Server:   http://{HOST}:{PORT}")
    print(f"🌍 Extern:   http://Weltenbibliothek.ddns.net:{PORT}")
    print()
    
    # Liste vorhandene Verzeichnisse
    try:
        subdirs = [d for d in os.listdir(FTP_ROOT_PATH) if os.path.isdir(os.path.join(FTP_ROOT_PATH, d))]
        if subdirs:
            print("📂 Gefundene Verzeichnisse:")
            for subdir in subdirs:
                file_count = len([f for f in os.listdir(os.path.join(FTP_ROOT_PATH, subdir)) if os.path.isfile(os.path.join(FTP_ROOT_PATH, subdir, f))])
                print(f"   - /{subdir}/ ({file_count} Dateien)")
        else:
            print("📂 Noch keine Unterverzeichnisse vorhanden")
    except Exception as e:
        print(f"⚠️  Warnung beim Lesen der Verzeichnisse: {e}")
    
    print()
    print("=" * 70)
    print("✅ Server gestartet! Drücke CTRL+C zum Beenden.")
    print("=" * 70)
    print()
    
    # Starte Server
    try:
        with socketserver.TCPServer((HOST, PORT), CORSHTTPRequestHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n⏹️  Server wird beendet...")
        print("✅ Server gestoppt.")
    except OSError as e:
        if e.errno == 10048:  # Port already in use
            print(f"\n❌ FEHLER: Port {PORT} wird bereits verwendet!")
            print()
            print("LÖSUNG:")
            print(f"1. Stoppe den Prozess, der Port {PORT} verwendet")
            print("2. ODER: Ändere PORT in diesem Script (Zeile 33)")
            print()
            input("Drücke ENTER zum Beenden...")
        else:
            print(f"\n❌ FEHLER: {e}")
            input("Drücke ENTER zum Beenden...")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unerwarteter Fehler: {e}")
        import traceback
        traceback.print_exc()
        input("Drücke ENTER zum Beenden...")
        sys.exit(1)

if __name__ == "__main__":
    main()
