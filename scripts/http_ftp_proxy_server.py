#!/usr/bin/env python3
"""
HTTP FTP Proxy Server für Flutter-Kompatibilität
Stellt FTP-Dateien über HTTP zur Verfügung

WARUM?
- Flutter kann nicht direkt FTP-URLs abspielen
- Dieser Server macht FTP-Dateien über HTTP verfügbar

VERWENDUNG:
1. Setzen Sie das Xlight FTP Home Directory als Root
2. python3 http_ftp_proxy_server.py
3. Server läuft auf Port 8080
4. Flutter-App kann dann http://host:8080/videos/file.mp4 abrufen

VORAUSSETZUNG:
- Xlight FTP Home Directory: C:\weltenbibliothek\ (Windows)
- Oder /weltenbibliothek/ (Linux)
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

# ========== KONFIGURATION ==========

# Port für HTTP-Server
PORT = 8080

# FTP Home Directory (Xlight Weltenbibliothek)
# WICHTIG: Passen Sie das an Ihre Xlight-Konfiguration an!
FTP_HOME_DIRS = [
    r"C:\weltenbibliothek",  # Windows
    "/weltenbibliothek",      # Linux
    r"C:\Users\Administrator\weltenbibliothek",  # Alternative Windows
]

# ========== HTTP REQUEST HANDLER ==========

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP Request Handler mit CORS-Support für Flutter"""
    
    def end_headers(self):
        """Füge CORS-Header hinzu"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Range')
        self.send_header('Access-Control-Expose-Headers', 'Content-Length, Content-Range')
        self.send_header('Cache-Control', 'public, max-age=3600')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests"""
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom Logging mit Emojis"""
        print(f"📥 [{self.address_string()}] {format % args}")

# ========== MAIN ==========

def find_ftp_home():
    """Finde FTP Home Directory automatisch"""
    for directory in FTP_HOME_DIRS:
        if os.path.exists(directory):
            return directory
    return None

def main():
    """Starte HTTP-Proxy-Server"""
    print("=" * 60)
    print("🌐 HTTP FTP Proxy Server für Flutter")
    print("=" * 60)
    
    # Finde FTP Home Directory
    ftp_home = find_ftp_home()
    
    if not ftp_home:
        print("\n❌ FEHLER: FTP Home Directory nicht gefunden!")
        print("\n📁 Überprüfen Sie folgende Pfade:")
        for directory in FTP_HOME_DIRS:
            print(f"   - {directory}")
        print("\n💡 Lösung:")
        print("   1. Erstellen Sie das Verzeichnis manuell")
        print("   2. Oder passen Sie FTP_HOME_DIRS in diesem Script an")
        sys.exit(1)
    
    print(f"\n✅ FTP Home gefunden: {ftp_home}")
    
    # Wechsle in FTP Home Directory
    try:
        os.chdir(ftp_home)
        print(f"✅ Working Directory: {os.getcwd()}")
    except Exception as e:
        print(f"\n❌ Fehler beim Wechseln ins Directory: {e}")
        sys.exit(1)
    
    # Liste verfügbare Ordner
    print("\n📂 Verfügbare Medien-Ordner:")
    for item in os.listdir('.'):
        if os.path.isdir(item):
            file_count = len([f for f in os.listdir(item) if os.path.isfile(os.path.join(item, f))])
            print(f"   /{item:15} ({file_count} Dateien)")
    
    # Starte HTTP Server
    print(f"\n🚀 Starte HTTP Server auf Port {PORT}...")
    print("=" * 60)
    
    try:
        with socketserver.TCPServer(("0.0.0.0", PORT), CORSRequestHandler) as httpd:
            print(f"\n✅ Server läuft erfolgreich!")
            print(f"\n📡 Zugriff:")
            print(f"   Lokal:    http://localhost:{PORT}")
            print(f"   Netzwerk: http://Weltenbibliothek.ddns.net:{PORT}")
            print(f"\n📁 Beispiel-URLs:")
            print(f"   Videos:  http://Weltenbibliothek.ddns.net:{PORT}/videos/")
            print(f"   Audios:  http://Weltenbibliothek.ddns.net:{PORT}/audios/")
            print(f"   Bilder:  http://Weltenbibliothek.ddns.net:{PORT}/images/")
            print(f"   PDFs:    http://Weltenbibliothek.ddns.net:{PORT}/pdfs/")
            print(f"\n🎯 Flutter-App Integration:")
            print(f"   In MediaItem.httpUrl:")
            print(f"   return 'http://Weltenbibliothek.ddns.net:{PORT}' + path;")
            print(f"\n⏹️  Drücken Sie Ctrl+C zum Beenden")
            print("=" * 60)
            print("\n📊 Server-Logs:\n")
            
            httpd.serve_forever()
            
    except PermissionError:
        print(f"\n❌ FEHLER: Keine Berechtigung für Port {PORT}")
        print(f"💡 Lösung:")
        print(f"   1. Verwenden Sie einen Port > 1024 (z.B. 8080)")
        print(f"   2. Oder führen Sie das Script mit Admin-Rechten aus")
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"\n❌ FEHLER: Port {PORT} wird bereits verwendet")
            print(f"💡 Lösung:")
            print(f"   1. Stoppen Sie den anderen Server")
            print(f"   2. Oder ändern Sie PORT in diesem Script")
        else:
            print(f"\n❌ FEHLER: {e}")
    except KeyboardInterrupt:
        print("\n\n⏹️  Server durch Benutzer gestoppt")
        print("=" * 60)
        print("✅ Server sauber beendet")
    except Exception as e:
        print(f"\n❌ Unerwarteter Fehler: {e}")

if __name__ == "__main__":
    main()
