@echo off
setlocal
cd /d "%~dp0..\..\.."
if not defined Z88DK set "Z88DK=C:\z88dk"
set "ZCCCFG=%Z88DK%\lib\config"
set "PATH=%Z88DK%\bin;%PATH%"
if not defined LIBV9968_ROOT set "LIBV9968_ROOT=%CD%\..\libv9968"
if not defined AUDIO_TEST_OUT set "AUDIO_TEST_OUT=E:\work\libv9968-audio-tests"
if not exist "%AUDIO_TEST_OUT%" mkdir "%AUDIO_TEST_OUT%"
if not defined OPENMSX_EXE (echo Set OPENMSX_EXE and its data directories.& exit /b 2)
if not defined OPENMSX_MACHINE (echo Set OPENMSX_MACHINE.& exit /b 2)
if not defined NATIVE_MUSIC_TEST (echo Set NATIVE_MUSIC_TEST to motion-music-test.exe.& exit /b 2)
zcc +msx -subtype=rom -compiler=sdcc -SO2 -DLIBV9968_MSX -I"%LIBV9968_ROOT%" -create-app platform/pc/tests/music-trace.c src\music.c -o "%AUDIO_TEST_OUT%\MOTION"
if errorlevel 1 exit /b 1
set "PSG_TRACE_FILE=%AUDIO_TEST_OUT%\motion-msx.txt"
"%OPENMSX_EXE%" -machine "%OPENMSX_MACHINE%" -carta "%AUDIO_TEST_OUT%\MOTION.rom" -romtype Normal -script platform/pc/tests/capture.tcl
if errorlevel 1 exit /b 1
"%NATIVE_MUSIC_TEST%" --trace > "%AUDIO_TEST_OUT%\motion-pc.txt"
if errorlevel 1 exit /b 1
fc /L "%PSG_TRACE_FILE%" "%AUDIO_TEST_OUT%\motion-pc.txt"
exit /b %errorlevel%
