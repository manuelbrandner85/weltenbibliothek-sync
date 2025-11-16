# 🚀 Schnellanleitung: APK in 3 Minuten

## ✅ Automatischer Build über GitHub Actions

### Schritt 1: Code zu GitHub pushen
```bash
# Einmalig: GitHub Environment einrichten
setup_github_environment

# Code pushen
git push origin main
```

### Schritt 2: APK herunterladen
1. Gehe zu: https://github.com/DEIN-USERNAME/DEIN-REPO/actions
2. Warte 5-10 Minuten bis Build fertig ist ✓
3. Klicke auf den Workflow → Artifacts → Download `weltenbibliothek-debug.apk`

### Schritt 3: Auf Handy installieren
1. Übertrage APK auf dein Android-Handy
2. Aktiviere "Unbekannte Quellen" in den Einstellungen
3. Öffne die APK-Datei
4. Installieren → Fertig! 🎉

---

## 📱 Was ist in der APK enthalten?

✅ Komplette Weltenbibliothek-App  
✅ Chat (💬 Allgemein + 🎵 Musik)  
✅ Livestreaming mit Agora  
✅ KI-Chat mit Google Gemini  
✅ Weltkarte mit Events  
✅ Cost Protection System  
✅ Offline-Modus  
✅ Push-Benachrichtigungen (in Vorbereitung)  

---

## ⚠️ Wichtig: Backend-Verbindung

Die APK ist nur das **Frontend** (die App). Das **Backend** läuft auf:
- **Aktuell**: Sandbox (http://localhost:3000)
- **Produktiv**: Cloudflare Pages (nach Deployment)

### Nach Cloudflare Deployment:

Bearbeite `capacitor.config.ts`:
```typescript
server: {
  url: 'https://weltenbibliothek.pages.dev',
  cleartext: true
}
```

Dann APK neu bauen!

---

## 🔥 Pro-Tipp: Continuous Deployment

Bei jedem `git push origin main` wird automatisch eine neue APK gebaut!

1. Ändere Code
2. Commit & Push
3. Neue APK in 10 Minuten fertig
4. Download & Installieren

---

## 📞 Support

Bei Problemen:
- Schaue in `APK_BUILD_GUIDE.md` für detaillierte Anleitung
- Prüfe Android Studio Logcat für Fehler
- Teste zuerst im Browser: http://localhost:3000

---

**Build-Status prüfen:**  
https://github.com/DEIN-USERNAME/DEIN-REPO/actions

**GitHub Actions Workflow:**  
`.github/workflows/android-build.yml`
