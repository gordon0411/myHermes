@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\install-hermes-service.ps1" -RunAtStartup
endlocal
