#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Telegram API Credentials Setup
===============================
Interaktives Script zum Einrichten der Telegram API Credentials
"""

import json
import os

CONFIG_FILE = "telegram_config.json"

def setup_credentials():
    """
    Interaktives Setup für Telegram API Credentials
    """
    print("=" * 60)
    print("🔐 TELEGRAM API CREDENTIALS SETUP")
    print("=" * 60)
    print()
    print("📋 Dieses Script speichert Ihre Telegram API Credentials sicher.")
    print()
    print("🔗 Falls Sie noch keine API Credentials haben:")
    print("   1. Gehe zu: https://my.telegram.org/apps")
    print("   2. Melde dich mit deiner Telegram-Nummer an")
    print("   3. Erstelle eine neue App oder verwende eine vorhandene")
    print("   4. Kopiere API_ID und API_HASH")
    print()
    print("=" * 60)
    print()
    
    # Prüfe ob Config bereits existiert
    if os.path.exists(CONFIG_FILE):
        print(f"⚠️  Config-Datei gefunden: {CONFIG_FILE}")
        overwrite = input("   Möchten Sie die vorhandenen Credentials überschreiben? (j/n): ").strip().lower()
        if overwrite != 'j':
            print("❌ Setup abgebrochen.")
            return False
        print()
    
    # API ID
    print("📝 Schritt 1/3: API ID")
    print("   (Numerisch, z.B. 12345678)")
    api_id = input("   API ID: ").strip()
    
    if not api_id.isdigit():
        print("❌ Fehler: API ID muss numerisch sein!")
        return False
    
    print()
    
    # API Hash
    print("📝 Schritt 2/3: API Hash")
    print("   (Alphanumerisch, z.B. 0123456789abcdef...)")
    api_hash = input("   API Hash: ").strip()
    
    if len(api_hash) < 16:
        print("❌ Fehler: API Hash zu kurz! Sollte ca. 32 Zeichen lang sein.")
        return False
    
    print()
    
    # Telefonnummer
    print("📝 Schritt 3/3: Telefonnummer")
    print("   (Internationales Format, z.B. +43XXXXXXXXXX)")
    phone_number = input("   Telefonnummer: ").strip()
    
    if not phone_number.startswith('+'):
        print("❌ Fehler: Telefonnummer muss mit + beginnen (international)!")
        return False
    
    print()
    
    # Config speichern
    config = {
        "api_id": int(api_id),
        "api_hash": api_hash,
        "phone_number": phone_number
    }
    
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        
        print("=" * 60)
        print("✅ CREDENTIALS ERFOLGREICH GESPEICHERT!")
        print("=" * 60)
        print()
        print(f"📁 Config-Datei: {CONFIG_FILE}")
        print()
        print("🔐 Gespeicherte Credentials:")
        print(f"   API ID: {api_id}")
        print(f"   API Hash: {api_hash[:8]}{'*' * (len(api_hash) - 8)}")
        print(f"   Telefonnummer: {phone_number}")
        print()
        print("🚀 Sie können jetzt den Chat-Sync-Daemon starten:")
        print("   python3 telegram_chat_sync_daemon.py")
        print()
        
        return True
        
    except Exception as e:
        print(f"❌ Fehler beim Speichern: {e}")
        return False

if __name__ == "__main__":
    try:
        setup_credentials()
    except KeyboardInterrupt:
        print("\n❌ Setup abgebrochen (Strg+C)")
    except Exception as e:
        print(f"\n❌ Fehler: {e}")
