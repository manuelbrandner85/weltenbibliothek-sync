#!/usr/bin/env python3
"""
Xlight FTP Server Connection Test
Testet die Verbindung zu deinem Xlight FTP Server
"""

import ftplib
import os
from dotenv import load_dotenv

# Lade Umgebungsvariablen
load_dotenv()

# FTP-Zugangsdaten
FTP_HOST = os.getenv("FTP_HOST", "localhost")
FTP_PORT = int(os.getenv("FTP_PORT", "21"))
FTP_USER = os.getenv("FTP_USER", "Weltenbibliothek")
FTP_PASS = os.getenv("FTP_PASS", "Jolene2305")
FTP_BASE_PATH = os.getenv("FTP_BASE_PATH", "/weltenbibliothek")

def test_connection():
    """Teste FTP-Verbindung"""
    print("=" * 60)
    print("🔧 XLIGHT FTP SERVER CONNECTION TEST")
    print("=" * 60)
    print()
    
    print("📋 Konfiguration:")
    print(f"   Host: {FTP_HOST}")
    print(f"   Port: {FTP_PORT}")
    print(f"   User: {FTP_USER}")
    print(f"   Pass: {'*' * len(FTP_PASS)}")
    print(f"   Base Path: {FTP_BASE_PATH}")
    print()
    
    ftp = None
    
    try:
        # Schritt 1: Verbindung herstellen
        print("🔌 Schritt 1: Verbinde mit Server...")
        ftp = ftplib.FTP()
        ftp.connect(FTP_HOST, FTP_PORT, timeout=10)
        print(f"✅ Verbindung erfolgreich zu {FTP_HOST}:{FTP_PORT}")
        print()
        
        # Schritt 2: Login
        print("🔐 Schritt 2: Authentifizierung...")
        ftp.login(FTP_USER, FTP_PASS)
        print(f"✅ Login erfolgreich als {FTP_USER}")
        print()
        
        # Schritt 3: Welcome Message
        print("📨 Server Welcome Message:")
        print(f"   {ftp.getwelcome()}")
        print()
        
        # Schritt 4: Aktuelles Verzeichnis
        print("📂 Schritt 3: Prüfe aktuelles Verzeichnis...")
        current_dir = ftp.pwd()
        print(f"✅ Aktuelles Verzeichnis: {current_dir}")
        print()
        
        # Schritt 5: Wechsel zu Base Path
        print(f"📁 Schritt 4: Wechsel zu {FTP_BASE_PATH}...")
        try:
            ftp.cwd(FTP_BASE_PATH)
            print(f"✅ Erfolgreich zu {FTP_BASE_PATH} gewechselt")
        except ftplib.error_perm as e:
            print(f"⚠️ Verzeichnis {FTP_BASE_PATH} existiert nicht: {e}")
            print(f"💡 Erstelle Verzeichnis...")
            try:
                ftp.mkd(FTP_BASE_PATH)
                ftp.cwd(FTP_BASE_PATH)
                print(f"✅ Verzeichnis {FTP_BASE_PATH} erstellt und gewechselt")
            except Exception as e2:
                print(f"❌ Fehler beim Erstellen: {e2}")
                return False
        print()
        
        # Schritt 6: Liste Dateien/Ordner
        print("📋 Schritt 5: Liste Dateien und Ordner...")
        items = []
        ftp.retrlines('LIST', items.append)
        
        if items:
            print(f"✅ {len(items)} Einträge gefunden:")
            for item in items[:10]:  # Zeige nur ersten 10
                print(f"   {item}")
            if len(items) > 10:
                print(f"   ... und {len(items) - 10} weitere")
        else:
            print("⚠️ Verzeichnis ist leer")
        print()
        
        # Schritt 7: Prüfe Unterordner
        print("📁 Schritt 6: Prüfe erforderliche Unterordner...")
        required_folders = ['videos', 'audios', 'images', 'pdfs', 'documents']
        
        ftp.cwd(FTP_BASE_PATH)
        existing_folders = ftp.nlst()
        
        for folder in required_folders:
            if folder in existing_folders:
                print(f"   ✅ {folder}/ existiert")
            else:
                print(f"   ⚠️ {folder}/ fehlt - erstelle...")
                try:
                    ftp.mkd(folder)
                    print(f"   ✅ {folder}/ erstellt")
                except Exception as e:
                    print(f"   ❌ Fehler beim Erstellen von {folder}/: {e}")
        print()
        
        # Schritt 8: Test-Upload
        print("📤 Schritt 7: Teste Upload...")
        test_file_content = b"Test file from Xlight FTP Connection Test"
        test_filename = "test_connection.txt"
        
        ftp.cwd(FTP_BASE_PATH)
        try:
            from io import BytesIO
            ftp.storbinary(f'STOR {test_filename}', BytesIO(test_file_content))
            print(f"✅ Test-Datei '{test_filename}' erfolgreich hochgeladen")
            
            # Versuche Datei zu löschen
            ftp.delete(test_filename)
            print(f"✅ Test-Datei erfolgreich gelöscht")
        except Exception as e:
            print(f"❌ Upload-Test fehlgeschlagen: {e}")
            return False
        print()
        
        # Erfolg!
        print("=" * 60)
        print("🎉 ALLE TESTS ERFOLGREICH!")
        print("=" * 60)
        print()
        print("✅ FTP-Verbindung funktioniert einwandfrei")
        print("✅ Login erfolgreich")
        print("✅ Verzeichnisse vorhanden")
        print("✅ Upload-Berechtigung OK")
        print()
        print("💡 Du kannst jetzt das Sync-Script starten:")
        print("   python3 telegram_to_ftp_sync.py")
        print()
        
        return True
        
    except ftplib.error_perm as e:
        print(f"❌ Authentifizierungsfehler: {e}")
        print()
        print("💡 Mögliche Ursachen:")
        print("   - Falscher Benutzername oder Passwort")
        print("   - Benutzer nicht aktiviert in Xlight")
        print("   - IP-Beschränkungen in Xlight")
        print()
        return False
        
    except ConnectionRefusedError:
        print(f"❌ Verbindung verweigert zu {FTP_HOST}:{FTP_PORT}")
        print()
        print("💡 Mögliche Ursachen:")
        print("   - Xlight FTP Server läuft nicht")
        print("   - Falsche Host-Adresse oder Port")
        print("   - Firewall blockiert Port 21")
        print()
        return False
        
    except Exception as e:
        print(f"❌ Unerwarteter Fehler: {e}")
        print()
        return False
        
    finally:
        if ftp:
            try:
                ftp.quit()
                print("🔌 FTP-Verbindung geschlossen")
            except:
                pass

def main():
    """Hauptfunktion"""
    # Prüfe .env Datei
    if not os.path.exists('.env'):
        print("=" * 60)
        print("⚠️ KEINE .env DATEI GEFUNDEN")
        print("=" * 60)
        print()
        print("Bitte erstelle eine .env Datei mit:")
        print()
        print("  cp .env.example .env")
        print("  nano .env")
        print()
        print("Und fülle folgende Werte aus:")
        print("  - FTP_HOST (z.B. 192.168.1.100)")
        print("  - API_ID (von https://my.telegram.org/apps)")
        print("  - API_HASH (von https://my.telegram.org/apps)")
        print("  - CHANNEL (dein Telegram Kanal)")
        print()
        return
    
    # Führe Test aus
    success = test_connection()
    
    if not success:
        print()
        print("💡 NÄCHSTE SCHRITTE:")
        print()
        print("1. Prüfe ob Xlight FTP Server läuft")
        print("2. Prüfe .env Datei Einstellungen")
        print("3. Teste mit FileZilla:")
        print(f"   Host: {FTP_HOST}")
        print(f"   User: {FTP_USER}")
        print(f"   Pass: {FTP_PASS}")
        print("   Port: 21")
        print()

if __name__ == "__main__":
    main()
