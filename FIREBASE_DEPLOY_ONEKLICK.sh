#!/bin/bash
###############################################################################
# 🔥 FIREBASE ONE-CLICK DEPLOYMENT
###############################################################################
# Weltenbibliothek v3.0.0+84
# Project ID: weltenbibliothek-5d21f
#
# Dieses Skript deployed automatisch:
# - Firestore Indexes
# - Firestore Security Rules  
# - Storage Rules
###############################################################################

set -e  # Exit bei Fehler

PROJECT_ID="weltenbibliothek-5d21f"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔥 FIREBASE ONE-CLICK DEPLOYMENT"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Project: Weltenbibliothek v3.0.0+84"
echo "Project ID: $PROJECT_ID"
echo ""

# ─────────────────────────────────────────────────────────────────
# SCHRITT 1: Voraussetzungen prüfen
# ─────────────────────────────────────────────────────────────────

echo "🔍 Prüfe Voraussetzungen..."
echo ""

# Firebase CLI installiert?
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI nicht gefunden!"
    echo ""
    echo "Bitte installiere Firebase CLI:"
    echo "npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "✅ Firebase CLI gefunden: $(firebase --version)"

# Konfigurationsdateien vorhanden?
if [ ! -f "firestore.indexes.json" ]; then
    echo "❌ firestore.indexes.json nicht gefunden!"
    exit 1
fi

if [ ! -f "firestore.rules" ]; then
    echo "❌ firestore.rules nicht gefunden!"
    exit 1
fi

if [ ! -f "storage.rules" ]; then
    echo "❌ storage.rules nicht gefunden!"
    exit 1
fi

echo "✅ Alle Konfigurationsdateien gefunden"
echo ""

# ─────────────────────────────────────────────────────────────────
# SCHRITT 2: Firebase Login
# ─────────────────────────────────────────────────────────────────

echo "🔐 Prüfe Firebase Login..."
echo ""

if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Nicht eingeloggt. Starte Login..."
    firebase login
else
    echo "✅ Firebase Login aktiv"
fi

echo ""

# ─────────────────────────────────────────────────────────────────
# SCHRITT 3: Projekt initialisieren (falls nötig)
# ─────────────────────────────────────────────────────────────────

if [ ! -f ".firebaserc" ]; then
    echo "📝 Erstelle .firebaserc..."
    cat > .firebaserc << EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF
    echo "✅ .firebaserc erstellt"
else
    echo "✅ .firebaserc existiert bereits"
fi

echo ""

# ─────────────────────────────────────────────────────────────────
# SCHRITT 4: Deployment
# ─────────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════"
echo "🚀 STARTE DEPLOYMENT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Firestore Indexes
echo "📊 Deploye Firestore Indexes..."
firebase deploy --only firestore:indexes --project $PROJECT_ID

echo ""
echo "✅ Firestore Indexes deployed!"
echo "⏳ Index-Erstellung läuft im Hintergrund (5-15 Minuten)"
echo ""

# Firestore Rules
echo "🔒 Deploye Firestore Security Rules..."
firebase deploy --only firestore:rules --project $PROJECT_ID

echo ""
echo "✅ Firestore Rules deployed!"
echo ""

# Storage Rules
echo "🗄️  Deploye Storage Rules..."
firebase deploy --only storage --project $PROJECT_ID

echo ""
echo "✅ Storage Rules deployed!"
echo ""

# ─────────────────────────────────────────────────────────────────
# SCHRITT 5: Erfolgsmeldung
# ─────────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════"
echo "🎉 DEPLOYMENT ERFOLGREICH ABGESCHLOSSEN!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Firestore Indexes: Deployed (Erstellung läuft)"
echo "✅ Firestore Rules: Aktiv"
echo "✅ Storage Rules: Aktiv"
echo ""
echo "📊 Überwache Index-Erstellung:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/firestore/indexes"
echo ""
echo "🔐 Teste Security Rules:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/firestore/rules"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "⚠️  WICHTIG: Index-Erstellung kann 5-15 Minuten dauern!"
echo "    Prüfe den Status in der Firebase Console."
echo ""
echo "🧪 NÄCHSTE SCHRITTE:"
echo "   1. Warte auf Index-Erstellung (Firebase Console)"
echo "   2. Teste Rules im Rules Playground"
echo "   3. Teste App mit neuen Indexes"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

