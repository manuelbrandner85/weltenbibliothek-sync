#!/bin/bash
##############################################################################
# 📦 CREATE INDIVIDUAL CHANNEL DAEMON SCRIPTS
##############################################################################
# 
# Erstellt separate PHP-Skripte für jeden Kanal basierend auf dem
# Master-Template telegram_chat_sync_madeline.php
#
##############################################################################

SCRIPT_DIR="/home/user/flutter_app/scripts"
cd "$SCRIPT_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  📦 ERSTELLE CHANNEL-SPEZIFISCHE DAEMON-SKRIPTE           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Ensure logs directory exists
mkdir -p logs

# Channel configurations: name|username|collection|ftpPath
declare -a CHANNELS=(
    "chat|@Weltenbibliothekchat|chat_messages|/chat/"
    "pdfs|@WeltenbibliothekPDF|pdf_documents|/pdfs/"
    "bilder|@weltenbibliothekbilder|images|/images/"
    "wachauf|@WeltenbibliothekWachauf|wachauf_content|/wachauf/"
    "archiv|@ArchivWeltenBibliothek|archive_items|/archiv/"
    "hoerbuch|@WeltenbibliothekHoerbuch|audiobooks|/audios/"
)

for channel_config in "${CHANNELS[@]}"; do
    IFS='|' read -r name username collection ftpPath <<< "$channel_config"
    
    output_file="sync_${name}.php"
    
    echo "🔹 Erstelle: $output_file"
    echo "   Channel: $username"
    echo "   Collection: $collection"
    echo "   FTP Path: $ftpPath"
    
    # Copy master template and modify configuration
    cp telegram_chat_sync_madeline_backup.php "$output_file"
    
    # Replace configuration values using sed
    sed -i "s|@Weltenbibliothekchat|$username|g" "$output_file"
    sed -i "s|'chat_messages'|'$collection'|g" "$output_file"
    sed -i "s|'/chat/'|'$ftpPath'|g" "$output_file"
    sed -i "s|:8080/chat|:8080${ftpPath%/}|g" "$output_file"
    sed -i "s|TELEGRAM CHAT BIDIREKTIONALE|CHANNEL $name BIDIREKTIONALE|g" "$output_file"
    
    echo "   ✅ Erstellt"
    echo ""
done

echo "✅ Alle Channel-Daemon-Skripte erstellt!"
echo ""
echo "📋 Erstellte Dateien:"
ls -lh sync_*.php
echo ""
