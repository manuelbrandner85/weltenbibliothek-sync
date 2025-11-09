@echo off
REM ============================================================================
REM Weltenbibliothek HTTP Media Server - Service Deinstallation
REM ============================================================================
REM Entfernt den Windows-Dienst für den HTTP Media Server

title Weltenbibliothek HTTP Service Deinstallation

echo ============================================================================
echo Weltenbibliothek HTTP Media Server - Service Deinstallation
echo ============================================================================
echo.

REM Administrator-Rechte prüfen
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ FEHLER: Administrator-Rechte erforderlich!
    echo    Bitte starten Sie als Administrator
    pause
    exit /b 1
)

set SERVICE_NAME=WeltenbibliothekMediaServer
set NSSM_PATH=%~dp0nssm.exe

echo Prüfe Service-Status...
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Service "%SERVICE_NAME%" ist nicht installiert.
    echo.
    pause
    exit /b 0
)

echo ✅ Service gefunden
echo.

if not exist "%NSSM_PATH%" (
    echo ⚠️  NSSM nicht gefunden, verwende sc.exe...
    echo.
    echo Stoppe Service...
    net stop %SERVICE_NAME% 2>nul
    timeout /t 2 /nobreak >nul
    
    echo Entferne Service...
    sc delete %SERVICE_NAME%
    
    if %errorlevel% equ 0 (
        echo ✅ Service erfolgreich entfernt!
    ) else (
        echo ❌ Fehler beim Entfernen des Service
    )
) else (
    echo Stoppe Service...
    "%NSSM_PATH%" stop %SERVICE_NAME% >nul 2>&1
    timeout /t 2 /nobreak >nul
    
    echo Entferne Service...
    "%NSSM_PATH%" remove %SERVICE_NAME% confirm
    
    if %errorlevel% equ 0 (
        echo ✅ Service erfolgreich entfernt!
    ) else (
        echo ❌ Fehler beim Entfernen des Service
    )
)

echo.
echo Der HTTP Media Server startet nicht mehr automatisch.
echo Um ihn manuell zu starten, verwenden Sie: start_media_server.bat
echo.
pause
