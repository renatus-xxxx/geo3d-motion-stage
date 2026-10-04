[English](README.md) | [日本語](README.ja.md)

# geo3d-motion-stage

A cartridge-native 3D dance demo for **MSX with V9968 + geo3d**. Three low-polygon figures perform BVH motion in **SCREEN 7 FIL, 512×424, 16 colors**, with trails, floor reflection and original PSG music.

![R800 emulator preview](preview.gif)

The ROM starts a demonstration automatically: effects, individual characters and camera movement follow a shared timeline. The application fades to white and fades its music, then starts again without input. You can take control at any point.

At boot, the ROM detects external V9968 first, otherwise uses the main V9968. geo3d is required on the selected device. See [detection, initialization and synchronization](docs/VDP.md). To emulate the external expansion, use `run-turbor.bat 8m external` or `run-msx2plus-cbios.bat 2m external`.

## Download

| ROM | Motion / mapper | FIL implementation |
|---|---|---|
| [MOTION8.ROM](dist/MOTION8.ROM) | 8 MiB, 20 Hz, ASCII16-X | Bundled V9968 openMSX, R21 bit 6 |
| [MOT8N.ROM](dist/MOT8N.ROM) | 8 MiB, 20 Hz, ASCII16-X | Native, R20 bit 5 |
| [MOTION2.ROM](dist/MOTION2.ROM) | 2 MiB, 10 Hz, ASCII16 | Bundled V9968 openMSX, R21 bit 6 |
| [MOT2N.ROM](dist/MOT2N.ROM) | 2 MiB, 10 Hz, ASCII16 | Native, R20 bit 5 |

All ROM names use 8.3 format. **N means native FIL, not a CPU type.** Each ROM supports both R800 and Z80. The 8 MiB version preserves every original 20 Hz pose. The 2 MiB version retains every second pose and exact 16-bit coordinates/normals; it does not shorten playback.

Required: **V9968 + geo3d, 256 KiB VRAM and at least 64 KiB main RAM**. A standard V9958 alone is insufficient. R800 is recommended; Z80 is substantially slower with effects. The application explicitly selects 60 Hz. Native-FIL and physical FPGA validation are documented separately in [verification](VERIFICATION.md).

[Full demo video](dist/motion-stage-demo.mp4) · [R800 comparison](dist/comparison-r800.mp4) · [Z80 comparison](dist/comparison-z80.mp4) · [Checksums and distribution](dist/README.md)

## Windows launch

Prepare a Windows [V9968 + geo3d openMSX](https://github.com/alexmoncks/openMSX) build with the R21 bit 6 FIL implementation and the BIOS files for your machine. BIOS and emulator binaries are not distributed.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup-runtime.ps1 -EmulatorRoot C:\Tools\openMSX-V9968 -SystemROMs C:\MSX\systemroms -CBIOS C:\MSX\cbios
```

Paths are examples. See [runtime setup](docs/RUNTIME.md) for required BIOS files.

```bat
run-turbor.bat 8m
run-turbor.bat 2m
run-msx2plus-cbios.bat 8m
run-msx2plus-cbios.bat 2m
```

Without a capacity argument, the launchers select 8 MiB. They use a local build when present, otherwise the ROM in `dist`. No BASIC command, disk or saved state is needed. These launchers select the openMSX FIL ROMs; native ROMs require an emulator or FPGA implementing R20 bit 5.

## Controls

| Key | Action |
|---|---|
| **D — Demo** | Restart the automatic demonstration |
| Left / Right | Camera yaw, up to ±45° |
| Up / Down | Camera pitch |
| Shift + Up / Down | Zoom within the automatic fit limit |
| **T — Trails** | Toggle the two past poses |
| **R — Reflection** | Toggle floor reflection |
| **C — Character** | All → aachan → kashiyuka → nocchi → all |
| **M — Music** | Mute / unmute without leaving demo mode |
| Space | Pause / resume |
| **E — End** | Start the ending early |
| Esc | Restart the current mode with default camera and effects |

Camera, T/R/C, Space and E switch to manual mode while preserving the current scene. Manual mode holds the final white screen until Esc or D. Automatic mode repeats after its approximately 70.5-second motion and a one-second white hold; drawing the next first frame adds a small CPU-dependent delay. Mute preference survives automatic restarts.

## Build

Windows z88dk, Windows PowerShell and .NET Framework are required. Normal build and launch need no Python or WSL.

```bat
set Z88DK=C:\z88dk
build.bat
build-native.bat
```

Each command builds both capacities. Use `build.bat 2m` or `build-native.bat 8m` to build one. Outputs are the four names above under `build`. Capacity and FIL settings are independent; all builds share the C sources. The 2 MiB ROM uses standard ASCII16 bank writes rather than ASCII16-X address extensions.

Place the official `aachan.bvh`, `kashiyuka.bvh` and `nocchi.bvh` files in `assets` first. Their SHA-256 hashes are checked offline. The original bake is cached; after changing BVH or `BvhBake.cs`, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-rom.ps1 -Profile all -Rebake
```

Then rebuild native ROMs. There is no automatic download from a secondary repository. Media regeneration additionally requires FFmpeg: [media instructions](docs/MEDIA.md).

## SX-2 and small ROM devices

The 2 MiB ROM targets **standard ASCII16** and its data banks stay below 128. This is intended for the ASCII-16K ESE-MegaRAM mode used by SX-2-compatible OCM firmware. Select ASCII16 and the appropriate ESE-MegaRAM device in your loader. Keep V9968 + geo3d enabled; standard SX-2 VDP support alone does not provide these extensions. Exact SX-2 loader/firmware and physical operation remain untested.

Upstream [OCM-PLD history](https://github.com/gnogni/ocm-pld-dev/blob/master/history.txt) identifies SX-2 among supported machines and describes ESE-MegaRAM ASCII-16K support. The 8 MiB ROM still requires [ASCII16-X](https://www.grauw.nl/projects/ascii-x/ascii16-x/).

## Motion source

**BVH motion: [Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/).**

The ROM contains motion converted from BVH provided by this official primary project. The project provided BVH and MP3; this demo uses only BVH. Its human mesh, MSX viewer and PSG music were created for this independent, unofficial fan demo. The official MP3 is not used or distributed.

The use basis follows the official description of fan-created works using the motion data; the article is not treated as a blanket open-source license. See [third-party notes](THIRD_PARTY.md).

## Technical documentation

- [Current ROM layout, demo clock and rendering](docs/DESIGN.md)
- [Verification and measured performance](VERIFICATION.md)
- [Original technical guide, English PDF](docs/geo3d-motion-stage-technical-guide.en.pdf) / [Japanese PDF](docs/geo3d-motion-stage-technical-guide.ja.pdf)

The original PDF guide describes the initial release's data layout. The current layout adds baked bounds and a separate 2 MiB profile; use DESIGN for current sizes and code.

The two machine definitions, [MOTIONGT.xml](tools/machines/MOTIONGT.xml) and [MOTIONCB.xml](tools/machines/MOTIONCB.xml), retain their upstream [GPL-2.0](licenses/GPL-2.0.txt) notices. Those notices apply to these configuration files, not the new application code or BVH data. No project-wide MIT/GPL license is asserted.
