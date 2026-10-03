[English](DESIGN.md) | [日本語](DESIGN.ja.md)

# Implementation and data format

## BVH conversion

The reference BVH contains 23 joints and 2,820 frames at 0.025 seconds per frame. `tools/BvhBake.cs` reads the hierarchy, OFFSET, position CHANNELs and rotation CHANNELs in the file's declared order to compute world coordinates. End Sites also provide endpoints, including the head tip. Rotation order is not hardcoded to XYZ.

Every two input frames produce one pose: 1,410 poses at 20Hz, lasting 70.5 seconds. Instead of full skinning, the head, torso, pelvis, arms and legs use 12 triangular bipyramids. Each part has five vertices and six triangles. Width varies by body part; outward normals are generated per pose.

Coordinates are signed 16-bit integers at twice the BVH units, centered on the complete sequence's bounding-box center. X points right, Y up and Z into the scene. Matrices and normals use Q2.14. Bounds are X=-623..623, Y=-166..166, Z=-600..600; floor Y=-174. Recheck quantization and projection limits for larger values or other input.

## ASCII16-X ROM

The 8MB ROM has 512 banks of 16KB.

| Banks | Contents |
|---|---|
| 0 | AB header and ROM INIT |
| 1 | C program copied into RAM |
| 2..354 | Motion data: 353 banks |
| 355..511 | Unused, filled with FFh |

A pose occupies 3,456 bytes.

| Region | Format | Bytes |
|---|---|---:|
| Vertices | 180 × X,Y,Z as little-endian int16 | 1,080 |
| Faces | 216 × four vertex indices, int16 NX/NY/NZ and BASE color | 2,376 |

Each bank holds four poses plus FFh padding; the last holds two. The data region occupies 5,783,552 bytes. A triangle repeats vertex three as vertex four for geo3d.

```c
bank = 2 + frame / 4;
address = 0x4000 + (frame & 3) * 3456;
```

ASCII16-X encodes upper bank bits in bits 8..11 of the mapper write address. Only the first window is used:

```c
*(volatile unsigned char *)(0x6000 | (bank & 0x0f00)) = (unsigned char)bank;
```

The eight-byte `ASCII16X` identifier is at file offset 16; automatic identification was checked on a compatible emulator. Ordinary ASCII16 cannot select banks above 255 correctly. Code, variables, stack and interrupts are in RAM, outside the switched window. Pose data transfers directly from the selected ROM bank to geo3d without a full RAM copy. Interrupts never switch the cartridge bank.

## RAM and startup

| Address | Purpose |
|---|---|
| 0000..3FFF | Main BIOS retained |
| 4000..7FFF | Cartridge 16KB data window |
| 8400..A06B | C program, constants and BSS in the current build |
| E000..E100 | 257-byte IM2 vector table |
| E1E1..E1E3 | JP to RAM interrupt handler |
| Around E200 | Startup RAM-copy helper |
| Below F300 | Downward-growing stack |
| F380 onward | BIOS work area retained |

At least 64KB RAM is expected; the application does not switch RAM banks. Startup maps page 2 to the page-3 RAM slot and copies the program into RAM. It selects R800 DRAM only when BIOS generation byte 002Dh is 3 and CHGCPU exists. BIOS calls preserve IX, the C frame pointer.

After BIOS CHGMOD initializes the VDP during bootstrap, `video_init()` directly programs registers for the distributed **SCREEN 7 FIL, 512×424, 16-color** display. A dedicated IM2 interrupt maintains the VBlank clock. The main renderer owns VDP register configuration; interrupts acknowledge VBlank, update the clock, play PSG music and detect input edges. AF/HL/BC/DE/IX/IY and the alternate register set are saved around the C handler. Input reads the PPI keyboard matrix directly.

## Rendering and camera

V9968 uses 512×424, 16 colors and an RGB5 palette. Compatibility ROM: R20=11h/R21=7Ah. Native ROM: R20=31h/R21=3Ah. SCREEN 7 FIL uses VRAM Y=0 and Y=512 as display/render regions. The tested internal-VDP emulator uses VDP ports 98h..9Ch and geo3d 9Dh/9Fh.

Camera matrix, translation, vertices, faces and lighting are sent to geo3d. The renderer waits for geo3d/VDP completion and never issues VDP commands while geo3d RUN is busy. VBlank retains input edges; the main loop uses DI/EI while reading/clearing them.

Bounds include the current pose, displayed past poses and, when enabled, reflected Y across the floor. Their center is the camera target. All eight corners are transformed to camera coordinates to calculate the minimum distance satisfying screen bounds and near plane. Zoom is 100..200% of this distance, so all vertices remain framed.

The floor fills below the horizon and adds a 5×5-vertex, 4×4-cell 3D checker grid. Cell side length is 175; overall coverage is retained. Reflections use `2*FLOOR_Y-Y`, reversed winding and reversed normal Y. Trails show skeletal endpoints from 100ms and 200ms earlier as two dark line colors, followed by the current solid mesh. A three-person trail pose has 72 vertices and 36 edges. This replaces costly filled past poses. There is no alpha blending, physical reflection or temporal image blur.

A 20Hz clock selects poses; slow rendering skips to the current pose instead of slowing Z80 choreography. Interpolation and loop-seam smoothing are unimplemented; the sequence ends and can be restarted.

## PSG BGM

`src/music.c` provides an original 32-step × 15-VBlank sequencer: about eight seconds at 120 BPM. Channel A is a bright arpeggio, B bass, C noise/short-tone percussion. Periods use the standard MSX clock; register 7's upper two bits are preserved. Code/note tables remain in RAM and can be read during ROM bank changes. M mutes, Space pauses, Esc restarts.

[Verification](../VERIFICATION.md) describes FIL presentation copies versus native page switching, white fade and ending controls.