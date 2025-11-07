# 🔄 AUTOMATISCHES SERVICE MONITORING & RESTART

**Problem gelöst:** "Check service restart if not" - Services werden jetzt automatisch überwacht und neu gestartet!

---

## 🎯 WAS WURDE IMPLEMENTIERT?

### **Intelligentes 3-Stufen-System:**

```
1. SERVICE MONITOR     → Prüft & startet Services bei Bedarf
2. SERVICE WATCHDOG    → Überwacht kontinuierlich (alle 60s)
3. AUTO-RESTART        → Startet abgestürzte Services automatisch neu
```

---

## 📋 VERFÜGBARE SCRIPTS

### 1️⃣ **`/home/user/service_monitor.sh`** - Einmalige Prüfung & Restart

**Funktion:**
- Prüft ob Flutter Web (Port 5060) läuft
- Prüft ob PHP Backend (Port 8080) läuft
- Startet fehlende Services automatisch neu
- Testet HTTP-Erreichbarkeit

**Verwendung:**
```bash
/home/user/service_monitor.sh
```

**Output:**
```
✅ Flutter Web Server läuft (Port 5060)
✅ PHP Backend läuft (Port 8080)
✅ Flutter Web: HTTP 200 OK
✅ PHP Backend: HTTP 200 OK
🎉 ALLE SERVICES ONLINE!
```

---

### 2️⃣ **`/home/user/service_watchdog.sh`** - Kontinuierliche Überwachung

**Funktion:**
- Läuft dauerhaft im Hintergrund
- Prüft alle 60 Sekunden die Services
- Startet automatisch neu bei Absturz
- Loggt alle Aktionen

**Verwendung:**
```bash
# Im Hintergrund starten
nohup /home/user/service_watchdog.sh > /dev/null 2>&1 &

# Logs anzeigen
tail -f /tmp/service_watchdog.log
```

---

### 3️⃣ **`/home/user/start_services.sh`** - Alles-in-einem Starter ⭐

**Funktion:**
- Startet alle Services
- Aktiviert automatisches Monitoring
- Startet Watchdog im Hintergrund
- Zeigt Status & URLs

**Verwendung:**
```bash
/home/user/start_services.sh
```

**Output:**
```
🚀 STARTE WELTENBIBLIOTHEK SERVICES...

✅ Flutter Web Server erfolgreich gestartet!
✅ PHP Backend erfolgreich gestartet!
🐕 Watchdog PID: 12345

========================================
✅ SERVICES GESTARTET & ÜBERWACHT
========================================

🌐 Flutter Web: http://localhost:5060/
🔧 PHP Backend:  http://localhost:8080/

📊 Monitoring:
   - Auto-Check: alle 60 Sekunden
   - Auto-Restart: bei Absturz
   - Logs: /tmp/service_monitor.log
```

---

### 4️⃣ **`/home/user/stop_services.sh`** - Sauberes Herunterfahren

**Funktion:**
- Stoppt Watchdog
- Stoppt Flutter Web Server
- Stoppt PHP Backend
- Zeigt Bestätigung

**Verwendung:**
```bash
/home/user/stop_services.sh
```

---

## 🚀 SCHNELLSTART

### **Empfohlener Workflow:**

```bash
# 1. Services starten mit Auto-Monitoring
/home/user/start_services.sh

# 2. App nutzen...

# 3. Bei Bedarf Status prüfen
/home/user/service_monitor.sh

# 4. Logs anzeigen
tail -f /tmp/service_monitor.log
tail -f /tmp/service_watchdog.log

# 5. Services stoppen (optional)
/home/user/stop_services.sh
```

---

## 🔍 WIE FUNKTIONIERT ES?

### **Automatische Erkennung:**

```bash
# Der Monitor prüft:
1. Ist Port 5060 offen? (Flutter)
   ❌ Nein → Starte Flutter Web Server
   ✅ Ja  → Nächster Check

2. Ist Port 8080 offen? (PHP)
   ❌ Nein → Starte PHP Backend
   ✅ Ja  → Nächster Check

3. HTTP 200 OK? (beide)
   ❌ Nein → Warnung in Logs
   ✅ Ja  → Alles OK!
```

### **Auto-Restart Logik:**

```bash
# Bei fehlendem Service:
1. Stoppe alte Prozesse (falls hängend)
2. Prüfe ob Dateien vorhanden sind
3. Starte Service neu
4. Warte 3 Sekunden
5. Verifiziere erfolgreichen Start
6. Logge Ergebnis
```

### **Watchdog-Schleife:**

```bash
while true; do
    # Führe Monitor aus
    bash /home/user/service_monitor.sh
    
    # Warte 60 Sekunden
    sleep 60
done
```

---

## 📊 LOGS & MONITORING

### **Log-Dateien:**

```bash
# Service Monitor Log (alle Checks & Restarts)
tail -f /tmp/service_monitor.log

# Watchdog Log (kontinuierliche Überwachung)
tail -f /tmp/service_watchdog.log

# Flutter Server Log (Web-Server Ausgabe)
tail -f /tmp/flutter_server.log

# PHP Backend Log (Backend Ausgabe)
tail -f /tmp/php_backend.log
```

### **Live-Monitoring:**

```bash
# Terminal 1: Watchdog Logs
watch -n 1 'tail -20 /tmp/service_watchdog.log'

# Terminal 2: Service Status
watch -n 5 'lsof -i :5060,8080 | grep LISTEN'

# Terminal 3: Memory
watch -n 5 'free -h'
```

---

## 🎯 VERWENDUNGSSZENARIEN

### **Szenario 1: Nach System-Neustart**

```bash
# Einfach starten:
/home/user/start_services.sh

# → Watchdog überwacht ab jetzt automatisch
```

---

### **Szenario 2: Service ist abgestürzt**

```bash
# Watchdog erkennt automatisch und startet neu:
[2025-11-07 10:45:00] ⚠️ Flutter Web Server nicht aktiv - Starte neu...
[2025-11-07 10:45:03] ✅ Flutter Web Server erfolgreich gestartet!
```

**Du musst nichts tun!** ✅

---

### **Szenario 3: Manuelle Prüfung**

```bash
# Prüfe sofort:
/home/user/service_monitor.sh

# Zeigt:
✅ Flutter Web Server läuft (Port 5060)
✅ PHP Backend läuft (Port 8080)
🎉 ALLE SERVICES ONLINE!
```

---

### **Szenario 4: Während Flutter Build**

```bash
# Services laufen weiter während Build
/home/user/build_safe.sh

# Watchdog überwacht parallel und startet Services neu falls nötig
```

---

## ⚙️ KONFIGURATION

### **Prüfintervall ändern:**

Edit `/home/user/service_watchdog.sh`:
```bash
INTERVAL=60  # Sekunden (Standard: 60)

# Beispiele:
INTERVAL=30   # Alle 30 Sekunden (intensiver)
INTERVAL=120  # Alle 2 Minuten (sparsamer)
INTERVAL=300  # Alle 5 Minuten (sehr sparsam)
```

### **Ports ändern:**

Edit `/home/user/service_monitor.sh`:
```bash
FLUTTER_PORT=5060  # Standard
PHP_PORT=8080      # Standard
```

---

## 🐛 TROUBLESHOOTING

### **Problem: Watchdog läuft nicht**

**Prüfen:**
```bash
ps aux | grep service_watchdog
```

**Neu starten:**
```bash
/home/user/start_services.sh
```

---

### **Problem: Services starten nicht automatisch**

**Logs prüfen:**
```bash
tail -50 /tmp/service_monitor.log
```

**Manuell testen:**
```bash
/home/user/service_monitor.sh
```

---

### **Problem: Zu viele Restarts**

**Watchdog stoppen:**
```bash
pkill -f service_watchdog.sh

# Oder:
/home/user/stop_services.sh
```

**Problem beheben, dann neu starten:**
```bash
/home/user/start_services.sh
```

---

## 📝 BEISPIEL-LOGS

### **Erfolgreicher Check:**
```
[2025-11-07 10:30:06] ==========================================
[2025-11-07 10:30:06] 🔍 SERVICE MONITOR GESTARTET
[2025-11-07 10:30:06] ==========================================
[2025-11-07 10:30:07] ✅ Flutter Web Server läuft (Port 5060)
[2025-11-07 10:30:07] ✅ PHP Backend läuft (Port 8080)
[2025-11-07 10:30:09] ✅ Flutter Web: HTTP 200 OK
[2025-11-07 10:30:09] ✅ PHP Backend: HTTP 200 OK
[2025-11-07 10:30:09] ✅ ALLE SERVICES LAUFEN KORREKT
```

### **Auto-Restart:**
```
[2025-11-07 11:00:00] ⚠️ Flutter Web Server nicht aktiv - Starte neu...
[2025-11-07 11:00:02] 🔧 Führe Flutter Web Build aus...
[2025-11-07 11:00:45] ✅ Flutter Web Server erfolgreich gestartet!
[2025-11-07 11:00:48] ✅ Flutter Web: HTTP 200 OK
[2025-11-07 11:00:48] ✅ ALLE SERVICES LAUFEN KORREKT
```

---

## ✅ VORTEILE DIESES SYSTEMS

| **Feature** | **Beschreibung** |
|------------|------------------|
| ✅ **Automatisch** | Keine manuelle Überwachung nötig |
| ✅ **Schnell** | Erkennt Abstürze innerhalb 60s |
| ✅ **Zuverlässig** | Startet Services automatisch neu |
| ✅ **Transparent** | Alle Aktionen werden geloggt |
| ✅ **Ressourcen-schonend** | Nur ~1 MB RAM |
| ✅ **Einfach** | Ein Befehl zum Starten |

---

## 🎯 ZUSAMMENFASSUNG

**Du musst jetzt:**
1. ✅ **Einmal starten:** `/home/user/start_services.sh`
2. ✅ **Fertig!** Services werden automatisch überwacht

**Das System macht:**
- 🔄 Prüft alle 60 Sekunden
- 🚀 Startet abgestürzte Services neu
- 📝 Loggt alle Aktionen
- ✅ Läuft dauerhaft im Hintergrund

---

## 📞 QUICK COMMANDS

```bash
# Services starten + Monitoring aktivieren
/home/user/start_services.sh

# Services prüfen (einmalig)
/home/user/service_monitor.sh

# Services stoppen
/home/user/stop_services.sh

# Logs anzeigen
tail -f /tmp/service_monitor.log
tail -f /tmp/service_watchdog.log

# Watchdog Status
ps aux | grep service_watchdog
```

---

**🎉 PROBLEM GELÖST: Services werden jetzt automatisch überwacht und neu gestartet!** 🎉
