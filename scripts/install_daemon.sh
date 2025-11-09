#!/bin/bash

# ========================================
# Weltenbibliothek Chat-Sync-Daemon
# Installation Script (systemd)
# ========================================

set -e  # Exit on error

echo "🚀 Weltenbibliothek Chat-Sync-Daemon Installation"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Dieses Script muss als root ausgeführt werden"
    echo "   Bitte verwenden: sudo $0"
    exit 1
fi

# Variables
SERVICE_NAME="telegram-chat-sync"
SERVICE_FILE="${SERVICE_NAME}.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SYSTEMD_DIR="/etc/systemd/system"
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/${SERVICE_NAME}.log"

echo "📁 Projektverzeichnis: $PROJECT_DIR"
echo "📁 Script-Verzeichnis: $SCRIPT_DIR"
echo ""

# Step 1: Check PHP version
echo "🔍 Schritt 1/6: PHP-Version prüfen..."
PHP_VERSION=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "0.0.0")
PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)

if [ "$PHP_MAJOR" -lt 8 ] || ([ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -lt 1 ]); then
    echo "❌ PHP 8.1 oder höher wird benötigt (gefunden: $PHP_VERSION)"
    echo "   Installation: sudo apt install php8.1-cli php8.1-mbstring php8.1-xml"
    exit 1
fi
echo "✅ PHP $PHP_VERSION gefunden"
echo ""

# Step 2: Check MadelineProto
echo "🔍 Schritt 2/6: MadelineProto-Installation prüfen..."
if [ ! -d "/home/user/madeline_backend/vendor" ]; then
    echo "❌ MadelineProto nicht gefunden in /home/user/madeline_backend/vendor"
    exit 1
fi
echo "✅ MadelineProto installiert"
echo ""

# Step 3: Check script file
echo "🔍 Schritt 3/6: Chat-Sync-Script prüfen..."
if [ ! -f "$SCRIPT_DIR/telegram_chat_sync_madeline.php" ]; then
    echo "❌ Script nicht gefunden: $SCRIPT_DIR/telegram_chat_sync_madeline.php"
    exit 1
fi
echo "✅ Script gefunden"
echo ""

# Step 4: Create log file
echo "📝 Schritt 4/6: Log-Datei erstellen..."
touch "$LOG_FILE"
chown user:user "$LOG_FILE"
chmod 644 "$LOG_FILE"
echo "✅ Log-Datei erstellt: $LOG_FILE"
echo ""

# Step 5: Install systemd service
echo "⚙️  Schritt 5/6: systemd-Service installieren..."
if [ ! -f "$SCRIPT_DIR/$SERVICE_FILE" ]; then
    echo "❌ Service-Datei nicht gefunden: $SCRIPT_DIR/$SERVICE_FILE"
    exit 1
fi

# Copy service file
cp "$SCRIPT_DIR/$SERVICE_FILE" "$SYSTEMD_DIR/$SERVICE_FILE"
chmod 644 "$SYSTEMD_DIR/$SERVICE_FILE"
echo "✅ Service-Datei kopiert"

# Reload systemd
systemctl daemon-reload
echo "✅ systemd neu geladen"
echo ""

# Step 6: Enable and start service
echo "🚀 Schritt 6/6: Service aktivieren und starten..."
systemctl enable "$SERVICE_NAME.service"
echo "✅ Service aktiviert (startet automatisch beim Boot)"

systemctl start "$SERVICE_NAME.service"
echo "✅ Service gestartet"
echo ""

# Wait for service to start
echo "⏳ Warte 5 Sekunden auf Service-Start..."
sleep 5
echo ""

# Check service status
echo "📊 Service-Status:"
echo "=================="
systemctl status "$SERVICE_NAME.service" --no-pager || true
echo ""

# Show logs
echo "📋 Letzte Log-Einträge:"
echo "======================="
tail -n 20 "$LOG_FILE"
echo ""

# Success message
echo "✅ Installation erfolgreich abgeschlossen!"
echo ""
echo "📌 Wichtige Befehle:"
echo "  Status prüfen:  sudo systemctl status $SERVICE_NAME"
echo "  Logs anzeigen:  tail -f $LOG_FILE"
echo "  Live-Logs:      sudo journalctl -u $SERVICE_NAME -f"
echo "  Neustart:       sudo systemctl restart $SERVICE_NAME"
echo "  Stoppen:        sudo systemctl stop $SERVICE_NAME"
echo "  Deaktivieren:   sudo systemctl disable $SERVICE_NAME"
echo ""
echo "🎉 Der Chat-Sync-Daemon läuft jetzt im Hintergrund!"
echo ""
