#!/usr/bin/env python3
"""
Einfacher HTTP-Server für FTP-Dateien
Macht Xlight FTP-Ordner über HTTP für Flutter verfügbar

SETUP:
1. Setzen Sie FTP_ROOT auf Ihr Xlight Home Directory
2. python3 simple_http_server.py
3. Server läuft auf Port 8080

FLUTTER nutzt dann: http://Weltenbibliothek.ddns.net:8080/videos/datei.mp4
"""

import http.server
import socketserver
import os

PORT = 8080

# Xlight FTP Home Directory
# ANPASSEN: Zeigen Sie auf Ihr Xlight Home Directory!
FTP_ROOT = r"C:\weltenbibliothek"  # Windows
# FTP_ROOT = "/weltenbibliothek"    # Linux

class CORSHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Range')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

# Wechsle ins FTP-Root-Verzeichnis
if os.path.exists(FTP_ROOT):
    os.chdir(FTP_ROOT)
    print(f"✅ Serviere Dateien aus: {FTP_ROOT}")
else:
    print(f"❌ FEHLER: FTP_ROOT nicht gefunden: {FTP_ROOT}")
    print(f"   Bitte passen Sie FTP_ROOT in diesem Script an!")
    exit(1)

print(f"🚀 HTTP-Server läuft auf Port {PORT}")
print(f"📡 Zugriff: http://localhost:{PORT}")
print(f"   Flutter: http://Weltenbibliothek.ddns.net:{PORT}")

with socketserver.TCPServer(("0.0.0.0", PORT), CORSHandler) as httpd:
    httpd.serve_forever()
