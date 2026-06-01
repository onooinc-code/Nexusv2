@echo off
TITLE NexusV2 Dev Server
echo ========================================
echo Starting NexusV2 Build and Server Script
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-fixed.ps1"
pause
