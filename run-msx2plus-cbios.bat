@echo off
setlocal
set "MOTION_MACHINE=MOTIONCB"
call "%~dp0run.bat" %*
exit /b %errorlevel%
