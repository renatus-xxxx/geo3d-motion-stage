[English](README.md) | [日本語](README.ja.md)

# Prebuilt binaries

| File | Target | Validation |
|---|---|---|
| [MOTION.rom](MOTION.rom) | Legacy V9968 openMSX: FIL = R21 bit 6 | R800 and Z80 emulator playback, controls, ending and reset verified |
| [MOTION-native.rom](MOTION-native.rom) | Current FPGA: FIL = R20 bit 5 | Build verified; blueMSX+ 2090cd2 boot/playback/white ending observed with field artifacts; controls/audio and hardware untested |
| [motion-stage-demo.mp4](motion-stage-demo.mp4) | 42-second demonstration | R800 capture with PSG audio and the application's own ending |

Both ROMs are **8,388,608 bytes, ASCII16-X**, and need **V9968 with 256KB VRAM + geo3d + at least 64KB main RAM**. These ROMs are not for a standard V9958-only MSX.

The launch scripts select the legacy ROM. See [runtime setup](../docs/RUNTIME.md) before launching. BIOS and emulator binaries are not included. [SHA256SUMS.txt](SHA256SUMS.txt) contains file checksums; [manifest.json](manifest.json) records sizes and validation scope.

## Data attribution

BVH motion data: **[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)**.

The ROMs include converted skeletal motion from `aachan.bvh`, `kashiyuka.bvh` and `nocchi.bvh`. The official project provided BVH and MP3; this demo uses only the BVH motion and does not include the official MP3, original song, WAV, BIOS or emulator. This is an independent, unofficial demo. See [NOTICE.txt](NOTICE.txt) and [third-party notes](../THIRD_PARTY.md). The motion data is used for this fan-created derivative demo, following the official project description. Its use basis is documented separately from the machine XML notices.


The blueMSX+ visual check above used the earlier native ROM with SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`. The current review-fixed native ROM has been rebuilt, but has not been visually rechecked on blueMSX+; its real-hardware operation remains untested.
