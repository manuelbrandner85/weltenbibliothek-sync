#!/bin/bash
##############################################################################
# 🚀 START ALL TELEGRAM CHANNEL SYNC DAEMONS
##############################################################################

SCRIPT_DIR="/home/user/flutter_app/scripts"
cd "$SCRIPT_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🚀 STARTE ALLE TELEGRAM CHANNEL SYNC DAEMONS             ║"
echo "║     6 Kanäle → Firestore + FTP Integration                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Stop existing daemons
echo "🛑 Stoppe existierende Daemons..."
pkill -f "sync_chat.php" 2>/dev/null
pkill -f "sync_pdfs.php" 2>/dev/null
pkill -f "sync_bilder.php" 2>/dev/null
pkill -f "sync_wachauf.php" 2>/dev/null
pkill -f "sync_archiv.php" 2>/dev/null
pkill -f "sync_hoerbuch.php" 2>/dev/null
sleep 2
echo "✅ Alte Daemons gestoppt"
echo ""

# Ensure logs directory exists
mkdir -p logs

# Start each channel daemon
echo "📺 Starte Channel-Daemons..."
echo ""

# 1. Chat Channel
echo "   🔹 Chat (@Weltenbibliothekchat)"
nohup php sync_chat.php > logs/channel_chat.log 2>&1 &
CHAT_PID=$!
echo "      ✅ PID: $CHAT_PID"
sleep 1

# 2. PDFs Channel
echo "   🔹 PDFs (@WeltenbibliothekPDF)"
nohup php sync_pdfs.php > logs/channel_pdfs.log 2>&1 &
PDFS_PID=$!
echo "      ✅ PID: $PDFS_PID"
sleep 1

# 3. Bilder Channel
echo "   🔹 Bilder (@weltenbibliothekbilder)"
nohup php sync_bilder.php > logs/channel_bilder.log 2>&1 &
BILDER_PID=$!
echo "      ✅ PID: $BILDER_PID"
sleep 1

# 4. Wachauf Channel
echo "   🔹 Wachauf (@WeltenbibliothekWachauf)"
nohup php sync_wachauf.php > logs/channel_wachauf.log 2>&1 &
WACHAUF_PID=$!
echo "      ✅ PID: $WACHAUF_PID"
sleep 1

# 5. Archiv Channel
echo "   🔹 Archiv (@ArchivWeltenBibliothek)"
nohup php sync_archiv.php > logs/channel_archiv.log 2>&1 &
ARCHIV_PID=$!
echo "      ✅ PID: $ARCHIV_PID"
sleep 1

# 6. Hörbuch Channel
echo "   🔹 Hörbuch (@WeltenbibliothekHoerbuch)"
nohup php sync_hoerbuch.php > logs/channel_hoerbuch.log 2>&1 &
HOERBUCH_PID=$!
echo "      ✅ PID: $HOERBUCH_PID"
sleep 1

echo ""
echo "✅ Alle Channel-Daemons gestartet!"
echo ""

echo "📊 Aktive Prozesse:"
ps aux | grep -E "sync_(chat|pdfs|bilder|wachauf|archiv|hoerbuch).php" | grep -v grep
echo ""

echo "📋 Log-Dateien:"
echo "   logs/channel_chat.log     - Chat-Nachrichten"
echo "   logs/channel_pdfs.log     - PDF-Dokumente"
echo "   logs/channel_bilder.log   - Bilder"
echo "   logs/channel_wachauf.log  - Wachauf-Inhalte"
echo "   logs/channel_archiv.log   - Archiv-Einträge"
echo "   logs/channel_hoerbuch.log - Hörbücher"
echo ""

echo "🔍 Überwachung (Beispiele):"
echo "   tail -f logs/channel_chat.log"
echo "   tail -f logs/channel_pdfs.log"
echo ""

echo "🛑 Alle Daemons stoppen:"
echo "   bash stop_all_channels.sh"
echo ""
