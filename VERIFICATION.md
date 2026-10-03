[English](VERIFICATION.md) | [日本語](VERIFICATION.ja.md)

# Verification record

Tested on 2026-10-03 with Windows V9968 + geo3d openMSX. The native ROM has a limited blueMSX+ 2090cd2 visual check covering boot, playback and the white ending; controls, audio and reset there remain untested. Real hardware is untested.

## ROM

| File | Target | Bytes |
|---|---|---:|
| build/MOTION.rom | Tested openMSX legacy FIL | 8,388,608 |
| build/MOTION-native.rom | Current FPGA FIL registers | 8,388,608 |

Compatibility SHA-256: `b82324d940b2b0a5cc74cf804625a4f68d5521b5a59b1d5bb8e2900871c52d17`.

Native SHA-256: `c5ce2e25c22bac28a91a0a81a803e4c01c5fd4cfeb5be27aad1769c20d640448`.

Both use ASCII16-X. C payload: 7,276 bytes; BOOT: 111 bytes; BSS: 9FAFh..A06Ch, end excluded. Three dancers have 1,410 poses at 20Hz, about 70.5 seconds. Both ROMs built successfully with Windows `C:\z88dk`. Native boot/playback/white ending were observed on blueMSX+; controls/audio/reset there and real-hardware rendering/speed remain untested.

## Rendering environment

FS-A1GT BIOS / R800 DRAM / 512KB RAM (MOTIONGT), and C-BIOS 0.29 MSX2+ JP / Z80 / 64KB RAM (MOTIONCB). Both use V9968, 256KB VRAM and geo3d, without disks, BASIC commands or saved states.

SCREEN 7 FIL renders 512×424, 16 colors, RGB5 palette. geo3d center: 256,212; focal length: 320; clip bounds: 512×424. Current FPGA FIL is R20 bit5; native sets R20=31h/R21=3Ah. Tested openMSX legacy FIL is R21 bit6; compatibility sets R20=11h/R21=7Ah. R9=84h selects NTSC, 212 lines per field and EO; ordinary IL is not used.

- [Current FPGA implementation](https://github.com/hra1129/V9968_Cartridge/blob/main/fpga/V9968_Cartridge_TangNano20K/src/v9968/vdp_cpu_interface.v)
- [Reference emulator VDP.hh](https://github.com/alexmoncks/openMSX/blob/msx2pp/src/video/VDP.hh)

One image is 108,544 bytes. Y=0 and Y=512 images fit in 256KB. Legacy FIL cannot display upper 128KB as a page, so HMMM copies the completed Y=512 image to Y=0 in two 256-pixel halves, avoiding its NX=512 high-speed limitation. Native alternates regions and flips R2=3Fh/7Fh.

## openMSX functional checks

Both CPUs were tested with actual keyboard-matrix input, without changing application state:

- Cold boot, correct CPU mode, rendering error zero, banks beyond 255.
- Full playback, final pose 1409, terminal white_level=31.
- Esc after ending: white_level=0, motion/camera reset.
- T trails, R reflection, C modes, camera rotation/zoom, Space pause/resume.
- M music-clock stop/resume.
- Full solo/all-effects playback, reset/reboot and both launcher bats.

Every 15 display frames, all character/reflection vertices were independently projected to check the near plane and 512×424 viewport. ROM-window data was compared. Local logs/images are `output/test-*`; launch logs are `output/launcher-*`. Remaining mapper auto-detection logs are from an earlier version.

## Performance

Averages over about 88 seconds of emulated time include effect/mode changes, white fade/hold and Esc restart. These are not hardware measurements.

| Display | R800 | Z80 |
|---|---:|---:|
| Three dancers, effects off | ~15.0 FPS | ~4.0 FPS |
| Solo, effects off | ~15.0 FPS | ~4.6 FPS |
| Three dancers, trails + reflections | ~6.0 FPS | ~1.3 FPS |

Clock-based poses keep choreography speed despite slow rendering. Legacy FIL copies and VBlank waiting reduce the R800 ceiling.

## Ending and shared video

During the final 0.5 seconds, all 16 RGB5 colors approach white and BGM fades/stops. The final pose and white screen hold until Esc. E is the normal ending-sequence shortcut.

An earlier 320×240 capture cropped captions. Release video was recaptured at 640×480 with 14px captions as `dist/motion-stage-demo.mp4`. Sizes/hashes are in `dist/manifest.json` and `dist/SHA256SUMS.txt`. It demonstrates T/R on/off, all C modes, rotation and original PSG music. E invokes the application's ending; there is no edited video whiteout. Audio/video decoded to EOF without errors; the white-ending image was checked.

## Limitations

- Native real-hardware FIL, page switching and performance untested.
- FIL can show moving-edge field differences/flicker.
- Legacy copies may display partly if they exceed VBlank.
- Z80 smoothness is limited, especially with both effects.
- No alpha transparency, Z-buffer, temporal interpolation or smooth skinning.
- geo3d omits floor faces intersecting the near plane.
- Original BGM is not synchronized to source song/choreography beats.

The tested legacy openMSX executable reports version `21.0-unknown` and SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`. Its precise source revision and build date were not recorded; the fork link identifies the implementation family, not a proven binary-to-commit match.


The blueMSX+ visual check above used the earlier native ROM with SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`. The current review-fixed native ROM has been rebuilt, but has not been visually rechecked on blueMSX+; its real-hardware operation remains untested.

After the review fixes, R800/Z80 regression checks exercised simultaneous E/Space, ending from pause and Esc restart. Test logs/images are local-only and excluded from publication.

The performance table records earlier functional-validation measurements. It is an indication of performance, not a repeat of the identical benchmark on the final review-hardened ROM.
