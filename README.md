[English](README.md) | [日本語](README.ja.md)

# geo3d-motion-stage


A cartridge-based 3D dance demo for **MSX with V9968 + geo3d**. Three low-poly dancers perform BVH motion in **SCREEN 7 FIL, 512×424, 16 colors**, with optional motion trails, floor reflections and an original PSG soundtrack.

![Animated preview from the R800 emulator](preview.gif)

## Download

No compiler is needed to try the prebuilt ROMs.

| Download | Choose this for |
|---|---|
| [MOTION.rom](dist/MOTION.rom) | The legacy V9968 openMSX implementation with FIL at **R21 bit 6**; tested on R800 and Z80 |
| [MOTION-native.rom](dist/MOTION-native.rom) | Current FPGA register layout with FIL at **R20 bit 5**; build verified, hardware operation untested |
| [Demo video](dist/motion-stage-demo.mp4) | A 42-second R800 recording with sound and English feature captions |

Both ROMs are **8 MiB ASCII16-X** cartridges. They need **V9968 with 256KB VRAM, geo3d and at least 64KB main RAM**. Standard MSX2+/V9958 hardware or an unmodified openMSX build is insufficient. R800 gives smoother playback; Z80 support has lower frame rates.

See [binary notes and checksums](dist/README.md) for details. BIOS and emulator binaries are not included.

## Technical guide

[English PDF](docs/geo3d-motion-stage-technical-guide.en.pdf) | [日本語 PDF](docs/geo3d-motion-stage-technical-guide.ja.pdf)

An illustrated 22-slide guide explains BVH joint hierarchies, baking, low-poly mesh generation, ASCII16-X ROM banks and geo3d rendering. It includes code excerpts, camera projection, motion trails, floor reflections and the two SCREEN 7 FIL backends.

## Run on Windows

Use a Windows [V9968 + geo3d openMSX build](https://github.com/alexmoncks/openMSX) that supports ASCII16-X and the legacy FIL layout described above. Prepare the BIOS files for the machine you want to use.

1. Clone or download this repository.
2. Run the setup helper with the directory containing `openmsx.exe` and `share`:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup-runtime.ps1 -EmulatorRoot C:\Tools\openMSX-V9968 -SystemROMs C:\MSX\systemroms -CBIOS C:\MSX\cbios
   ```

   The paths above are examples. `-SystemROMs` is needed for turboR; `-CBIOS` is needed for the C-BIOS machine. See [runtime setup](docs/RUNTIME.md) for file names.
3. Start `run-turbor.bat` for **FS-A1GT / R800**, or `run-msx2plus-cbios.bat` for **MSX2+ / C-BIOS / Z80**. `run.bat` defaults to R800.

The launchers use a local build when available, otherwise `dist/MOTION.rom`. They boot directly from the cartridge without disks, BASIC commands or saved states.

## Controls

| Key | Action |
|---|---|
| Left / Right | Orbit the camera horizontally, up to ±45° |
| Up / Down | Adjust camera pitch above the floor |
| Shift + Up / Down | Zoom while keeping the dancers in view |
| **T** — Trails | Toggle two fading past poses |
| **R** — Reflection | Toggle floor reflections |
| **C** — Character | All three → aachan → kashiyuka → nocchi → all three |
| **M** — Music | Mute / unmute the original PSG loop |
| Space | Pause / resume |
| **E** — End | Start the application’s ending early |
| Esc | Restart motion and music; reset the camera |

Playback starts with all three dancers and both visual effects off. After approximately **70.5 seconds**, the application fades to white, fades out the music and holds the final screen. Press Esc to start again.

## Motion data credit

**BVH motion data: [Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/).**

This demo uses the BVH motion data provided by **Perfume global site project #001**, credited to the official primary source linked above. The project provided both BVH motion and MP3 music; this demo uses only the BVH motion, converted into ROM data. The character meshes, MSX viewer and PSG music are original; the official MP3 is not used or distributed. This is an independent, unofficial demo.

The [official project article](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/) describes providing motion data for fan-created derivatives. This demo follows that fan-creation purpose. The article is not presented here as a blanket license grant for the BVH data; see [third-party notes](THIRD_PARTY.md).

## Build from source

Requires Windows, **z88dk**, Windows PowerShell and .NET Framework. Python and WSL are not required.

```bat
set Z88DK=C:\z88dk
build.bat
build-native.bat
```

`build.bat` produces `build/MOTION.rom`; `build-native.bat` produces the separate native-FIL ROM. Place the project-provided `aachan.bvh`, `kashiyuka.bvh` and `nocchi.bvh` in `assets/` before building. The build verifies their SHA-256 hashes and runs offline; it does not fetch data from a redistribution repository. The linked official article describes the primary project, but is not itself a direct BVH download endpoint.

FFmpeg is required only to regenerate the video and GIF, not to build or run the demo. See [media instructions](docs/MEDIA.md).

## Performance and technical notes

| Display | R800 | Z80 |
|---|---:|---:|
| Three dancers, effects off | ~15 FPS | ~4 FPS |
| One dancer, effects off | ~15 FPS | ~4.6 FPS |
| Three dancers, trails + reflections | ~6 FPS | ~1.3 FPS |

These are emulator measurements, not real-hardware results. Pose data is 20Hz; slow rendering skips poses without slowing the choreography. FIL is interlaced and can show field differences on moving edges. Native-FIL hardware has not been tested.

The runtime uses fixed-size buffers, integer/fixed-point geometry and banked ROM data. Each dancer has 60 vertices and 72 triangles. geo3d handles transforms, lighting, face sorting and filling.

- [Architecture and data format](docs/DESIGN.md)
- [Verification and known limitations](VERIFICATION.md)

## Third-party notices

[tools/machines/MOTIONGT.xml](tools/machines/MOTIONGT.xml) and [tools/machines/MOTIONCB.xml](tools/machines/MOTIONCB.xml) derive from openMSX machine definitions and retain [GPL-2.0](licenses/GPL-2.0.txt). This notice applies only to these two configuration files, not the application code or BVH motion data. BVH attribution and use are described in [third-party notes](THIRD_PARTY.md).

### Build variants

| Script | Output | FIL implementation |
|---|---|---|
| `build.bat` (default) | `build/MOTION.rom` | Compatibility with the tested geo3d openMSX: R21 bit 6, with a VRAM copy to present each frame |
| `build-native.bat` | `build/MOTION-native.rom` | Current V9968 FPGA register layout: R20 bit 5, with display-page switching |

Both use the same motion, controls and music, and produce 8MB ASCII16-X ROMs. `native` does not mean R800-only. The bundled launchers select `MOTION.rom`.

`build-native.bat` reuses existing baked motion data. After changing BVH inputs or the converter, run `build.bat` first, then `build-native.bat`. `build.bat` always builds the compatibility backend; use `build-native.bat` for the native backend.

The current [blueMSX+ V9968 + geo3d branch](https://github.com/Hesoten/blueMSX-plus/tree/experimental/v9968-geo3d) uses R20 bit 5 for FIL. On 2026-10-03, the supplied **v3.1.1 experimental V9968 + geo3d build `2090cd2`** was tested with `MOTION-native.rom`, FS-A1GT BIOS, V9968/256KB VRAM, ASCII16-X and 100% emulation speed. Cold boot, animated dancers, floor rendering, automatic playback and the final white screen were observed. Moving edges sometimes showed interlace combing/field differences; visually smooth frames were also observed. This is a limited visual compatibility check, not a claim of artifact-free rendering. Keyboard controls, effects toggles, audio, CPU mode readback and reset were not verified in this test because the Windows input automation runtime could not initialize. FPGA hardware remains untested. Standard builds without geo3d are not supported.


The blueMSX+ visual check above used the earlier native ROM with SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`. The current review-fixed native ROM has been rebuilt, but has not been visually rechecked on blueMSX+; its real-hardware operation remains untested.

The performance table records earlier functional-validation measurements. It is an indication of performance, not a repeat of the identical benchmark on the final review-hardened ROM.
