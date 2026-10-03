@echo off
setlocal
cd /d "%~dp0"
if not defined Z88DK set "Z88DK=C:\z88dk"
set "PATH=%Z88DK%\bin;%PATH%"
set "ZCCCFG=%Z88DK%\lib\config"
if not exist build mkdir build
powershell -NoProfile -ExecutionPolicy Bypass -File tools\get-bvh.ps1
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\bake.ps1
if errorlevel 1 exit /b 1
"%Z88DK%\bin\zcc.exe" +msx -subtype=bin -zorg=33792 -compiler=sdcc -SO2 -pragma-define:REGISTER_SP=62208 -pragma-define:CRT_ENABLE_EIDI=0 -Isrc -Ibuild src\main.c src\video.c src\scene.c src\trig.c src\platform.c src\music.c -o build\STAGE.bin -m >build\build.log 2>&1
if errorlevel 1 (type build\build.log & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pack.ps1 -Layout
if errorlevel 1 exit /b 1
"%Z88DK%\bin\z88dk-z80asm.exe" -b -m -l -obuild/BOOT.bin src\boot.asm >build\boot-build.log 2>&1
if errorlevel 1 (type build\boot-build.log & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pack.ps1
exit /b %errorlevel%
