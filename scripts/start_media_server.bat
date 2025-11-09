@echo off
REM =====================================================
REM Weltenbibliothek Media HTTP Server - Windows Starter
REM =====================================================

title Weltenbibliothek Media Server

echo.
echo ================================================
echo   WELTENBIBLIOTHEK MEDIA HTTP SERVER
echo ================================================
echo.

REM Wechsle zum Script-Verzeichnis
cd /d "%~dp0"

REM Prüfe ob Python installiert ist
python --version >nul 2>&1
if errorlevel 1 (
    echo FEHLER: Python ist nicht installiert!
    echo.
    echo Bitte installiere Python von: https://www.python.org/
    echo.
    pause
    exit /b 1
)

echo Python gefunden!
echo.
echo Starte Media HTTP Server...
echo.

REM Starte den Server
python media_http_server.py

pause
