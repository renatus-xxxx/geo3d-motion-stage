@echo off
setlocal
cd /d "%~dp0"
set "MOTION_PROFILE=all"
if not "%~1"=="" set "MOTION_PROFILE=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-rom.ps1 -Profile "%MOTION_PROFILE%"
exit /b %errorlevel%
