@echo off
REM ============================================================================
REM Weltenbibliothek HTTP Media Server - Status-Prüfung
REM ============================================================================
REM Prüft den Status des HTTP Media Server Service

title Weltenbibliothek HTTP Service Status

echo ============================================================================
echo Weltenbibliothek HTTP Media Server - Status-Prüfung
echo ============================================================================
echo.

set SERVICE_NAME=WeltenbibliothekMediaServer

REM Service-Status prüfen
echo [1] Service-Status:
echo.
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Service ist NICHT installiert
    echo.
    echo Um den Service zu installieren, führen Sie aus:
    echo    install_http_service.bat (als Administrator)
    echo.
    goto :port_check
) else (
    sc query %SERVICE_NAME% | findstr "STATE" 
    sc query %SERVICE_NAME% | findstr "RUNNING" >nul
    if %errorlevel% equ 0 (
        echo ✅ Service läuft
    ) else (
        echo ⚠️  Service ist installiert, aber nicht gestartet
        echo.
        echo Um den Service zu starten:
        echo    net start %SERVICE_NAME%
    )
)
echo.

REM Port-Belegung prüfen
:port_check
echo [2] Port 8080 Status:
echo.
netstat -ano | findstr :8080 >nul
if %errorlevel% equ 0 (
    echo ✅ Port 8080 ist belegt (Server läuft wahrscheinlich)
    echo.
    echo Prozess-Details:
    netstat -ano | findstr :8080
    echo.
) else (
    echo ❌ Port 8080 ist FREI (kein Server läuft)
    echo.
)

REM HTTP-Test
echo [3] HTTP-Erreichbarkeit:
echo.
echo Teste http://localhost:8080 ...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:8080 2>nul
if %errorlevel% neq 0 (
    echo ❌ Server ist nicht erreichbar
    echo    (curl fehlt oder Server läuft nicht)
) else (
    echo ✅ Server antwortet
)
echo.

REM Log-Dateien prüfen
echo [4] Log-Dateien:
echo.
set SCRIPT_DIR=%~dp0
set LOG_FILE=%SCRIPT_DIR%http_service.log
set ERROR_LOG=%SCRIPT_DIR%http_service_error.log

if exist "%LOG_FILE%" (
    echo ✅ Normal-Log gefunden: %LOG_FILE%
    echo    Größe: 
    for %%A in ("%LOG_FILE%") do echo       %%~zA Bytes
    echo.
    echo    Letzte 5 Zeilen:
    powershell -Command "Get-Content '%LOG_FILE%' -Tail 5"
    echo.
) else (
    echo ⚠️  Kein Normal-Log gefunden
)

if exist "%ERROR_LOG%" (
    echo ✅ Error-Log gefunden: %ERROR_LOG%
    echo    Größe:
    for %%A in ("%ERROR_LOG%") do echo       %%~zA Bytes
    echo.
    for %%A in ("%ERROR_LOG%") do set ERROR_LOG_SIZE=%%~zA
    if !ERROR_LOG_SIZE! GTR 0 (
        echo ⚠️  ERROR-LOG ENTHÄLT EINTRÄGE!
        echo.
        echo    Letzte 10 Zeilen:
        powershell -Command "Get-Content '%ERROR_LOG%' -Tail 10"
        echo.
    )
) else (
    echo ⚠️  Kein Error-Log gefunden
)
echo.

REM FTP-Verzeichnis prüfen
echo [5] FTP-Verzeichnis-Zugriff:
echo.
set FTP_DIR=C:\xlight\Weltenbibliothek
if exist "%FTP_DIR%" (
    echo ✅ FTP-Verzeichnis gefunden: %FTP_DIR%
    echo.
    echo    Unterverzeichnisse:
    dir /b /ad "%FTP_DIR%" 2>nul
    echo.
) else (
    echo ❌ FTP-Verzeichnis NICHT gefunden: %FTP_DIR%
    echo.
    echo    Bitte prüfen Sie den Pfad in media_http_server.py
    echo.
)

REM Python-Installation prüfen
echo [6] Python-Installation:
echo.
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python ist NICHT installiert!
) else (
    for /f "tokens=*" %%i in ('python --version') do echo ✅ %%i
    echo.
    for /f "tokens=*" %%i in ('where python') do echo    Pfad: %%i
)
echo.

REM Zusammenfassung
echo ============================================================================
echo Zusammenfassung:
echo ============================================================================
echo.

set ALL_OK=1

sc query %SERVICE_NAME% | findstr "RUNNING" >nul
if %errorlevel% neq 0 set ALL_OK=0

netstat -ano | findstr :8080 >nul
if %errorlevel% neq 0 set ALL_OK=0

if %ALL_OK% equ 1 (
    echo ✅ ALLES OK - Server läuft und ist erreichbar!
    echo.
    echo Test im Browser:
    echo    http://localhost:8080
    echo    http://Weltenbibliothek.ddns.net:8080
) else (
    echo ⚠️  PROBLEME ERKANNT
    echo.
    echo Mögliche Lösungen:
    echo    1. Service starten: net start %SERVICE_NAME%
    echo    2. Service installieren: install_http_service.bat (als Admin)
    echo    3. Manuell starten: start_media_server.bat
    echo    4. Logs prüfen: %SCRIPT_DIR%http_service_error.log
)

echo.
pause
