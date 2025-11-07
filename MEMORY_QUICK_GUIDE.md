# 🚀 FLUTTER MEMORY - QUICK REFERENCE

---

## ⚡ SOFORT-HILFE BEI RAM-PROBLEMEN

### 🛑 **NOTFALL: Build hängt oder System langsam?**

```bash
# Sofort alle Build-Prozesse beenden
/home/user/kill_build_processes.sh
```

**Effekt:** Gibt sofort ~600-800 MB RAM frei!

---

## 📋 SICHERE BUILD-METHODEN

### ✅ **METHODE 1: Memory-optimierter APK Build** (EMPFOHLEN)

```bash
# Nutze das sichere Build-Script
/home/user/build_safe.sh
```

**Vorteile:**
- ✅ Automatisches Cleanup
- ✅ Memory-Monitoring
- ✅ Daemon-Stopp vor Build
- ✅ Optimierte Gradle Settings

**Dauer:** ~90 Sekunden  
**RAM-Bedarf:** ~2-2.5 GB (statt 3+ GB)

---

### ✅ **METHODE 2: Web Build** (SCHNELLSTE, NIEDRIGSTER RAM)

```bash
cd /home/user/flutter_app

# Cleanup
rm -rf build/web

# Build
flutter build web --release

# Serve
cd build/web
python3 -m http.server 5060 --bind 0.0.0.0 > /tmp/flutter_web.log 2>&1 &
```

**Vorteile:**
- ✅ Nur ~500 MB RAM
- ✅ Sehr schnell (30-60 Sek)
- ✅ Kein Gradle/Kotlin
- ✅ Sofort testbar

**Nachteile:**
- ❌ Keine native Android-App
- ❌ Nur für Testing/Demo

**Dauer:** 30-60 Sekunden  
**RAM-Bedarf:** ~500 MB

---

### ✅ **METHODE 3: Manueller Build mit Cleanup**

```bash
cd /home/user/flutter_app

# 1. Cleanup
pkill -f kotlin.daemon
rm -rf .gradle build android/.gradle android/build
cd android && ./gradlew --stop && cd ..

# 2. Build
flutter pub get
flutter build apk --release --split-per-abi

# 3. Kopiere zu Downloads
cp build/app/outputs/flutter-apk/*.apk build/web/downloads/
```

**Dauer:** ~90 Sekunden  
**RAM-Bedarf:** ~2.5 GB

---

## 🔧 OPTIMIERUNGEN (BEREITS AKTIVIERT)

**In `android/gradle.properties`:**
```properties
✅ Gradle Max Heap: 2048M (reduziert von 2560M)
✅ Kotlin Daemon: 1024M (neu hinzugefügt)
✅ Gradle Daemon: OFF (verhindert Memory-Leaks)
✅ Parallele Builds: OFF (spart ~800 MB)
✅ Gradle Caching: OFF (spart ~200 MB)
✅ Worker Max: 1 (nur ein Build-Prozess)
```

---

## 📊 MEMORY-VERBRAUCH ÜBERSICHT

| **Build-Methode** | **RAM-Bedarf** | **Dauer** | **Output** |
|------------------|----------------|-----------|-----------|
| **Web Build** | ~500 MB | 30-60s | Web-App ✅ |
| **APK (optimiert)** | ~2-2.5 GB | ~90s | Native APK ✅ |
| **APK (standard)** | ~3+ GB | ~90s | Native APK ⚠️ |

---

## 🎯 WANN WELCHE METHODE?

### **FÜR SCHNELLE TESTS:**
👉 **Web Build** (Methode 2)
- Schnell testen ob Code funktioniert
- UI-Änderungen verifizieren
- Demo für andere

### **FÜR APK-RELEASES:**
👉 **Memory-optimierter Build** (Methode 1)
- Finale APK für Distribution
- Test auf echten Geräten
- Google Play Store Upload

### **BEI RAM-PROBLEMEN:**
👉 **Erst Cleanup, dann Build** (Methode 3)
- Wenn Methode 1 abstürzt
- Wenn System schon ausgelastet
- Schrittweise Kontrolle

---

## 🐛 TROUBLESHOOTING

### **Problem: Build stürzt mit "Out of Memory" ab**

**Lösung 1: Cleanup & Retry**
```bash
/home/user/kill_build_processes.sh
sleep 5
/home/user/build_safe.sh
```

**Lösung 2: Nur ARM64 bauen**
```bash
cd /home/user/flutter_app
flutter build apk --release --target-platform android-arm64
```
*Generiert nur 1 APK statt 3 - spart ~30% RAM*

**Lösung 3: Web Build verwenden**
```bash
flutter build web --release
```
*Nur ~500 MB RAM benötigt*

---

### **Problem: Kotlin Daemon verbraucht 600+ MB**

**Lösung:**
```bash
# Daemon beenden
pkill -f kotlin.daemon

# Oder Script nutzen
/home/user/kill_build_processes.sh
```

---

### **Problem: Gradle hängt bei "Resolving dependencies"**

**Lösung:**
```bash
# Gradle stoppen
cd /home/user/flutter_app/android
./gradlew --stop

# Caches löschen
rm -rf ~/.gradle/caches/
rm -rf .gradle/

# Neu versuchen
cd ..
flutter pub get
```

---

## 📁 WICHTIGE PFADE

**Build Scripts:**
- `/home/user/build_safe.sh` - Sicherer APK Build
- `/home/user/kill_build_processes.sh` - Prozesse beenden

**APK Output:**
- `/home/user/flutter_app/build/app/outputs/flutter-apk/*.apk`
- `/home/user/flutter_app/build/web/downloads/*.apk` (Kopie)

**Logs:**
- `/tmp/flutter_web.log` - Web Server Log
- `/tmp/flutter_server.log` - Flutter Server Log
- `/tmp/php_backend.log` - PHP Backend Log

**Config:**
- `/home/user/flutter_app/android/gradle.properties` - Gradle Memory Settings

---

## 💡 TIPPS & TRICKS

### **1. Memory Monitor während Build:**
```bash
# Terminal 1: Monitor
watch -n 1 'free -h'

# Terminal 2: Build
/home/user/build_safe.sh
```

### **2. Vor jedem Build aufräumen:**
```bash
# Füge zu deinem Workflow hinzu:
alias flutter-clean='cd /home/user/flutter_app && /home/user/kill_build_processes.sh && rm -rf build .gradle android/build'
```

### **3. Nutze Web-Build für Entwicklung:**
```bash
# Entwicklungs-Workflow:
flutter build web --release && cd build/web && python3 -m http.server 5060 --bind 0.0.0.0 &

# APK nur für finale Releases
```

---

## ✅ CHECKLISTE FÜR ERFOLGREICHEN BUILD

- [ ] Aktuelle Memory-Nutzung < 4 GB
- [ ] Keine laufenden Kotlin/Gradle Daemons
- [ ] Build-Cache gelöscht
- [ ] Gradle Settings optimiert
- [ ] Richtige Build-Methode gewählt
- [ ] Backup der letzten APK vorhanden

---

## 🆘 WENN ALLES FEHLSCHLÄGT

### **Letzte Option: Externe Build-Maschine**

1. **Code exportieren:**
```bash
cd /home/user
tar -czf flutter_source.tar.gz flutter_app/
```

2. **Auf lokalem Rechner bauen:**
```bash
# Download tar.gz
tar -xzf flutter_source.tar.gz
cd flutter_app
flutter pub get
flutter build apk --release --split-per-abi
```

3. **APK zurück kopieren**

---

## 📞 QUICK COMMANDS ÜBERSICHT

```bash
# Build-Prozesse stoppen
/home/user/kill_build_processes.sh

# Sicherer APK Build
/home/user/build_safe.sh

# Schneller Web Build
cd /home/user/flutter_app && flutter build web --release

# Memory Check
free -h

# Laufende Builds prüfen
ps aux | grep -E "kotlin|gradle|java" | grep -v grep

# Alle Caches löschen
cd /home/user/flutter_app && rm -rf .gradle build android/.gradle android/build
```

---

**🎯 EMPFEHLUNG: Nutze `/home/user/build_safe.sh` für APK-Builds!**
