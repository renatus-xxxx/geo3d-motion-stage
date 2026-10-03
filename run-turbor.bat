@echo off
setlocal
set "MOTION_MACHINE=MOTIONGT"
call "%~dp0run.bat" %*
exit /b %errorlevel%
