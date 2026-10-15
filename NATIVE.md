[English](NATIVE.md) | [日本語](NATIVE.ja.md)

# Native application and shared graphics

MSX source now uses the shared v9968.c/geo3d.c transport in lib/libv9968. Cartridge mapping, interrupts, input, music and choreography remain application-owned. The vendored C files are identical to the sibling libv9968 checkout; CMake checks their hashes to prevent divergent APIs.

The experimental native application loads generated motion-banks.bin data directly. No MSX BIOS, ROM loader or external MSX emulator is used. Build the ordinary ROM/data first, then:

```bat
set OPENAL_SOFT_ROOT=E:\dependencies\openal-soft-1.25.2-bin
cmake -S . -B E:/work/motion-native -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake -DMOTION_PROFILE=8m
cmake --build E:/work/motion-native --config Release
ctest --test-dir E:/work/motion-native -C Release --output-on-failure
cd /d E:\work\motion-native\Release
motion-stage.exe
```

Use MOTION_PROFILE=2m for the 10 Hz compact data; each build directory contains its own copied bank file. MOTION_NATIVE_FIL=ON uses current R20 FIL; OFF models the application's bundled R21 FIL presentation. Pixel comparisons normalize display pages and logical VRAM. Do not confuse physical SCREEN7 VRAM ordering with logical image bytes.

T/R/C, Space, M, D, E, Esc and arrow controls retain their meaning. Shift+arrows changes zoom; Z/X also changes zoom without modifier keys. Letter commands are case insensitive. Native BGM now uses the optional libv9968 PSG module and OpenAL Soft. The same music code drives the unchanged MSX PSG playback.

`--ticks 4400` checks a complete unforced demo loop. `--test-input` exercises manual controls and restart. `--at 800 --dump capture.vram` freezes an explicit rendering fixture; it is not a game-progress or performance test. A dump includes palette and logical image metadata. Ubuntu/macOS build branches are supplied by libv9968 but not verified on this Windows host. Physical hardware and beam-phase parity remain unverified.


## PSG audio

Install OpenAL Soft as described in [libv9968 audio setup](../libv9968/doc/AUDIO.md). Keep the official package's shared-library notices when redistributing native binaries. Use `--ticks 960 --wav bgm.wav` to record 16 seconds without opening an audio device. Normal windowed playback opens OpenAL Soft and follows the 60 Hz application clock. Recording is independent of drawing. Physical hardware sound and Ubuntu/macOS playback remain unverified.
