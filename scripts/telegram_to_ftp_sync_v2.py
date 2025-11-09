#!/usr/bin/env python3
"""
Telegram → FTP → Firestore Sync Script (Version 2.0)
Synchronisiert Medien von Telegram-Channels zu Xlight FTP Server und Firestore

Features:
- Lädt Medien von Telegram herunter
- Upload zu Xlight FTP Server (Weltenbibliothek.ddns.net)
- Speichert Metadaten in Firestore Collection 'medien'
- Generiert sowohl FTP- als auch HTTP-URLs für Flutter-Kompatibilität
- Automatische Kategorisierung nach Dateityp

Abhängigkeiten:
- pip install pyrogram firebase-admin

Konfiguration:
- Telegram API-Credentials von https://my.telegram.org/
- Firebase Admin SDK JSON von Firebase Console
- Xlight FTP Server muss laufen (Weltenbibliothek.ddns.net:21)
"""

import os
from pyrogram import Client
from ftplib import FTP
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# ========== KONFIGURATION ==========

# 1. TELEGRAM-SETUP
API_ID = "DEIN_API_ID"  # Von https://my.telegram.org/
API_HASH = "DEIN_API_HASH"  # Von https://my.telegram.org/
TELEGRAM_CHANNEL = "DEIN_KANALNAME"  # Z.B. "@weltenbibliothek"

# 2. FTP-SETUP (Xlight Server)
FTP_HOST = "Weltenbibliothek.ddns.net"
FTP_PORT = 21
FTP_USER = "Weltenbibliothek"
FTP_PASS = "Jolene2305"

# 3. HTTP-PROXY SETUP (für Flutter)
# WICHTIG: Flutter kann nicht direkt FTP abspielen!
# Sie brauchen einen HTTP-Server auf Port 8080
HTTP_HOST = "Weltenbibliothek.ddns.net"
HTTP_PORT = 8080

# 4. FIREBASE-SETUP
FIREBASE_CREDENTIALS = "firebase_credentials.json"  # Pfad zu Ihrem Service Account JSON
FIRESTORE_COLLECTION = "medien"  # Collection-Name in Firestore

# 5. DOWNLOAD-LIMIT
MAX_MESSAGES = 50  # Maximale Anzahl Nachrichten zum Verarbeiten

# ========== DATEI-KATEGORIEN ==========
FOLDERS = {
    "video": "/videos",
    "audio": "/audios",
    "image": "/images",
    "pdf": "/pdfs"
}

FILE_EXTENSIONS = {
    "video": [".mp4", ".mov", ".mkv", ".avi", ".wmv", ".flv", ".webm"],
    "audio": [".mp3", ".wav", ".m4a", ".aac", ".ogg", ".flac", ".wma"],
    "image": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg"],
    "pdf": [".pdf"]
}

# ========== MAIN SCRIPT ==========

def get_media_type(filename):
    """Bestimme Medientyp anhand der Dateiendung"""
    ext = os.path.splitext(filename)[1].lower()
    
    for media_type, extensions in FILE_EXTENSIONS.items():
        if ext in extensions:
            return media_type
    
    return "other"

def generate_urls(ftp_folder, filename):
    """Generiere sowohl FTP- als auch HTTP-URLs"""
    ftp_path = os.path.join(ftp_folder, filename)
    
    # FTP-URL (mit Authentifizierung)
    ftp_url = f"ftp://{FTP_USER}:{FTP_PASS}@{FTP_HOST}:{FTP_PORT}{ftp_path}"
    
    # HTTP-URL (für Flutter - kein User/Pass nötig)
    http_url = f"http://{HTTP_HOST}:{HTTP_PORT}{ftp_path}"
    
    return ftp_url, http_url

def main():
    """Haupt-Sync-Funktion"""
    print("=" * 60)
    print("🚀 Telegram → FTP → Firestore Sync gestartet")
    print("=" * 60)
    
    # Telegram Client initialisieren
    print("\n📡 Verbinde mit Telegram...")
    app = Client("telegram_session", api_id=API_ID, api_hash=API_HASH)
    
    # FTP-Verbindung
    print(f"📤 Verbinde mit FTP Server {FTP_HOST}:{FTP_PORT}...")
    ftp = FTP()
    try:
        ftp.connect(FTP_HOST, FTP_PORT)
        ftp.login(FTP_USER, FTP_PASS)
        print("✅ FTP-Verbindung erfolgreich")
    except Exception as e:
        print(f"❌ FTP-Verbindung fehlgeschlagen: {e}")
        return
    
    # Stelle sicher, dass FTP-Ordner existieren
    print("\n📁 Erstelle FTP-Ordner...")
    for folder in FOLDERS.values():
        try:
            ftp.mkd(folder)
            print(f"✅ Ordner erstellt: {folder}")
        except:
            print(f"ℹ️  Ordner existiert bereits: {folder}")
    
    # Firebase initialisieren
    print("\n☁️  Verbinde mit Firestore...")
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(FIREBASE_CREDENTIALS)
            firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firestore-Verbindung erfolgreich")
    except Exception as e:
        print(f"❌ Firestore-Verbindung fehlgeschlagen: {e}")
        ftp.quit()
        return
    
    # Statistiken
    stats = {
        "total": 0,
        "videos": 0,
        "audios": 0,
        "images": 0,
        "pdfs": 0,
        "errors": 0
    }
    
    # Telegram-Medien verarbeiten
    print(f"\n📥 Lade Medien aus Kanal '{TELEGRAM_CHANNEL}'...")
    print(f"   (Limit: {MAX_MESSAGES} Nachrichten)\n")
    
    with app:
        for message in app.get_chat_history(TELEGRAM_CHANNEL, limit=MAX_MESSAGES):
            if message.media:
                try:
                    stats["total"] += 1
                    print(f"[{stats['total']}/{MAX_MESSAGES}] Verarbeite Nachricht ID {message.id}...")
                    
                    # Medien herunterladen
                    file_path = app.download_media(message, file_name="temp_download")
                    if not file_path:
                        print(f"  ⚠️  Kein Download möglich (vielleicht zu groß?)")
                        stats["errors"] += 1
                        continue
                    
                    # Dateityp erkennen
                    media_type = get_media_type(file_path)
                    
                    if media_type == "other":
                        print(f"  ⚠️  Unbekannter Dateityp: {os.path.splitext(file_path)[1]}")
                        os.remove(file_path)
                        stats["errors"] += 1
                        continue
                    
                    # FTP-Upload
                    ftp_folder = FOLDERS[media_type]
                    filename = os.path.basename(file_path)
                    ftp_file_path = os.path.join(ftp_folder, filename)
                    
                    print(f"  📤 Upload zu FTP: {ftp_file_path}")
                    with open(file_path, "rb") as f:
                        ftp.storbinary(f"STOR {ftp_file_path}", f)
                    
                    # URLs generieren
                    ftp_url, http_url = generate_urls(ftp_folder, filename)
                    
                    # Firestore-Dokument erstellen
                    doc_data = {
                        "title": message.caption or filename,
                        "description": message.caption or "",
                        "ftp_url": ftp_url,
                        "http_url": http_url,  # ✅ NEU: HTTP-URL für Flutter
                        "media_type": media_type,
                        "filename": filename,
                        "telegram_message_id": message.id,
                        "upload_date": firestore.SERVER_TIMESTAMP,
                        "file_size": os.path.getsize(file_path),
                    }
                    
                    print(f"  ☁️  Speichere Metadaten in Firestore...")
                    db.collection(FIRESTORE_COLLECTION).document(filename).set(doc_data)
                    
                    # Statistik aktualisieren
                    if media_type == "video":
                        stats["videos"] += 1
                    elif media_type == "audio":
                        stats["audios"] += 1
                    elif media_type == "image":
                        stats["images"] += 1
                    elif media_type == "pdf":
                        stats["pdfs"] += 1
                    
                    # Lokal löschen
                    os.remove(file_path)
                    print(f"  ✅ Erfolgreich: {filename} ({media_type})\n")
                    
                except Exception as e:
                    print(f"  ❌ Fehler: {e}\n")
                    stats["errors"] += 1
                    if os.path.exists(file_path):
                        os.remove(file_path)
    
    # FTP schließen
    ftp.quit()
    
    # Abschluss-Statistik
    print("\n" + "=" * 60)
    print("✅ SYNC ABGESCHLOSSEN")
    print("=" * 60)
    print(f"📊 Statistik:")
    print(f"   Gesamt verarbeitet: {stats['total']}")
    print(f"   🎬 Videos: {stats['videos']}")
    print(f"   🎵 Audios: {stats['audios']}")
    print(f"   🖼️  Bilder: {stats['images']}")
    print(f"   📄 PDFs: {stats['pdfs']}")
    print(f"   ❌ Fehler: {stats['errors']}")
    print("=" * 60)
    print(f"\n💡 HTTP-URLs verfügbar unter: http://{HTTP_HOST}:{HTTP_PORT}")
    print("   Flutter-App kann jetzt diese Medien abspielen!")
    print("\n✅ Alle Dateien hochgeladen und Firestore aktualisiert!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Sync durch Benutzer abgebrochen")
    except Exception as e:
        print(f"\n\n❌ Kritischer Fehler: {e}")
