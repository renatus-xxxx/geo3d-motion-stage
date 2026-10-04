[English](RUNTIME.md) | [日本語](RUNTIME.ja.md)

# Runtime setup

The ROMs require V9968, geo3d and ASCII16-X support. **Official, unmodified openMSX and a standard V9958 are not sufficient.** The emulator used for validation derives from [alexmoncks/openMSX](https://github.com/alexmoncks/openMSX); choose a Windows build that implements FIL at R21 bit 6 for `dist/MOTION8.ROM`.

The emulator, BIOS files and raw BVH downloads are not distributed here. Two GPL-2.0 machine configurations are provided in `tools/machines`; their upstream source is the [openMSX machine definitions](https://github.com/openMSX/openMSX/tree/RELEASE_21_0/share/machines).

## Files to prepare

The `-EmulatorRoot` directory must contain `openmsx.exe` and its `share` directory, including the `geo3d` extension. Do not point it at this repository's `emulator` destination.

For **FS-A1GT / R800**, place these files in the directory passed as `-SystemROMs`:

- `fs-a1gt_firmware.rom`
- `fs-a1gt_kanjifont.rom`

For **MSX2+ / C-BIOS / Z80**, place these files in the directory passed as `-CBIOS`:

- `cbios_main_msx2+_jp.rom`
- `cbios_logo_msx2+.rom`
- `cbios_sub.rom`
- `cbios_music.rom`

The tested version is [C-BIOS 0.29](https://cbios.sourceforge.net/). Its files may already be available in your emulator installation. Machine definitions contain SHA-1 identifiers; a different BIOS release may require updating the identifiers to match its verified files.

## Configure and launch

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup-runtime.ps1 -EmulatorRoot C:\Tools\openMSX-V9968 -SystemROMs C:\MSX\systemroms -CBIOS C:\MSX\cbios
```

Paths are examples. Supply only the BIOS option for the machine you need. The helper copies the emulator only if the local `emulator` directory does not exist, then installs the machine configurations and supplied BIOS files under ignored runtime directories. Existing emulator files are preserved.

- `run-turbor.bat`: selects MOTIONGT and R800.
- `run-msx2plus-cbios.bat`: selects MOTIONCB and Z80.
- `run.bat`: defaults to MOTIONGT.

The scripts use `build/MOTION8.ROM` if it exists, otherwise `dist/MOTION8.ROM`. A fresh clone can run the prebuilt binary without z88dk or BVH downloads. No disks or saved states are attached.

## Native-FIL variant

`dist/MOT8N.ROM` targets the current FPGA register layout, FIL at R20 bit 5, and hardware page flipping. It is **not** for the legacy emulator above. A limited visual test on blueMSX+ 2090cd2 confirmed boot, playback and the white ending, with field artifacts observed. Controls, audio, CPU mode readback and reset were not checked there. Real-hardware operation and performance remain untested.


The tested legacy openMSX executable reports version `21.0-unknown` and SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`. Its precise source revision and build date were not recorded; the fork link identifies the implementation family, not a proven binary-to-commit match.


The blueMSX+ visual check above used the earlier native ROM with SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`. The current review-fixed native ROM has been rebuilt, but has not been visually rechecked on blueMSX+; its real-hardware operation remains untested.

## Capacity selection

Pass 2m to a launcher to select MOTION2.ROM and standard ASCII16; no argument selects MOTION8.ROM and ASCII16-X. Example: run-msx2plus-cbios.bat 2m. The native 2 MiB ROM is MOT2N.ROM. Mapper auto-detection failed with the tested openMSX build for 2 MiB; select ASCII16 explicitly. On SX-2, select compatible ESE-MegaRAM in the loader and retain V9968 + geo3d. Physical operation remains untested.


## External V9968

The external configuration also requires HRA_V9968 and geo3d88 emulator extensions. Use run-turbor.bat 8m external or run-msx2plus-cbios.bat 2m external to insert them and display the V9968 video source. The same ROM detects the external device. See [the device specification](VDP.md).
