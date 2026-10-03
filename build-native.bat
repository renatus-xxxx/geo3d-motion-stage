@echo off
setlocal
cd /d "%~dp0"
if not defined Z88DK set "Z88DK=C:\z88dk"
set "PATH=%Z88DK%\bin;%PATH%"
set "ZCCCFG=%Z88DK%\lib\config"
if not exist build\motion-banks.bin (
 call build.bat
 if errorlevel 1 exit /b 1
)
"%Z88DK%\bin\zcc.exe" +msx -subtype=bin -zorg=33792 -compiler=sdcc -SO2 -DV9968_NATIVE_FIL -pragma-define:REGISTER_SP=62208 -pragma-define:CRT_ENABLE_EIDI=0 -Isrc -Ibuild src\main.c src\video.c src\scene.c src\trig.c src\platform.c src\music.c -o build\STAGE-native.bin -m >build\build-native.log 2>&1
if errorlevel 1 (type build\build-native.log & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pack.ps1 -Layout -Native
if errorlevel 1 exit /b 1
powershell -NoProfile -Command "$s=[IO.File]::ReadAllText('src/boot.asm').Replace('build/rom_layout.inc','build/rom_layout-native.inc');[IO.File]::WriteAllText('build/boot-native.asm',$s)"
if errorlevel 1 exit /b 1
"%Z88DK%\bin\z88dk-z80asm.exe" -b -m -l -obuild/BOOT-native.bin build/boot-native.asm >build\boot-native.log 2>&1
if errorlevel 1 (type build\boot-native.log & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pack.ps1 -Native
exit /b %errorlevel%