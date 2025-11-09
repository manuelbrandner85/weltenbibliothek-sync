#!/usr/bin/env python3
"""
Telegram → FTP → Firestore Sync
Ersetzt Firebase Storage durch Xlight FTP Server

Speichert:
- Medien-Dateien auf FTP Server
- Metadaten in Firestore (wie bisher)
- HTTP-URLs für Flutter-Wiedergabe
"""

import os
from pyrogram import Client
from ftplib import FTP
import firebase_admin
from firebase_admin import credentials, firestore

# ===== KONFIGURATION =====
API_ID = "DEIN_API_ID"
API_HASH = "DEIN_API_HASH"
TELEGRAM_CHANNEL = "DEIN_KANALNAME"

FTP_HOST = "Weltenbibliothek.ddns.net"
FTP_PORT = 21
FTP_USER = "Weltenbibliothek"
FTP_PASS = "Jolene2305"

# HTTP-Zugriff (für Flutter-Wiedergabe)
HTTP_BASE_URL = f"http://{FTP_HOST}:8080"

# Firebase
FIREBASE_CRED = "firebase_credentials.json"
COLLECTION = "telegram_media"  # Ihre bestehende Collection!

# Ordner
FOLDERS = {
    "video": "/videos",
    "audio": "/audios", 
    "image": "/images",
    "pdf": "/pdfs"
}

# ===== FUNKTIONEN =====

def get_media_type(filename):
    """Dateityp erkennen"""
    ext = os.path.splitext(filename)[1].lower()
    if ext in [".mp4", ".mov", ".mkv", ".avi", ".webm"]:
        return "video"
    elif ext in [".mp3", ".wav", ".m4a", ".aac", ".ogg"]:
        return "audio"
    elif ext in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
        return "image"
    elif ext in [".pdf"]:
        return "pdf"
    return "other"

# ===== MAIN =====

app = Client("telegram_session", api_id=API_ID, api_hash=API_HASH)

# FTP verbinden
ftp = FTP()
ftp.connect(FTP_HOST, FTP_PORT)
ftp.login(FTP_USER, FTP_PASS)

# Ordner erstellen
for folder in FOLDERS.values():
    try:
        ftp.mkd(folder)
    except:
        pass

# Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CRED)
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("🚀 Starte Sync...")

with app:
    for message in app.get_chat_history(TELEGRAM_CHANNEL, limit=50):
        if message.media:
            try:
                # Download
                file_path = app.download_media(message, file_name="temp_download")
                if not file_path:
                    continue
                
                media_type = get_media_type(file_path)
                if media_type == "other":
                    os.remove(file_path)
                    continue
                
                # FTP Upload
                ftp_folder = FOLDERS[media_type]
                filename = os.path.basename(file_path)
                ftp_path = os.path.join(ftp_folder, filename).replace("\\", "/")
                
                with open(file_path, "rb") as f:
                    ftp.storbinary(f"STOR {ftp_path}", f)
                
                # Firestore - KOMPATIBEL mit bestehender App-Struktur!
                doc_data = {
                    # Bestehende Felder (kompatibel)
                    "channelUsername": TELEGRAM_CHANNEL.replace("@", ""),
                    "channelTitle": "Weltenbibliothek",
                    "messageId": message.id,
                    "text": message.caption or "",
                    "date": message.date,
                    "category": "allgemein",
                    
                    # Medien-Felder (NEU)
                    "mediaType": media_type,
                    "mediaUrl": f"{HTTP_BASE_URL}{ftp_path}",  # ✅ HTTP für Flutter!
                    "fileName": filename,
                    "fileSize": os.path.getsize(file_path),
                    
                    # Optional
                    "ftpPath": ftp_path,
                }
                
                # In bestehende Collection schreiben
                db.collection(COLLECTION).document(filename).set(doc_data)
                
                os.remove(file_path)
                print(f"✅ {filename} ({media_type})")
                
            except Exception as e:
                print(f"❌ Fehler: {e}")
                if os.path.exists(file_path):
                    os.remove(file_path)

ftp.quit()
print("✅ Sync abgeschlossen!")
