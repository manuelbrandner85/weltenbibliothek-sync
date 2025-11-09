@echo off
REM ============================================================================
REM Weltenbibliothek HTTP Media Server - Windows Service Installation
REM ============================================================================
REM Installiert den HTTP Media Server als Windows-Dienst mit NSSM
REM Der Dienst startet automatisch mit Windows und läuft im Hintergrund

title Weltenbibliothek HTTP Service Installation

echo ============================================================================
echo Weltenbibliothek HTTP Media Server - Service Installation
echo ============================================================================
echo.

REM ============================================================================
REM SCHRITT 1: Administrator-Rechte prüfen
REM ============================================================================
echo [1/6] Prüfe Administrator-Rechte...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ FEHLER: Administrator-Rechte erforderlich!
    echo.
    echo Bitte starten Sie diese Datei als Administrator:
    echo    Rechtsklick ^> "Als Administrator ausführen"
    echo.
    pause
    exit /b 1
)
echo ✅ Administrator-Rechte vorhanden
echo.

REM ============================================================================
REM SCHRITT 2: Python-Installation prüfen
REM ============================================================================
echo [2/6] Prüfe Python-Installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ FEHLER: Python ist nicht installiert!
    echo.
    echo Bitte installieren Sie Python von https://www.python.org/
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ %PYTHON_VERSION% gefunden
echo.

REM ============================================================================
REM SCHRITT 3: Python-Pfad ermitteln
REM ============================================================================
echo [3/6] Ermittle Python-Pfad...
for /f "tokens=*" %%i in ('where python') do set PYTHON_PATH=%%i
if not defined PYTHON_PATH (
    echo ❌ FEHLER: Python-Pfad konnte nicht ermittelt werden!
    pause
    exit /b 1
)
echo ✅ Python gefunden: %PYTHON_PATH%
echo.

REM ============================================================================
REM SCHRITT 4: Script-Pfad ermitteln
REM ============================================================================
echo [4/6] Ermittle Script-Pfad...
set SCRIPT_DIR=%~dp0
set SCRIPT_PATH=%SCRIPT_DIR%media_http_server.py

if not exist "%SCRIPT_PATH%" (
    echo ❌ FEHLER: media_http_server.py nicht gefunden!
    echo    Erwartet: %SCRIPT_PATH%
    pause
    exit /b 1
)
echo ✅ Script gefunden: %SCRIPT_PATH%
echo.

REM ============================================================================
REM SCHRITT 5: NSSM prüfen/herunterladen
REM ============================================================================
echo [5/6] Prüfe NSSM (Non-Sucking Service Manager)...
set NSSM_PATH=%SCRIPT_DIR%nssm.exe

if not exist "%NSSM_PATH%" (
    echo.
    echo ⚠️  NSSM nicht gefunden. Bitte herunterladen:
    echo.
    echo    1. Öffnen Sie: https://nssm.cc/download
    echo    2. Laden Sie "nssm 2.24" herunter
    echo    3. Entpacken Sie win64\nssm.exe nach:
    echo       %SCRIPT_DIR%
    echo.
    echo Alternative: PowerShell-Download (erfordert Internet):
    echo    powershell -Command "Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile '%SCRIPT_DIR%nssm.zip'"
    echo    powershell -Command "Expand-Archive -Path '%SCRIPT_DIR%nssm.zip' -DestinationPath '%SCRIPT_DIR%'"
    echo    copy "%SCRIPT_DIR%nssm-2.24\win64\nssm.exe" "%NSSM_PATH%"
    echo.
    pause
    exit /b 1
)
echo ✅ NSSM gefunden: %NSSM_PATH%
echo.

REM ============================================================================
REM SCHRITT 6: Windows Service installieren
REM ============================================================================
echo [6/6] Installiere Windows Service...
echo.

REM Service-Name
set SERVICE_NAME=WeltenbibliothekMediaServer

REM Prüfen ob Service bereits existiert
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Service "%SERVICE_NAME%" existiert bereits!
    echo    Deinstalliere alten Service...
    "%NSSM_PATH%" stop %SERVICE_NAME% >nul 2>&1
    timeout /t 2 /nobreak >nul
    "%NSSM_PATH%" remove %SERVICE_NAME% confirm >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo ✅ Alter Service entfernt
    echo.
)

echo Installiere neuen Service...
"%NSSM_PATH%" install %SERVICE_NAME% "%PYTHON_PATH%" "%SCRIPT_PATH%"

if %errorlevel% neq 0 (
    echo ❌ FEHLER: Service-Installation fehlgeschlagen!
    pause
    exit /b 1
)

echo ✅ Service installiert
echo.

REM Service-Eigenschaften konfigurieren
echo Konfiguriere Service-Eigenschaften...

REM Beschreibung
"%NSSM_PATH%" set %SERVICE_NAME% Description "Weltenbibliothek HTTP Media Server - Stellt Medien-Dateien vom FTP-Server über HTTP bereit (Port 8080)"

REM Start-Typ: Automatisch
"%NSSM_PATH%" set %SERVICE_NAME% Start SERVICE_AUTO_START

REM Arbeitsverzeichnis
"%NSSM_PATH%" set %SERVICE_NAME% AppDirectory "%SCRIPT_DIR%"

REM Log-Dateien
"%NSSM_PATH%" set %SERVICE_NAME% AppStdout "%SCRIPT_DIR%http_service.log"
"%NSSM_PATH%" set %SERVICE_NAME% AppStderr "%SCRIPT_DIR%http_service_error.log"

REM Automatischer Neustart bei Fehler
"%NSSM_PATH%" set %SERVICE_NAME% AppExit Default Restart
"%NSSM_PATH%" set %SERVICE_NAME% AppRestartDelay 5000

REM Service nach FTP-Server starten lassen (verzögert)
REM Hinweis: Wenn Ihr FTP-Service einen anderen Namen hat, ändern Sie diese Zeile
REM "%NSSM_PATH%" set %SERVICE_NAME% DependOnService xlightftpd

echo ✅ Service konfiguriert
echo.

REM ============================================================================
REM Service starten
REM ============================================================================
echo Starte Service...
"%NSSM_PATH%" start %SERVICE_NAME%

if %errorlevel% neq 0 (
    echo ⚠️  Service konnte nicht gestartet werden!
    echo    Bitte prüfen Sie die Logs: %SCRIPT_DIR%http_service_error.log
    pause
    exit /b 1
)

timeout /t 3 /nobreak >nul
sc query %SERVICE_NAME% | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo ✅ Service läuft erfolgreich!
) else (
    echo ⚠️  Service-Status unbekannt. Bitte prüfen Sie manuell.
)

echo.
echo ============================================================================
echo ✅ Installation erfolgreich abgeschlossen!
echo ============================================================================
echo.
echo Service-Name: %SERVICE_NAME%
echo Service-Typ:  Automatischer Start (mit Windows)
echo Port:         8080
echo Status:       Läuft
echo.
echo Log-Dateien:
echo   - Normal:  %SCRIPT_DIR%http_service.log
echo   - Fehler:  %SCRIPT_DIR%http_service_error.log
echo.
echo Wichtige Befehle:
echo   Service stoppen:    net stop %SERVICE_NAME%
echo   Service starten:    net start %SERVICE_NAME%
echo   Service neustarten: net stop %SERVICE_NAME% ^& net start %SERVICE_NAME%
echo   Status prüfen:      sc query %SERVICE_NAME%
echo   Service entfernen:  nssm remove %SERVICE_NAME% confirm
echo.
echo Der Service startet jetzt automatisch mit Windows!
echo.
echo Test: Öffnen Sie im Browser:
echo   http://localhost:8080
echo   http://Weltenbibliothek.ddns.net:8080
echo.
pause
