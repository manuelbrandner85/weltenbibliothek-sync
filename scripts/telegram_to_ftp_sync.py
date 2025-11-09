#!/usr/bin/env python3
"""
Telegram to FTP Sync Script
Lädt Medien aus Telegram-Kanal und synchronisiert sie mit FTP Server
"""

from pyrogram import Client
import ftplib
import os
from dotenv import load_dotenv
from datetime import datetime
import json

# Lade Umgebungsvariablen
load_dotenv()

# FTP-Zugangsdaten
FTP_HOST = os.getenv("FTP_HOST", "your-ftp-server.com")
FTP_PORT = int(os.getenv("FTP_PORT", "21"))
FTP_USER = os.getenv("FTP_USER", "Weltenbibliothek")
FTP_PASS = os.getenv("FTP_PASS", "Jolene2305")
FTP_BASE_PATH = os.getenv("FTP_BASE_PATH", "/weltenbibliothek")

# Telegram Zugang
CHANNEL = os.getenv("CHANNEL")
API_ID = int(os.getenv("API_ID"))
API_HASH = os.getenv("API_HASH")

# Download-Verzeichnis
DOWNLOAD_DIR = "downloads"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# Metadaten-Tracking
METADATA_FILE = "sync_metadata.json"

class TelegramToFTPSync:
    def __init__(self):
        self.ftp = None
        self.app = None
        self.metadata = self.load_metadata()
        
    def load_metadata(self):
        """Lade Sync-Metadaten (welche Nachrichten wurden bereits hochgeladen)"""
        if os.path.exists(METADATA_FILE):
            with open(METADATA_FILE, 'r') as f:
                return json.load(f)
        return {"synced_messages": [], "last_sync": None}
    
    def save_metadata(self):
        """Speichere Sync-Metadaten"""
        with open(METADATA_FILE, 'w') as f:
            json.dump(self.metadata, f, indent=2)
    
    def connect_ftp(self):
        """Verbinde mit FTP Server"""
        try:
            self.ftp = ftplib.FTP()
            self.ftp.connect(FTP_HOST, FTP_PORT)
            self.ftp.login(FTP_USER, FTP_PASS)
            print(f"✅ FTP verbunden: {FTP_HOST}")
            
            # Erstelle Basis-Verzeichnis falls nicht vorhanden
            try:
                self.ftp.cwd(FTP_BASE_PATH)
            except ftplib.error_perm:
                self.ftp.mkd(FTP_BASE_PATH)
                self.ftp.cwd(FTP_BASE_PATH)
                
            return True
        except Exception as e:
            print(f"❌ FTP Verbindung fehlgeschlagen: {e}")
            return False
    
    def ensure_ftp_folder(self, folder_name):
        """Stelle sicher, dass FTP-Ordner existiert"""
        try:
            self.ftp.cwd(FTP_BASE_PATH)
            try:
                self.ftp.cwd(folder_name)
            except ftplib.error_perm:
                self.ftp.mkd(folder_name)
                self.ftp.cwd(folder_name)
            return True
        except Exception as e:
            print(f"⚠️ Fehler beim Erstellen des Ordners {folder_name}: {e}")
            return False
    
    def upload_to_ftp(self, local_path, remote_folder, original_filename=None):
        """Upload einer Datei auf FTP Server"""
        try:
            if not os.path.exists(local_path):
                print(f"⚠️ Datei nicht gefunden: {local_path}")
                return None
            
            # Verwende Original-Dateinamen wenn vorhanden
            file_name = original_filename or os.path.basename(local_path)
            
            # Stelle sicher, dass Ordner existiert
            if not self.ensure_ftp_folder(remote_folder):
                return None
            
            # Upload Datei
            with open(local_path, "rb") as file:
                self.ftp.storbinary(f"STOR {file_name}", file)
            
            # Generiere FTP URL
            ftp_url = f"ftp://{FTP_HOST}{FTP_BASE_PATH}/{remote_folder}/{file_name}"
            print(f"✅ Hochgeladen: {ftp_url}")
            
            # Lösche lokale Datei nach erfolgreichem Upload
            os.remove(local_path)
            
            return ftp_url
            
        except Exception as e:
            print(f"❌ Upload fehlgeschlagen für {local_path}: {e}")
            return None
    
    def get_media_category(self, message):
        """Bestimme Medien-Kategorie aus Nachricht"""
        # Versuche Kategorie aus Hashtags zu extrahieren
        if message.caption:
            text = message.caption.lower()
            if "#technologie" in text or "#tech" in text:
                return "tech_mysteries"
            elif "#mystik" in text or "#occult" in text:
                return "mysticism"
            elif "#kosmos" in text or "#space" in text:
                return "cosmos"
            elif "#verboten" in text or "#forbidden" in text:
                return "forbidden"
            elif "#paranormal" in text:
                return "paranormal"
        
        # Standard-Kategorie
        return "general"
    
    def process_message(self, message):
        """Verarbeite einzelne Telegram-Nachricht"""
        message_id = message.id
        
        # Prüfe, ob Nachricht bereits synchronisiert wurde
        if message_id in self.metadata["synced_messages"]:
            return None
        
        media_info = {
            "message_id": message_id,
            "date": message.date.isoformat() if message.date else None,
            "caption": message.caption or message.text or "",
            "category": self.get_media_category(message),
            "ftp_url": None,
            "media_type": None,
            "file_size": None,
        }
        
        file_path = None
        remote_folder = None
        
        try:
            # Video
            if message.video:
                media_info["media_type"] = "video"
                media_info["file_size"] = message.video.file_size
                file_path = message.download(file_name=f"{DOWNLOAD_DIR}/")
                remote_folder = "videos"
            
            # Audio / Voice
            elif message.audio or message.voice:
                media_info["media_type"] = "audio"
                if message.audio:
                    media_info["file_size"] = message.audio.file_size
                else:
                    media_info["file_size"] = message.voice.file_size
                file_path = message.download(file_name=f"{DOWNLOAD_DIR}/")
                remote_folder = "audios"
            
            # Foto
            elif message.photo:
                media_info["media_type"] = "image"
                media_info["file_size"] = message.photo.file_size
                file_path = message.download(file_name=f"{DOWNLOAD_DIR}/")
                remote_folder = "images"
            
            # PDF
            elif message.document and message.document.mime_type == "application/pdf":
                media_info["media_type"] = "pdf"
                media_info["file_size"] = message.document.file_size
                file_path = message.download(file_name=f"{DOWNLOAD_DIR}/")
                remote_folder = "pdfs"
            
            # Andere Dokumente
            elif message.document:
                media_info["media_type"] = "document"
                media_info["file_size"] = message.document.file_size
                file_path = message.download(file_name=f"{DOWNLOAD_DIR}/")
                remote_folder = "documents"
            
            # Upload zu FTP
            if file_path and remote_folder:
                ftp_url = self.upload_to_ftp(file_path, remote_folder)
                if ftp_url:
                    media_info["ftp_url"] = ftp_url
                    # Markiere als synchronisiert
                    self.metadata["synced_messages"].append(message_id)
                    return media_info
            
        except Exception as e:
            print(f"⚠️ Fehler beim Verarbeiten von Nachricht {message_id}: {e}")
        
        return None
    
    def sync_telegram_to_ftp(self, limit=100):
        """Synchronisiere Telegram-Kanal mit FTP"""
        print(f"\n📦 Starte Sync von {CHANNEL}...")
        print(f"📊 Limit: {limit} neueste Nachrichten\n")
        
        # Verbinde mit FTP
        if not self.connect_ftp():
            return False
        
        # Starte Pyrogram Client
        self.app = Client("weltenbibliothek_sync", api_id=API_ID, api_hash=API_HASH)
        
        synced_count = 0
        skipped_count = 0
        
        with self.app:
            try:
                for message in self.app.get_chat_history(CHANNEL, limit=limit):
                    # Verarbeite Nachricht
                    result = self.process_message(message)
                    
                    if result:
                        synced_count += 1
                        print(f"📊 Status: {synced_count} synchronisiert, {skipped_count} übersprungen")
                    else:
                        skipped_count += 1
                
                # Speichere Metadaten
                self.metadata["last_sync"] = datetime.now().isoformat()
                self.save_metadata()
                
                print(f"\n✅ Sync abgeschlossen!")
                print(f"   📥 {synced_count} neue Dateien hochgeladen")
                print(f"   ⏭️ {skipped_count} Nachrichten übersprungen")
                
            except Exception as e:
                print(f"❌ Sync-Fehler: {e}")
                return False
        
        # Schließe FTP Verbindung
        if self.ftp:
            self.ftp.quit()
        
        return True

def main():
    """Hauptfunktion"""
    print("=" * 60)
    print("📡 TELEGRAM → FTP SYNC SYSTEM")
    print("=" * 60)
    
    # Prüfe Umgebungsvariablen
    required_vars = ["CHANNEL", "API_ID", "API_HASH"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"\n❌ Fehlende Umgebungsvariablen: {', '.join(missing_vars)}")
        print("💡 Erstelle eine .env Datei mit:")
        print("   CHANNEL=@your_channel")
        print("   API_ID=your_api_id")
        print("   API_HASH=your_api_hash")
        print("   FTP_HOST=your_ftp_host")
        print("   FTP_USER=Weltenbibliothek")
        print("   FTP_PASS=Jolene2305")
        return
    
    # Starte Sync
    sync = TelegramToFTPSync()
    success = sync.sync_telegram_to_ftp(limit=100)
    
    if success:
        print("\n🎉 Sync erfolgreich abgeschlossen!")
    else:
        print("\n⚠️ Sync mit Fehlern beendet")

if __name__ == "__main__":
    main()
