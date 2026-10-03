@echo off
setlocal
cd /d "%~dp0"
if not defined MOTION_MACHINE set "MOTION_MACHINE=MOTIONGT"
if not defined MOTION_ROM (
 set "MOTION_ROM=%CD%\build\MOTION.rom"
 if not exist "%CD%\build\MOTION.rom" set "MOTION_ROM=%CD%\dist\MOTION.rom"
)
if not exist "%MOTION_ROM%" (echo Download the ROM in dist or run build.bat. & exit /b 1)
if not exist emulator\openmsx.exe (echo Set up a V9968 + geo3d openMSX environment first. & exit /b 1)
set "OPENMSX_HOME=%CD%\runtime\%MOTION_MACHINE%"
if not exist "%OPENMSX_HOME%" mkdir "%OPENMSX_HOME%"
set "OPENMSX_USER_DATA=%CD%\runtime\share"
set "OPENMSX_SYSTEM_DATA=%CD%\emulator\share"
"%CD%\emulator\openmsx.exe" -machine %MOTION_MACHINE% -ext geo3d -carta "%MOTION_ROM%" -romtype ASCII16-X -script "%CD%\tools\launch.tcl" %*
exit /b %errorlevel%
