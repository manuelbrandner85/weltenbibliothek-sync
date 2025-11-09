#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔐 TELEGRAM CHAT SYNC - SESSION SETUP

Dieses Script erstellt einmalig eine Pyrogram-Session für den Chat-Sync-Daemon.

Führen Sie dieses Script aus, um sich mit Telegram anzumelden:
    python3 setup_chat_sync_session.py

Nach erfolgreichem Login wird die Session-Datei erstellt:
    weltenbibliothek_chat_sync.session

Diese Session-Datei wird dann vom telegram_chat_sync_daemon.py verwendet.
"""

import asyncio
from pyrogram import Client

# Telegram API Credentials (aus Hauptscript übernommen)
API_ID = "25697241"
API_HASH = "19cfb3819684da4571a91874ee22603a"
SESSION_NAME = "weltenbibliothek_chat_sync"

async def create_session():
    """
    Erstellt interaktiv eine Pyrogram-Session
    """
    print("=" * 70)
    print("🔐 TELEGRAM CHAT SYNC - SESSION SETUP")
    print("=" * 70)
    print()
    print("Dieser Prozess fragt nach:")
    print("  1. Ihrer Telegram-Telefonnummer (z.B. +43XXXXXXXXXX)")
    print("  2. Dem Bestätigungscode (wird per Telegram gesendet)")
    print("  3. Falls 2FA aktiv: Ihrem Passwort")
    print()
    print("Nach erfolgreicher Anmeldung wird die Session gespeichert.")
    print()
    print("-" * 70)
    print()
    
    # Pyrogram Client erstellen
    app = Client(
        SESSION_NAME,
        api_id=API_ID,
        api_hash=API_HASH,
    )
    
    # Session erstellen (interaktiver Login)
    async with app:
        # Hole User-Informationen um Login zu bestätigen
        me = await app.get_me()
        
        print()
        print("=" * 70)
        print("✅ SESSION ERFOLGREICH ERSTELLT!")
        print("=" * 70)
        print()
        print(f"📱 Angemeldet als:")
        print(f"   Name: {me.first_name} {me.last_name or ''}")
        print(f"   Username: @{me.username or 'N/A'}")
        print(f"   User ID: {me.id}")
        print(f"   Phone: {me.phone_number}")
        print()
        print(f"💾 Session-Datei gespeichert: {SESSION_NAME}.session")
        print()
        print("🚀 Sie können jetzt den Chat-Sync-Daemon starten:")
        print("   python3 telegram_chat_sync_daemon.py")
        print()
        print("=" * 70)

if __name__ == "__main__":
    try:
        asyncio.run(create_session())
    except KeyboardInterrupt:
        print("\n\n⏹️ Setup abgebrochen (Strg+C)")
    except Exception as e:
        print(f"\n❌ Fehler beim Session-Setup: {e}")
        print()
        print("💡 Häufige Probleme:")
        print("   - Falsche Telefonnummer → Versuche es erneut")
        print("   - Falscher Code → Telegram sendet neuen Code")
        print("   - 2FA Passwort falsch → Überprüfe dein Passwort")
