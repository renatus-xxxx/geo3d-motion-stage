[English](VERIFICATION.md) | [日本語](VERIFICATION.ja.md)

# Verification results

## Internal/external VDP release (2026-10-05)

Windows V9968 + geo3d openMSX 21.0-unknown; emulator SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`. GT uses FS-A1GT BIOS / R800 DRAM / 512 KiB RAM. CB uses C-BIOS 0.29 MSX2+ JP / Z80 / 64 KiB RAM. No BASIC command, disk or saved state is used.

All four ROMs built with Windows z88dk. Capacity, motion data, normals, FIL settings and minimum RAM remain unchanged. Code is copied to 8400h; BSS must remain below E000h. See [device detection and synchronization](docs/VDP.md) for ports and error codes.

| ROM | Bytes | SHA-256 |
|---|---:|---|
| MOTION8.ROM | 8388608 | `594c27ffc53e069f1718dd903c61ad067d794ede7a5cc96876caa543650d358a` |
| MOT8N.ROM | 8388608 | `163e69a50816ee5beded32ca28207aec8895ac4740d84123d59174c8f140450e` |
| MOTION2.ROM | 2097152 | `8a1b590b4f3044dd1c5ccec3ac5a088dec8bb76c9f00e6c056a9acf14ae8dcab` |
| MOT2N.ROM | 2097152 | `25ff090ee622df5c2ca3fafc9791f8b85a14ccd24bbfc40e4fb1e6b67d0f8d70` |

## Current-ROM regression

Each demo run lasts 150 emulated seconds. Actual keyboard events exercise actor selection, trails/reflection and camera extremes; vertex projection and floor near clipping are checked, followed by a natural whiteout and automatic restart. Controls runs separately check movement-related camera input, pause, mute/phase, ending, Esc/D and reset cold boot. Main V9968 and external V9968 coexist in external rows, proving external priority. The VDP and geo3d selected ports are checked at startup.

| Capacity / CPU / selected VDP | Demo + projection | Controls + reset |
|---|---|---|
| 8m / GT / internal | PASS | PASS |
| 8m / GT / external | PASS | PASS |
| 8m / CB / internal | PASS | PASS |
| 8m / CB / external | PASS | PASS |
| 2m / GT / internal | PASS | PASS |
| 2m / GT / external | PASS | PASS |
| 2m / CB / internal | PASS | PASS |
| 2m / CB / external | PASS | PASS |

A further 2 MiB run on each CPU uses a standard internal V9958 plus external HRA_V9968/geo3d88: cold boot and a natural full demo loop pass. Standard internal V9958 alone stops with error 2. Main V9968 without geo3d and standard internal V9958 + external V9968 without geo3d stop with error 5. Disabling the emulated VBlank interrupt during normal playback and during the white hold separately produces error 4 and stops the clock; no indefinite HALT occurs. All five device fault tests pass.

The fixed-camera plain benchmarks remain 15.00 FPS on R800 for both capacities, 6.00 FPS on Z80/8 MiB and 5.00 FPS on Z80/2 MiB, over 30 emulated seconds with BGM enabled. These are emulator results, not physical hardware measurements.

## Limits and prior validation

The current native FIL ROMs are build-verified only. FPGA, physical SX-2, electrical bus pull-ups, and version-up-adapter BIOS port redirection remain unverified. The internal/external functional tests run headless but still execute guest geo3d/VDP rendering and VBlank waits. External 2 MiB/Z80 and 8 MiB/R800 rendering were also checked visually from the selected V9968 video source, including floor reflection. All four CPU/capacity external launchers passed at throttle=true, speed=100 with the correct CPU and control port 89h. Physical monitor switching is outside the program.

Previous-release six-real-hour and eight-emulated-hour passes apply to `de19b53f…` (8 MiB) and `dbc49b47…` (2 MiB), not these newly built ROMs. Continuous six-hour testing has not been repeated for this VDP update. Existing comparison videos and preview show the previous release with the same motion/visual settings.

Detection follows [HRA!'s official sample](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/v9968/detect/check_vdp_type.asm); see the scoped third-party notice in [THIRD_PARTY.md](THIRD_PARTY.md).
