#!/bin/bash
##############################################################################
# 🛑 STOP ALL TELEGRAM CHANNEL SYNC DAEMONS
##############################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🛑 STOPPE ALLE TELEGRAM CHANNEL SYNC DAEMONS             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🛑 Stoppe alle Channel-Daemons..."
echo ""

pkill -f "sync_chat.php" 2>/dev/null && echo "   ✅ Chat-Daemon gestoppt"
pkill -f "sync_pdfs.php" 2>/dev/null && echo "   ✅ PDFs-Daemon gestoppt"
pkill -f "sync_bilder.php" 2>/dev/null && echo "   ✅ Bilder-Daemon gestoppt"
pkill -f "sync_wachauf.php" 2>/dev/null && echo "   ✅ Wachauf-Daemon gestoppt"
pkill -f "sync_archiv.php" 2>/dev/null && echo "   ✅ Archiv-Daemon gestoppt"
pkill -f "sync_hoerbuch.php" 2>/dev/null && echo "   ✅ Hörbuch-Daemon gestoppt"

sleep 2

echo ""
echo "📊 Überprüfe Prozesse..."
REMAINING=$(ps aux | grep -E "sync_(chat|pdfs|bilder|wachauf|archiv|hoerbuch).php" | grep -v grep | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ Alle Daemons erfolgreich gestoppt!"
else
    echo "⚠️  Noch $REMAINING Prozesse aktiv"
    ps aux | grep -E "sync_(chat|pdfs|bilder|wachauf|archiv|hoerbuch).php" | grep -v grep
fi

echo ""
