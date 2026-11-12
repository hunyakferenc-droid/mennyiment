@echo off
cd /d "%~dp0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo HIBA: Windows PowerShell 5.1 szukseges.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INDITAS.ps1" -Mode Source
if errorlevel 1 pause
