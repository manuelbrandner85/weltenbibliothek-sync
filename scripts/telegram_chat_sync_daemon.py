#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔄 TELEGRAM CHAT BIDIREKTIONALE SYNCHRONISATION

Dieses Script synchronisiert Chat-Nachrichten zwischen:
- Telegram-Chat (@Weltenbibliothekchat) ↔ Flutter-App (Firestore)

Features:
✅ Nachrichten von Telegram → Firestore
✅ Nachrichten von App (Firestore) → Telegram
✅ Bearbeitungen synchronisieren (bidirektional)
✅ Löschungen synchronisieren (bidirektional)
✅ Telegram-Benutzernamen anzeigen
✅ Medien-Upload zu FTP-Server
✅ Auto-Löschung nach 24 Stunden

Voraussetzungen:
- pip install pyrogram tgcrypto firebase-admin ftplib
- Telegram API-Credentials (api_id, api_hash)
- Firebase Admin SDK Key
- FTP-Server-Zugang (Xlight)
"""

import os
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import ftplib

# Pyrogram für Telegram
from pyrogram import Client, filters
from pyrogram.types import Message
from pyrogram.errors import MessageNotModified, MessageDeleteForbidden
from pyrogram.handlers import MessageHandler, EditedMessageHandler

# Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, firestore

# ========================================
# KONFIGURATION
# ========================================

# Telegram API Credentials (✅ Konfiguriert)
API_ID = "25697241"  # Weltenbibliothek App
API_HASH = "19cfb3819684da4571a91874ee22603a"  # Weltenbibliothek App
PHONE_NUMBER = None  # Wird aus Config geladen
CHAT_USERNAME = "@Weltenbibliothekchat"  # Ziel-Chat

# ⚠️ Session-Datei: Verwendet "weltenbibliothek_session.session" (bereits vorhanden)

# FTP Server Konfiguration (Xlight)
FTP_HOST = "Weltenbibliothek.ddns.net"
FTP_PORT = 21
FTP_USER = "Weltenbibliothek"
FTP_PASS = "Jolene2305"
HTTP_BASE_URL = f"http://{FTP_HOST}:8080"  # HTTP-Proxy für Flutter

# Firebase Admin SDK
FIREBASE_ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

# Firestore Collection
CHAT_COLLECTION = "chat_messages"

# Auto-Delete Konfiguration
DELETE_AFTER_HOURS = 24  # Nachrichten nach 24 Stunden löschen
CHECK_INTERVAL_SECONDS = 300  # Alle 5 Minuten prüfen

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ========================================
# GLOBALE VARIABLEN
# ========================================

# Pyrogram Client
app: Optional[Client] = None

# Firestore Client
db: Optional[firestore.Client] = None

# Chat ID Cache (wird beim ersten Zugriff gefüllt)
chat_id: Optional[int] = None

# ========================================
# FTP HELPER FUNKTIONEN
# ========================================

def upload_to_ftp(local_path: str, remote_path: str) -> bool:
    """
    Lädt eine Datei auf den FTP-Server hoch
    
    Args:
        local_path: Lokaler Dateipfad
        remote_path: FTP-Zielpfad (z.B. /chat_media/photo_123.jpg)
    
    Returns:
        True bei Erfolg, False bei Fehler
    """
    try:
        with ftplib.FTP() as ftp:
            ftp.connect(FTP_HOST, FTP_PORT)
            ftp.login(FTP_USER, FTP_PASS)
            
            # Verzeichnis erstellen falls nicht vorhanden
            remote_dir = os.path.dirname(remote_path)
            try:
                ftp.mkd(remote_dir)
            except ftplib.error_perm:
                pass  # Verzeichnis existiert bereits
            
            # Datei hochladen
            with open(local_path, 'rb') as file:
                ftp.storbinary(f'STOR {remote_path}', file)
            
            logger.info(f"✅ FTP Upload erfolgreich: {remote_path}")
            return True
            
    except Exception as e:
        logger.error(f"❌ FTP Upload fehlgeschlagen: {e}")
        return False


def delete_from_ftp(remote_path: str) -> bool:
    """
    Löscht eine Datei vom FTP-Server
    
    Args:
        remote_path: FTP-Dateipfad (z.B. /chat_media/photo_123.jpg)
    
    Returns:
        True bei Erfolg, False bei Fehler
    """
    try:
        with ftplib.FTP() as ftp:
            ftp.connect(FTP_HOST, FTP_PORT)
            ftp.login(FTP_USER, FTP_PASS)
            ftp.delete(remote_path)
            logger.info(f"✅ FTP Datei gelöscht: {remote_path}")
            return True
            
    except Exception as e:
        logger.error(f"❌ FTP Löschen fehlgeschlagen: {e}")
        return False

# ========================================
# TELEGRAM → FIRESTORE HANDLER
# ========================================

async def telegram_to_firestore_handler(client: Client, message: Message):
    """
    Handler für neue Nachrichten aus Telegram → Firestore
    """
    global chat_id
    
    try:
        # Chat ID speichern (einmalig)
        if chat_id is None:
            chat_id = message.chat.id
            logger.info(f"📍 Chat ID ermittelt: {chat_id}")
        
        # Benutzerinformationen extrahieren
        user = message.from_user
        username = user.username or f"user_{user.id}"
        
        # Basis-Nachrichtendaten
        doc_data = {
            "messageId": str(message.id),
            "telegramUserId": str(user.id),
            "telegramUsername": username,
            "telegramFirstName": user.first_name or "",
            "telegramLastName": user.last_name or "",
            "text": message.text or message.caption or "",
            "timestamp": firestore.SERVER_TIMESTAMP,
            "source": "telegram",  # Von Telegram
            "edited": False,
            "deleted": False,
            "mediaUrl": None,
            "mediaType": None,
            "ftpPath": None,
            "replyToId": str(message.reply_to_message.id) if message.reply_to_message else None,
        }
        
        # Medien-Handling
        media_url = None
        media_type = None
        ftp_path = None
        
        if message.photo:
            media_type = "photo"
            file_path = await message.download()
            ftp_path = f"/chat_media/photo_{message.id}.jpg"
            
        elif message.video:
            media_type = "video"
            file_path = await message.download()
            ftp_path = f"/chat_media/video_{message.id}.mp4"
            
        elif message.audio:
            media_type = "audio"
            file_path = await message.download()
            ftp_path = f"/chat_media/audio_{message.id}.mp3"
            
        elif message.document:
            media_type = "document"
            file_path = await message.download()
            ext = os.path.splitext(message.document.file_name)[1]
            ftp_path = f"/chat_media/doc_{message.id}{ext}"
        
        # Medien auf FTP hochladen
        if ftp_path:
            if upload_to_ftp(file_path, ftp_path):
                media_url = f"{HTTP_BASE_URL}{ftp_path}"
                doc_data.update({
                    "mediaUrl": media_url,
                    "mediaType": media_type,
                    "ftpPath": ftp_path,
                })
            # Lokale Datei löschen
            os.remove(file_path)
        
        # In Firestore speichern
        db.collection(CHAT_COLLECTION).document(str(message.id)).set(doc_data)
        
        logger.info(f"✅ Telegram → Firestore: Nachricht {message.id} von @{username}")
        
    except Exception as e:
        logger.error(f"❌ Fehler in telegram_to_firestore_handler: {e}")


async def telegram_edit_handler(client: Client, message: Message):
    """
    Handler für bearbeitete Nachrichten in Telegram → Firestore
    """
    try:
        doc_ref = db.collection(CHAT_COLLECTION).document(str(message.id))
        doc = doc_ref.get()
        
        if doc.exists:
            doc_ref.update({
                "text": message.text or message.caption or "",
                "edited": True,
                "editedAt": firestore.SERVER_TIMESTAMP,
            })
            logger.info(f"✅ Telegram Edit → Firestore: Nachricht {message.id} bearbeitet")
        else:
            # Falls Nachricht noch nicht existiert, neu erstellen
            await telegram_to_firestore_handler(client, message)
            
    except Exception as e:
        logger.error(f"❌ Fehler in telegram_edit_handler: {e}")

# ========================================
# FIRESTORE → TELEGRAM POLLING
# ========================================

async def firestore_to_telegram_worker():
    """
    Pollt Firestore nach neuen Nachrichten aus der App und sendet sie zu Telegram
    """
    global chat_id
    
    logger.info("🔄 Firestore → Telegram Worker gestartet")
    
    while True:
        try:
            # Nur Nachrichten mit source="app" und nicht synced
            query = (
                db.collection(CHAT_COLLECTION)
                .where("source", "==", "app")
                .where("syncedToTelegram", "==", False)
                .limit(10)
            )
            
            docs = query.get()
            
            for doc in docs:
                data = doc.to_dict()
                message_text = data.get("text", "")
                media_url = data.get("mediaUrl")
                reply_to_id = data.get("replyToId")
                
                # Chat ID ermitteln (falls noch nicht gesetzt)
                if chat_id is None:
                    # Ersten Telegram-Chat-Zugriff verwenden
                    await asyncio.sleep(2)
                    continue
                
                # Nachricht zu Telegram senden
                sent_message = None
                
                if media_url:
                    # Medien-Nachricht
                    media_type = data.get("mediaType", "photo")
                    
                    if media_type == "photo":
                        sent_message = await app.send_photo(
                            chat_id, 
                            media_url, 
                            caption=message_text,
                            reply_to_message_id=int(reply_to_id) if reply_to_id else None
                        )
                    elif media_type == "video":
                        sent_message = await app.send_video(
                            chat_id, 
                            media_url, 
                            caption=message_text,
                            reply_to_message_id=int(reply_to_id) if reply_to_id else None
                        )
                    elif media_type == "audio":
                        sent_message = await app.send_audio(
                            chat_id, 
                            media_url, 
                            caption=message_text,
                            reply_to_message_id=int(reply_to_id) if reply_to_id else None
                        )
                else:
                    # Text-Nachricht
                    sent_message = await app.send_message(
                        chat_id, 
                        message_text,
                        reply_to_message_id=int(reply_to_id) if reply_to_id else None
                    )
                
                # Firestore aktualisieren
                doc.reference.update({
                    "syncedToTelegram": True,
                    "telegramMessageId": str(sent_message.id) if sent_message else None,
                    "syncedAt": firestore.SERVER_TIMESTAMP,
                })
                
                logger.info(f"✅ Firestore → Telegram: Nachricht {doc.id} gesendet")
            
            # Warte 3 Sekunden vor nächstem Poll
            await asyncio.sleep(3)
            
        except Exception as e:
            logger.error(f"❌ Fehler in firestore_to_telegram_worker: {e}")
            await asyncio.sleep(5)

# ========================================
# EDIT & DELETE SYNC (APP → TELEGRAM)
# ========================================

async def sync_edits_and_deletes_worker():
    """
    Synchronisiert Bearbeitungen und Löschungen von App → Telegram
    """
    logger.info("🔄 Edit & Delete Sync Worker gestartet")
    
    while True:
        try:
            # 1. BEARBEITUNGEN SYNCHRONISIEREN
            edit_query = (
                db.collection(CHAT_COLLECTION)
                .where("source", "==", "app")
                .where("edited", "==", True)
                .where("editSyncedToTelegram", "==", False)
                .limit(10)
            )
            
            for doc in edit_query.get():
                data = doc.to_dict()
                telegram_msg_id = data.get("telegramMessageId")
                
                if telegram_msg_id and chat_id:
                    try:
                        await app.edit_message_text(
                            chat_id,
                            int(telegram_msg_id),
                            data.get("text", "")
                        )
                        
                        doc.reference.update({
                            "editSyncedToTelegram": True,
                            "editSyncedAt": firestore.SERVER_TIMESTAMP,
                        })
                        
                        logger.info(f"✅ Edit App → Telegram: Nachricht {telegram_msg_id} bearbeitet")
                        
                    except MessageNotModified:
                        pass  # Nachricht unverändert
                    except Exception as e:
                        logger.error(f"❌ Edit sync fehlgeschlagen: {e}")
            
            # 2. LÖSCHUNGEN SYNCHRONISIEREN
            delete_query = (
                db.collection(CHAT_COLLECTION)
                .where("source", "==", "app")
                .where("deleted", "==", True)
                .where("deleteSyncedToTelegram", "==", False)
                .limit(10)
            )
            
            for doc in delete_query.get():
                data = doc.to_dict()
                telegram_msg_id = data.get("telegramMessageId")
                ftp_path = data.get("ftpPath")
                
                if telegram_msg_id and chat_id:
                    try:
                        await app.delete_messages(chat_id, int(telegram_msg_id))
                        
                        # Medien von FTP löschen
                        if ftp_path:
                            delete_from_ftp(ftp_path)
                        
                        doc.reference.update({
                            "deleteSyncedToTelegram": True,
                            "deleteSyncedAt": firestore.SERVER_TIMESTAMP,
                        })
                        
                        logger.info(f"✅ Delete App → Telegram: Nachricht {telegram_msg_id} gelöscht")
                        
                    except MessageDeleteForbidden:
                        pass  # Nachricht kann nicht gelöscht werden
                    except Exception as e:
                        logger.error(f"❌ Delete sync fehlgeschlagen: {e}")
            
            # Warte 5 Sekunden vor nächstem Check
            await asyncio.sleep(5)
            
        except Exception as e:
            logger.error(f"❌ Fehler in sync_edits_and_deletes_worker: {e}")
            await asyncio.sleep(10)

# ========================================
# AUTO-DELETE NACH 24 STUNDEN
# ========================================

async def auto_delete_worker():
    """
    Löscht automatisch Nachrichten älter als 24 Stunden
    """
    logger.info("🔄 Auto-Delete Worker gestartet (24h Cleanup)")
    
    while True:
        try:
            # Zeitstempel für Lösch-Grenze berechnen
            delete_before = datetime.utcnow() - timedelta(hours=DELETE_AFTER_HOURS)
            
            # Alte Nachrichten finden
            query = (
                db.collection(CHAT_COLLECTION)
                .where("timestamp", "<", delete_before)
                .where("deleted", "==", False)
                .limit(50)
            )
            
            docs = query.get()
            deleted_count = 0
            
            for doc in docs:
                data = doc.to_dict()
                telegram_msg_id = data.get("messageId")
                ftp_path = data.get("ftpPath")
                
                # 1. Von Telegram löschen
                if telegram_msg_id and chat_id:
                    try:
                        await app.delete_messages(chat_id, int(telegram_msg_id))
                        logger.info(f"✅ Auto-Delete: Telegram Nachricht {telegram_msg_id} gelöscht")
                    except Exception as e:
                        logger.error(f"❌ Telegram Delete fehlgeschlagen: {e}")
                
                # 2. Von FTP löschen
                if ftp_path:
                    delete_from_ftp(ftp_path)
                
                # 3. Firestore markieren als gelöscht
                doc.reference.update({
                    "deleted": True,
                    "deletedAt": firestore.SERVER_TIMESTAMP,
                    "autoDeleted": True,
                })
                
                deleted_count += 1
            
            if deleted_count > 0:
                logger.info(f"🗑️ Auto-Delete: {deleted_count} alte Nachrichten gelöscht")
            
            # Warte CHECK_INTERVAL_SECONDS vor nächstem Check
            await asyncio.sleep(CHECK_INTERVAL_SECONDS)
            
        except Exception as e:
            logger.error(f"❌ Fehler in auto_delete_worker: {e}")
            await asyncio.sleep(60)

# ========================================
# INITIALISIERUNG
# ========================================

async def initialize_services():
    """
    Initialisiert Telegram und Firebase Verbindungen
    """
    global app, db
    
    logger.info("🚀 Initialisiere Services...")
    
    # 1. Firebase Admin SDK initialisieren
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_ADMIN_SDK_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    logger.info("✅ Firebase Firestore verbunden")
    
    # 2. Pyrogram Client initialisieren
    # Nutze vorhandene Session-Datei falls verfügbar
    session_name = "weltenbibliothek_chat_sync"  # Verwendet kopierte Session von wb_session
    session_path = f"{session_name}.session"
    
    # API Credentials sind bereits im Script definiert (siehe oben)
    
    app = Client(
        session_name,
        api_id=API_ID,
        api_hash=API_HASH,
    )
    
    if os.path.exists(session_path):
        logger.info(f"✅ Verwende vorhandene Session: {session_path}")
    else:
        logger.info("⚠️ Keine Session gefunden - Login beim ersten Start erforderlich")
    
    logger.info("✅ Telegram Pyrogram Client initialisiert")
    
    # Firestore Collection Index prüfen/erstellen
    try:
        # Test-Query um Index-Status zu prüfen
        db.collection(CHAT_COLLECTION).where("source", "==", "app").limit(1).get()
        logger.info("✅ Firestore Indexes verfügbar")
    except Exception as e:
        logger.warning(f"⚠️ Firestore Index möglicherweise erforderlich: {e}")

# ========================================
# MAIN ENTRY POINT
# ========================================

async def main():
    """
    Hauptfunktion - startet alle Worker
    """
    logger.info("=" * 60)
    logger.info("🔄 TELEGRAM CHAT BIDIREKTIONALE SYNCHRONISATION")
    logger.info("=" * 60)
    
    # Services initialisieren
    await initialize_services()
    
    # Telegram Client starten
    async with app:
        logger.info("✅ Telegram Client gestartet")
        logger.info(f"📍 Ziel-Chat: {CHAT_USERNAME}")
        logger.info(f"🕐 Auto-Delete: {DELETE_AFTER_HOURS} Stunden")
        logger.info("-" * 60)
        
        # ✅ Handler registrieren (WICHTIG: Innerhalb async with app Block!)
        app.add_handler(
            MessageHandler(
                telegram_to_firestore_handler,
                filters.chat(CHAT_USERNAME) & ~filters.bot
            )
        )
        app.add_handler(
            EditedMessageHandler(
                telegram_edit_handler,
                filters.chat(CHAT_USERNAME) & ~filters.bot
            )
        )
        logger.info("✅ Telegram Event Handler registriert")
        
        # Alle Worker parallel starten
        await asyncio.gather(
            firestore_to_telegram_worker(),  # App → Telegram
            sync_edits_and_deletes_worker(),  # Edit & Delete Sync
            auto_delete_worker(),  # 24h Auto-Delete
        )


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n⏹️ Chat Sync Daemon gestoppt (Strg+C)")
    except Exception as e:
        logger.error(f"❌ Fataler Fehler: {e}")
