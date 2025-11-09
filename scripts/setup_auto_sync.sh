#!/bin/bash

# Setup Script für automatische Telegram → FTP Synchronisation

echo "🔧 TELEGRAM → FTP AUTO-SYNC SETUP"
echo "=================================="
echo ""

# Prüfe ob Script-Verzeichnis existiert
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Prüfe Python-Installation
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 ist nicht installiert!"
    echo "   Installiere mit: sudo apt install python3"
    exit 1
fi

echo "✅ Python 3 gefunden"

# Prüfe pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 ist nicht installiert!"
    echo "   Installiere mit: sudo apt install python3-pip"
    exit 1
fi

echo "✅ pip3 gefunden"

# Installiere Requirements
echo ""
echo "📦 Installiere Python-Packages..."
pip3 install -r requirements.txt

# Prüfe .env Datei
if [ ! -f ".env" ]; then
    echo ""
    echo "⚠️ .env Datei nicht gefunden!"
    echo "   Kopiere .env.example zu .env und fülle die Werte aus:"
    echo ""
    echo "   cp .env.example .env"
    echo "   nano .env"
    echo ""
    exit 1
fi

echo "✅ .env Datei gefunden"

# Test-Run
echo ""
echo "🧪 Teste Sync-Script..."
python3 telegram_to_ftp_sync.py

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Test erfolgreich!"
else
    echo ""
    echo "❌ Test fehlgeschlagen - prüfe Konfiguration"
    exit 1
fi

# Cron-Job Setup
echo ""
echo "⏰ Cron-Job Setup"
echo "================"
echo ""
echo "Möchtest du einen automatischen Sync einrichten?"
echo "1) Alle 15 Minuten"
echo "2) Stündlich"
echo "3) Täglich um 3:00 Uhr"
echo "4) Manuell (kein Cron-Job)"
echo ""
read -p "Wähle eine Option (1-4): " choice

CRON_CMD="cd $SCRIPT_DIR && python3 telegram_to_ftp_sync.py >> sync.log 2>&1"

case $choice in
    1)
        CRON_SCHEDULE="*/15 * * * *"
        ;;
    2)
        CRON_SCHEDULE="0 * * * *"
        ;;
    3)
        CRON_SCHEDULE="0 3 * * *"
        ;;
    4)
        echo ""
        echo "✅ Kein Cron-Job eingerichtet"
        echo "   Du kannst das Script manuell ausführen mit:"
        echo "   cd $SCRIPT_DIR && python3 telegram_to_ftp_sync.py"
        exit 0
        ;;
    *)
        echo "❌ Ungültige Option"
        exit 1
        ;;
esac

# Füge Cron-Job hinzu
(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $CRON_CMD") | crontab -

echo ""
echo "✅ Cron-Job eingerichtet!"
echo "   Schedule: $CRON_SCHEDULE"
echo "   Command: $CRON_CMD"
echo ""
echo "📊 Überprüfe Cron-Jobs mit: crontab -l"
echo "📝 Logs ansehen mit: tail -f $SCRIPT_DIR/sync.log"
echo ""
echo "🎉 Setup abgeschlossen!"
