@echo off
setlocal
cd /d "%~dp0"
if not defined MOTION_MACHINE set "MOTION_MACHINE=MOTIONGT"
if not defined MOTION_PROFILE set "MOTION_PROFILE=8m"
if /i "%~1"=="8m" (set "MOTION_PROFILE=8m" & shift)
if /i "%~1"=="2m" (set "MOTION_PROFILE=2m" & shift)
if /i not "%MOTION_PROFILE%"=="8m" if /i not "%MOTION_PROFILE%"=="2m" (echo Select 8m or 2m. & exit /b 1)
set "MOTION_FILE=MOTION8.ROM"
if /i "%MOTION_PROFILE%"=="2m" set "MOTION_FILE=MOTION2.ROM"
if not defined MOTION_MAPPER set "MOTION_MAPPER=ASCII16-X"
if /i "%MOTION_PROFILE%"=="2m" set "MOTION_MAPPER=ASCII16"
if not defined MOTION_ROM (
 set "MOTION_ROM=%CD%\build\%MOTION_FILE%"
 if not exist "%CD%\build\%MOTION_FILE%" set "MOTION_ROM=%CD%\dist\%MOTION_FILE%"
)
if not exist "%MOTION_ROM%" (echo Download the ROM in dist or run build.bat. & exit /b 1)
if not exist emulator\openmsx.exe (echo Set up a V9968 + geo3d openMSX environment first. & exit /b 1)
set "OPENMSX_HOME=%CD%\runtime\%MOTION_MACHINE%"
if not exist "%OPENMSX_HOME%" mkdir "%OPENMSX_HOME%"
set "OPENMSX_USER_DATA=%CD%\runtime\share"
set "OPENMSX_SYSTEM_DATA=%CD%\emulator\share"
set "MOTION_ARGUMENTS="
:arguments
if "%~1"=="" goto launch
set "MOTION_ARGUMENTS=%MOTION_ARGUMENTS% %1"
shift
goto arguments
:launch
"%CD%\emulator\openmsx.exe" -machine %MOTION_MACHINE% -ext geo3d -carta "%MOTION_ROM%" -romtype %MOTION_MAPPER% -script "%CD%\tools\launch.tcl" %MOTION_ARGUMENTS%
exit /b %errorlevel%
