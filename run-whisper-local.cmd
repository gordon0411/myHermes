@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0bin\run-whisper-local.ps1"
endlocal
