[English](README.md) | [日本語](README.ja.md)

# Prebuilt ROMs and videos

| File | Capacity / motion | Mapper | FIL |
|---|---|---|---|
| [MOTION8.ROM](MOTION8.ROM) | 8 MiB / 20 Hz | ASCII16-X | R21 bit6 |
| [MOT8N.ROM](MOT8N.ROM) | 8 MiB / 20 Hz | ASCII16-X | Native R20 bit5 |
| [MOTION2.ROM](MOTION2.ROM) | 2 MiB / 10 Hz | ASCII16 | R21 bit6 |
| [MOT2N.ROM](MOT2N.ROM) | 2 MiB / 10 Hz | ASCII16 | Native R20 bit5 |

N means native FIL. All support R800 or Z80 and start a looping automatic demonstration. Both capacities retain exact 16-bit normals. Required: V9968 + geo3d, 256 KiB VRAM, 64 KiB main RAM, 60 Hz. Standard V9958 is insufficient. Select ASCII16 explicitly for 2 MiB; automatic mapper detection is not supported by the tested setup. Physical SX-2/FPGA operation remains untested.

[Full demo](motion-stage-demo.mp4) · [R800 side-by-side](comparison-r800.mp4) · [Z80 side-by-side](comparison-z80.mp4)

[Checksums](SHA256SUMS.txt) and [manifest](manifest.json) identify the exact files. See [verification](../VERIFICATION.md), [controls](../README.md#controls) and [runtime setup](../docs/RUNTIME.md). Native builds and native runtime validation are distinguished there. BIOS and emulator binaries are not included.

BVH motion: **[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)**. The ROMs contain converted official BVH. The official MP3 is not used; PSG music is original. See [NOTICE](NOTICE.txt) and [third-party notes](../THIRD_PARTY.md). No project-wide MIT/GPL license is asserted; GPL applies only to the two machine XML configurations.
