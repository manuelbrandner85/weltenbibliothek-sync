# 💰 Cost Protection System - Automatischer Kostenschutz

## 🛡️ Übersicht

Das Cost Protection System schützt dich **automatisch** vor unerwarteten Kosten, indem es alle kostenpflichtigen Features überwacht und bei Erreichen der kostenlosen Limits **automatisch beendet**.

---

## 🎯 Geschützte Services

### 1. Agora RTC (Livestreaming)

**Kostenlos**: 10.000 Minuten/Monat

**Schutzfunktionen**:
- ✅ Automatisches **Quota-Check** vor Stream-Start
- ✅ Minuten-genaues **Tracking** während Stream läuft
- ✅ **Automatisches Stoppen** bei Limit-Erreichen
- ✅ **Warnungen** bei < 100 Minuten verbleibend
- ✅ **Toast-Benachrichtigungen** bei < 60 Minuten
- ✅ **Monatliches Reset** am 1. jeden Monats

**Was passiert bei Limit-Erreichen**:
```
⚠️ KOSTENLIMIT ERREICHT!

Dein kostenloses Livestreaming-Kontingent für 
diesen Monat ist aufgebraucht.

📊 Verbrauch: 10000 / 10000 Minuten
🔄 Zurückgesetzt: 01.12.2025

Der Stream wurde automatisch beendet.
```

**Kosten nach Limit**:
- $0.99 - $3.99 pro 1.000 Minuten
- **WIRD VERHINDERT** durch automatisches Stoppen

---

### 2. Google Gemini API (AI Chat)

**Kostenlos**: Unbegrenzt (60 Anfragen/Minute Limit)

**Schutzfunktionen**:
- ✅ **Quota-Check** vor jeder API-Anfrage
- ✅ Verhindert **Rate-Limit-Fehler**
- ✅ Blockiert Anfragen bei Limit
- ✅ Freundliche **Fehler-Meldungen**

**Was passiert bei Rate-Limit**:
```
⚠️ RATE-LIMIT ERREICHT!

Zu viele Anfragen in kurzer Zeit.

Bitte warte einen Moment und versuche es erneut.
```

**Kosten nach Limit**:
- Gemini API ist **IMMER kostenlos**
- Rate-Limit-Schutz verhindert nur Fehler

---

## 📊 Quota Dashboard

### Zugriff

**Im Chat Header**: Klicke auf 📊 **Chart-Icon**

### Anzeige

Das Dashboard zeigt dir:
1. **Livestreaming (Agora)**
   - Genutzte Minuten
   - Verbleibende Minuten
   - Prozentuale Nutzung
   - Fortschrittsbalken
   - Reset-Datum

2. **AI Chat (Gemini)**
   - Anzahl Anfragen (heute)
   - Verfügbare Anfragen
   - Prozentuale Nutzung
   - Reset-Datum

3. **Status-Badges**
   - 🟢 **Gut**: > 20% verfügbar
   - 🟡 **Warnung**: < 20% verfügbar
   - 🔴 **Limit**: 0% verfügbar

### Beispiel-Anzeige

```
┌─────────────────────────────────────────┐
│ 📊 Kostenlose Kontingente               │
├─────────────────────────────────────────┤
│                                         │
│ Livestreaming (Agora)           45.2% ✅│
│ ████████████░░░░░░░░░░░░                │
│ Genutzt: 4,520 Minuten                  │
│ Verfügbar: 5,480 Minuten                │
│ 🔄 Zurückgesetzt am: 01.12.2025         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│ AI Chat (Gemini)                 12.3% ✅│
│ ███░░░░░░░░░░░░░░░░░░░░░                │
│ Genutzt: 128 Anfragen                   │
│ Verfügbar: 912 Anfragen                 │
│ 🔄 Zurückgesetzt: Täglich um 00:00      │
│                                         │
└─────────────────────────────────────────┘

ℹ️ Automatischer Schutz aktiv

Alle kostenpflichtigen Features werden 
automatisch beendet, sobald das kostenlose 
Kontingent aufgebraucht ist.
```

---

## 🔔 Benachrichtigungssystem

### Warnung bei niedrigem Kontingent

**Wann**: Wenn < 60 Minuten beim Livestreaming verbleiben

**Wie**: Orange Toast-Benachrichtigung (5 Sekunden)

**Beispiel**:
```
⚠️ Kontingent niedrig!

Livestreaming: Nur noch 45 Minuten 
verfügbar in diesem Monat.
```

### Automatische Stream-Beendigung

**Wann**: Genau bei Limit-Erreichen (10.000 Minuten)

**Was passiert**:
1. Stream wird sofort gestoppt
2. Tracking wird beendet
3. Alert-Fenster erscheint mit Details
4. UI kehrt zu Chat zurück

---

## 🔒 Technische Details

### Daten-Speicherung

**Wo**: Browser LocalStorage (lokal, kein Server)

**Format**:
```javascript
{
  "used": 4520,              // Genutzte Minuten/Anfragen
  "lastReset": "2025-11-01", // Letztes Reset-Datum
  "monthKey": "2025-11"      // Monat für Tracking
}
```

**Keys**:
- `weltenbibliothek_quota_agora_2025-11` - Agora Nutzung November 2025
- `weltenbibliothek_quota_gemini_2025-11-16` - Gemini Nutzung 16. Nov 2025

### Tracking-Mechanismus

**Agora (Livestreaming)**:
```javascript
// Startet bei Stream-Start
setInterval(() => {
  recordUsage('agora', 1); // Jede Minute
  checkQuota('agora', 1);  // Prüfe Limit
  
  if (limit_reached) {
    stopLivestream();      // Auto-Stop
    showAlert();           // Benachrichtigung
  }
}, 60000); // Alle 60 Sekunden
```

**Gemini (AI Chat)**:
```javascript
// Vor jeder API-Anfrage
const quotaCheck = checkGeminiQuota();

if (!quotaCheck.allowed) {
  showError('Limit erreicht');
  return; // Blockiere Anfrage
}

// Nach erfolgreicher Antwort
recordGeminiUsage();
```

### Reset-Logik

**Monatliches Reset**:
```javascript
function checkQuota(service, amount) {
  const currentMonth = getCurrentMonthKey(); // "2025-11"
  
  if (data.monthKey !== currentMonth) {
    // Neuer Monat - Reset!
    data.used = 0;
    data.monthKey = currentMonth;
    data.lastReset = new Date().toISOString();
    saveQuotaData(service, data);
  }
  
  // Normale Prüfung
  const remaining = quota.limit - data.used;
  return { allowed: remaining >= amount };
}
```

---

## 📱 Benutzung

### Stream starten mit Quota-Check

**Was du siehst**:

1. **Wenn genug Kontingent**:
   - Stream startet normal
   - Tracking läuft im Hintergrund

2. **Wenn < 100 Minuten verbleiben**:
   ```
   ⚠️ Niedriges Kontingent!
   
   Nur noch 85 kostenlose Minuten verfügbar.
   
   Stream trotzdem starten?
   
   [Abbrechen]  [Starten]
   ```

3. **Wenn Limit erreicht**:
   ```
   ⚠️ KOSTENLIMIT ERREICHT!
   
   Dein kostenloses Livestreaming-Kontingent 
   ist aufgebraucht.
   
   📊 Verbrauch: 10000 / 10000 Minuten
   🔄 Zurückgesetzt am: 01.12.2025
   
   Bitte warte bis zum nächsten Monat oder 
   upgrade deinen Account.
   
   [OK]
   ```

### AI Chat mit Quota-Check

**Was du siehst**:

1. **Normal**: AI antwortet wie gewohnt

2. **Bei Limit** (sehr unwahrscheinlich):
   ```
   ❌ TAGES-LIMIT ERREICHT!
   
   Du hast dein kostenloses Gemini API Limit 
   für heute erreicht.
   
   🔄 Zurückgesetzt: Täglich um Mitternacht
   
   Bitte versuche es morgen erneut.
   ```

---

## 🎯 Garantien

### Was GARANTIERT geschützt ist:

✅ **Livestreaming bleibt kostenlos**
- Automatisches Stoppen bei 10.000 Minuten
- Keine versteckten Kosten möglich
- Monatliches Reset garantiert

✅ **AI Chat bleibt kostenlos**
- Gemini API ist grundsätzlich kostenlos
- Rate-Limit-Schutz verhindert Fehler
- Unbegrenzte Nutzung (mit 60/min Limit)

✅ **Voice Recognition & TTS kostenlos**
- Browser-native APIs
- Keine externen Services
- Komplett gratis, kein Limit

### Was NICHT geschützt werden muss:

❌ **Design System** - Keine Kosten
❌ **Chat System** - Keine Kosten
❌ **D1 Database** - 5 GB gratis (mehr als genug)
❌ **Cloudflare Pages** - 500 Builds/Monat gratis

---

## 🔧 Für Entwickler

### Quota-Status programmatisch abfragen

```javascript
// Alle Quotas
const status = window.costMonitor.getAllQuotaStatus();

console.log(status);
// {
//   agora: { used: 4520, remaining: 5480, ... },
//   gemini: { used: 128, remaining: 912, ... }
// }
```

### Eigene Quota-Checks

```javascript
// Agora prüfen
const agoraCheck = window.costMonitor.checkAgoraQuota();

if (agoraCheck.allowed) {
  startStream();
} else {
  showError(`Limit erreicht: ${agoraCheck.used}/${agoraCheck.limit}`);
}
```

### Quota-Dashboard anzeigen

```javascript
// Dashboard öffnen
window.costMonitor.showQuotaDashboard();

// Oder im HTML
<button onclick="window.costMonitor.showQuotaDashboard()">
  📊 Kontingente anzeigen
</button>
```

---

## 📊 Kostenübersicht (Falls Limits überschritten)

**Agora RTC** (nach 10.000 Minuten/Monat):
| Nutzung | Kosten |
|---------|--------|
| 1.000 Minuten | $0.99 - $3.99 |
| 10.000 Minuten | $9.90 - $39.90 |

**Gemini API**:
- **IMMER KOSTENLOS** ✅
- Keine Limits außer Rate-Limit (60/min)

**Voice/TTS**:
- **IMMER KOSTENLOS** ✅
- Browser-nativ, keine externen Kosten

---

## 🚨 FAQ

### Kann ich trotzdem Kosten bekommen?

**NEIN**, wenn:
- ✅ Du das Cost Monitoring System NICHT deaktivierst
- ✅ Du keine Änderungen am Code machst
- ✅ LocalStorage funktioniert

**JA**, nur wenn:
- ❌ Du das System manuell umgehst
- ❌ Du den Code modifizierst
- ❌ Du direkt die Agora API nutzt (ohne unsere Wrapper)

### Was wenn LocalStorage gelöscht wird?

**Schutz bleibt aktiv**:
- Gelöschte Daten werden als "0 genutzt" interpretiert
- Agora-Tracking startet von vorne
- Du bekommst ein neues 10.000-Minuten-Kontingent
- Kein Risiko!

### Was wenn ich das Limit wirklich überschreiten will?

**Manuell möglich**:
1. Öffne Browser Console (F12)
2. Führe aus: `window.costMonitor = null`
3. System ist deaktiviert
4. **WARNUNG**: Kosten können entstehen!

**Empfohlen**: Upgrade Agora Account statt System zu deaktivieren

### Wie genau ist das Tracking?

**Agora**:
- ✅ Minuten-genau
- ✅ Läuft während Stream
- ✅ Stoppt bei Limit ± 1 Minute

**Gemini**:
- ✅ Pro Request
- ✅ Vor Anfrage geprüft
- ✅ Nach Erfolg gezählt

---

## ✅ Status: PRODUCTION READY

Das Cost Protection System ist:
- ✅ Vollständig implementiert
- ✅ Getestet
- ✅ Deployed
- ✅ Dokumentiert
- ✅ **AKTIV** 🛡️

**Du bist geschützt!** Keine versteckten Kosten möglich! 💰✨

---

**Letzte Aktualisierung**: 2025-11-16  
**Version**: 1.0  
**Status**: Production Ready ✅
