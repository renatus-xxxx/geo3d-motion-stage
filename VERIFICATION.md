[English](VERIFICATION.md) | [日本語](VERIFICATION.ja.md)

# Verification results

Tested with Windows V9968 + geo3d openMSX. Physical FPGA/SX-2 and runtime execution of the current native FIL ROMs are unverified. Earlier blueMSX+ checks of a previous native ROM do not validate this release.

## ROM

| ROM | Bytes | C payload bytes | SHA-256 |
|---|---:|---:|---|
| MOTION8.ROM | 8388608 | 8457 | `de19b53ff95d4d223b58aaaa49e2686da96bb0ee7156048557ad8c15ac6e651f` |
| MOT8N.ROM | 8388608 | 8388 | `d9428d4daa65d08f87d8607ae75898bea1e9f814a985aee461952059c216e726` |
| MOTION2.ROM | 2097152 | 11781 | `dbc49b47ab4ad0a868b48a4efd860308741958521045ee7ca2cbd7191e9c08f2` |
| MOT2N.ROM | 2097152 | 11712 | `16dc99148096ea0719e484950b7c4307d098188dce1ddcc73f09d360f7c9d59a` |

8 MiB uses ASCII16-X, 20 Hz and 1,410 poses; 2 MiB uses standard ASCII16, 10 Hz and 705 poses. Both retain 16-bit coordinates/normals and approximately 70.5 seconds. The 111-byte boot header is separate from the C payload. All four ROMs built with Windows z88dk.

RAM layout: code/constants copied to RAM at 8400h; the build verifies BSS ends below E000h. IM2 table at E000h, IRQ trampoline at E1E1h, startup helper at E200h, stack at F300h. Minimum 64 KiB main RAM and 256 KiB V9968 VRAM required.

## Environment

FS-A1GT BIOS / R800 DRAM / 512 KiB RAM (MOTIONGT); C-BIOS 0.29 MSX2+ JP / Z80 / 64 KiB RAM (MOTIONCB).

Cartridge cold boot without BASIC commands, disks or saved states. SCREEN 7 FIL 512×424, 16 colors, RGB5; geo3d focal length 320, center 256/212, near plane 48. Refresh is explicitly set to 60 Hz. OpenMSX FIL uses R20=11h/R21=7Ah; native uses R20=31h/R21=3Ah. 50 Hz playback is outside this release.

openMSX: `21.0-unknown`, executable SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`.

The exact source revision and build date are not recorded; the fork link is not a proven binary-to-commit match.

## Functionality and quality

- Both capacities and CPUs: cold boot, CPU mode, natural playback/restart, whiteout/music fade and reset/reboot checked.
- Actual keyboard-matrix D/T/R/C/M/Space/E/Esc input checked. Music time continues while muted; enabling restores current tone periods.
- The automatic demo uses ROM-native timed states for effects, dancer selection, camera rotation and zoom; no external input sequence.
- Compared stored coordinates/normals for 253,800 vertices / 304,560 faces (8 MiB) and 126,900 / 152,280 (2 MiB). All 5,640 + 2,820 bounds boxes exactly match a vertex scan.
- Independently projected all character, past-pose and reflection vertices on every presented demo frame to check near depth and the 512×424 viewport. Verified high banks ≥256. Low FPS may skip the final pose, so exact final-bank equality is not required on every run.
- Both capacities/CPUs also passed actual-key manual rotation, zoom and dancer-selection tests: all character vertices stayed framed, and all four floor corners stayed beyond the near plane, including enabled effects.
- 2 MiB auto mapper detection failed in this openMSX build; forcing ASCII16 boots successfully. The physical SX-2 loader is untested.

## Performance (display FPS)

| Profile / CPU | Plain BGM on/off | Effects BGM on/off | Scan plain/effects |
|---|---:|---:|---:|
| 8m / R800 | 15.00 / 15.00 | 8.57 / 8.57 | 12.87 / 6.00 |
| 8m / Z80 | 6.00 / 6.13 | 2.30 / 2.30 | 3.53 / 1.23 |
| 2m / R800 | 15.00 / 15.00 | 8.57 / 8.57 | 12.17 / 5.63 |
| 2m / Z80 | 5.00 / 5.00 | 2.07 / 2.13 | 3.17 / 1.20 |

Measured for 30 emulated seconds (8–38 s), three dancers and a fixed manual camera. Effects means trails + reflection. The scan control build uses the same model, camera and rendering but scans vertices for bounds. These are emulator measurements, not hardware performance.

PSG work per interrupt is approximately 535/291 µs on Z80 (on/off), 103/60 µs on R800. Muting gives little FPS benefit, so music stays enabled by default. A three-word normal-copy experiment did not improve plain FPS and added 27 code bytes, so it was rejected.

## Continuous runs

| ROM / CPU | Time basis | Status |
|---|---|---|
| 8m / R800 | 6 h real time | PASS |
| 8m / Z80 | 6 h real time | PASS |
| 2m / R800 | 6 h real time | PASS |
| 2m / Z80 | 6 h real time | PASS |
| 8m / Z80 | 8 h emulated time | PASS |
| 2m / Z80 | 8 h emulated time | PASS |

- 8m/R800/6h: `PASS seconds=21600 loops=301 whiteouts=301 clock_wraps=19 frame_wraps=4 max_bank=354 wall_seconds=21604`
- 8m/Z80/6h: `PASS seconds=21600 loops=300 whiteouts=300 clock_wraps=19 frame_wraps=1 max_bank=354 wall_seconds=21601`
- 2m/R800/6h: `PASS seconds=21600 loops=301 whiteouts=301 clock_wraps=19 frame_wraps=4 max_bank=119 wall_seconds=21603`
- 2m/Z80/6h: `PASS seconds=21600 loops=299 whiteouts=299 clock_wraps=19 frame_wraps=1 max_bank=119 wall_seconds=21601`
- 8m/Z80/8h: `PASS seconds=28800 loops=400 whiteouts=400 clock_wraps=26 frame_wraps=2 max_bank=354 wall_seconds=2547`
- 2m/Z80/8h: `PASS seconds=28800 loops=399 whiteouts=399 clock_wraps=26 frame_wraps=1 max_bank=119 wall_seconds=2188`

Independent processes use copied final ROMs and recorded SHA-256 hashes. Six hours uses real time; eight hours uses accelerated emulated time. Disabling host window rendering still executes guest geo3d/VDP commands and VBlank waits. Interrupted/pre-fix time is excluded. Both 16-bit clock and displayed-frame counter wraps are counted.

## Review and references

Addressed Claude Code findings on VDP-init interrupts, R800 polling guards, error preservation, duplicate topology, bake metadata, verifier timing/nonzero checks, high-bank coverage and floor near clipping.

- [SX-2 / OCM ESE-MegaRAM history](https://github.com/gnogni/ocm-pld-dev/blob/master/history.txt)
- [ASCII16-X specification](https://www.grauw.nl/projects/ascii-x/ascii16-x/)
- [V9968 command engine](https://github.com/hra1129/V9968_Cartridge/blob/main/fpga/V9968_Cartridge_TangNano20K/src/v9968/vdp_command.v)
- [BVH primary source](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)
