[English](DESIGN.md) | [日本語](DESIGN.ja.md)

# Implementation and data format

## BVH bake

The official BVH contains 23 joints, 2,820 poses at 40 Hz. `BvhBake.cs` evaluates parent transforms, OFFSET, translations and rotations in channel order, including End Sites. It creates 12 triangular bipyramid body parts per person: 60 vertices and 72 triangles. All three figures have 180 vertices and 216 faces.

The base bake preserves 1,410 poses at 20 Hz and 70.5 seconds. `CompactMotion.cs` packages all poses for 8 MiB, or every second pose (705 at 10 Hz) for 2 MiB. Retained vertex coordinates and 16-bit normals are exact. The smaller version shares constant face topology and reconstructs geo3d face packets in a fixed RAM buffer.

Coordinates are signed int16 at twice the BVH scale, centered around the clip bounds. X right, Y up, Z depth; matrix and normals use Q2.14. Whole-clip bounds are X=-623..623, Y=-166..166, Z=-600..600. Floor Y=-174. Check arithmetic ranges before using other data.

## ROM profiles

| Layout | 8 MiB | 2 MiB |
|---|---:|---:|
| Mapper | ASCII16-X | ASCII16 |
| Stored poses / rate | 1,410 / 20 Hz | 705 / 10 Hz |
| Vertex bytes per pose | 1,080 | 1,080 |
| Face / normal bytes | 2,376 | 1,296 |
| Baked bounds | 48 | 48 |
| Total bytes per pose | 3,504 | 2,424 |
| Poses per 16 KiB bank | 4 | 6 |
| Data banks | 353 | 118 |
| Used bank range | 0..354 | 0..119 |
| Unused whole banks | 157 | 8 |

Bank 0 contains AB header and startup code; bank 1 contains the C payload copied to RAM; banks 2 onward contain poses. Unused bytes are FFh. Data occupies 5,783,552 or 1,933,312 bank bytes. Total occupied bank regions are 5,816,320 and 1,966,080 bytes respectively; padding inside those regions is not active data.

```c
stored = frame / SAMPLE_STRIDE;
bank = 2 + stored / POSES_PER_BANK;
pose = (const unsigned char *)(0x4000 +
                              (stored % POSES_PER_BANK) * FRAME_BYTES);
```

The 2 MiB mapper writes the bank byte at 6000h. The 8 MiB mapper additionally supplies high bank bits in address bits 8..11. Only the first ROM window is switched; code, stack and IRQ remain in RAM. ASCII16-X is identified by `ASCII16X` at ROM offset 16. The smaller ROM does not contain that signature and should be loaded explicitly as ASCII16.

## Precomputed bounds and camera control

The last 48 bytes of every pose hold four world-space AABBs: all characters, then each individual. Each AABB is six int16 values: minimum X/Y/Z followed by maximum X/Y/Z. This exactly replaces scanning vertices for minima and maxima; it does not cache a camera, projection or zoom.

Every rendered frame still:

1. Selects the current and requested past poses, then combines their bounds.
2. Includes reflection using `2*FLOOR_Y-Y` and adds the same safety margin.
3. Computes the center and the current yaw/pitch matrix.
4. Transforms the eight corners into camera space.
5. Solves screen-edge and near-plane constraints for a safe distance, then applies zoom.

Therefore keyboard and automatic camera rotations remain dynamic. Zoom 100..200% increases distance from the fitted minimum, keeping figures framed. Actor selection and effects can change the required distance. No camera smoothing or fixed-distance shortcut is introduced. A data verifier compares every baked AABB with a fresh scan of its original vertices; runtime projection verification separately checks current figures, trails and reflections.

## RAM and startup

BIOS stays at 0000..3FFF, ROM data window at 4000..7FFF, C code/constant tables/BSS start at 8400. The build rejects BSS reaching beyond E000. IM2 vectors occupy E000..E100, jump stub E1E1..E1E3, boot helper around E200, stack grows downward from F300, and BIOS workspace F380 onward is preserved.

Minimum main RAM remains 64 KiB; no RAM mapper is used by the application. Only the 2 MiB profile needs the 2,376-byte decoded-face buffer. Exact code and BSS endpoints are in generated STAGE maps. Startup maps page 2 to the page-3 RAM slot, initializes the VDP through BIOS, then programs SCREEN 7 FIL directly. R800 DRAM is selected only when BIOS generation 002Dh equals 3 and CHGCPU exists; other machines stay on Z80.

## FIL and geo3d

All distributions use SCREEN 7 FIL, 512×424, 16 colors, RGB5 palette and 256 KiB VRAM. The openMSX profile sets R20=11h/R21=7Ah and copies the finished Y=512 page to Y=0. Native FIL sets R20=31h/R21=3Ah and switches display pages. These profiles are independent of CPU and capacity. R9=84h explicitly selects 60 Hz, 212 lines per field and EO.

geo3d receives a camera matrix, translation, vertices, faces and lighting through 9Dh/9Fh. It transforms, sorts and fills the faces. The main code waits for geo3d and VDP completion. Reflection reverses vertex Y, winding and normal Y. Trails are skeletal lines from 100 and 200 ms earlier; they never wrap to the clip ending at startup. The floor uses a 5×5 vertex / 4×4 cell mesh plus a horizon fill. No alpha blending or image interpolation is used.

## Shared demo clock

The VBlank interrupt increments a bounded clip counter, derives music fade, plays PSG and records keyboard edges. It does not draw, call BIOS or change ROM banks. The main loop reads the clip counter atomically and selects logical pose `ticks/3`; sampling stride changes storage, not timing.

`demo_update(t)` derives absolute effect/character states and camera keyframes from time. It does not replay toggle events, so skipped frames cannot leave a wrong toggle state. A short intermediate state may remain invisible on slow hardware. Manual visual controls stop automatic settings while preserving the current scene. D begins a fresh demo; M only changes sound; Esc resets the current mode.

The last 30 ticks fade to white and silence PSG. After presentation, a one-second white hold runs without redrawing. State and face cache are reset under the white screen, the first next frame is presented, then the palette and music clock restart. This preparation adds a CPU-dependent gap between loops, while choreography and music during each clip remain VBlank-driven.

The free-running clock and frame counter are unsigned 16-bit and can wrap. Elapsed time uses unsigned subtraction; clip time saturates at 4,230 and hold time at 60. Neither uses equality against a distant global deadline. At nominal 60 Hz the free-running clock wraps about every 18 minutes. 50 Hz timing is not currently supported: changing it requires coordinated motion, demo, fade and PSG timing.

## Original PSG music

`music.c` uses a 32-step, 15-tick-per-step sequence, about eight seconds at 120 BPM. A is arpeggio, B bass, C noise/percussion. Mute retains the sequencer phase and reduces writes; unmuting restores the current note. Pause stops both motion and music phase. Loop restart resets the sequencer. The official MP3 is not used.

[Verification](../VERIFICATION.md) distinguishes emulator observations from physical hardware validation.
