[English](VDP.md) | [日本語](VDP.ja.md)

# Internal and external V9968

The same ROM selects an external V9968 first, otherwise the BIOS/main V9968. It requires geo3d on the selected device. A standard V9938/V9958 is not a rendering fallback. Both capacities and FIL implementations use this selection.

## Detection

`src/device.c` adapts the algorithm in [HRA!'s official check_vdp_type.asm](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/v9968/detect/check_vdp_type.asm). See the scoped [MIT notice](../licenses/MIT-VDP-DETECT.txt).

1. Disable CPU interrupts. BIOS page 0 remains mapped. Check that BIOS bytes 0006h/0007h agree and that the BIOS generation is MSX2 or later. Disable the main VDP's vertical/horizontal interrupt enables.
2. Write 00h to port4 (main 9Ch / external 8Ch), matching the working Night Raven demo, to unlock R20/R21. Then read S1; clear R21.FID (bit 0) and read S1 again. Extract `(S1 >> 1) & 31`; V9968 is 3. Restore the status selector to S0. R21 is intentionally changed; the selected device is subsequently initialized. The BIOS R21 shadow is not changed by this application.
3. Unless the BIOS already points to the 88h block (version-up adapter), read external control port 89h twice, as in the official sample. Two reads with bit 7 set mean absent. Otherwise run the same S1/FID test.
4. Prefer external ID 3. Derive all VDP/geo3d ports from the selected control port.
5. Read/write/read geo3d COLOR register 44h using 55h and AAh, then restore its old value. This validates register readback without executing geometry. If external V9968 has no geo3d, stop there; do not silently switch to a different display.

The official sample warns that machines without data-bus pull-ups may misidentify an absent external VDP. The extra geo3d readback rejects a constant undriven response, but does not guarantee every possible electrical configuration. Detection is designed for cold boot/reset, not hot swapping or preserving another program's graphics state. A CPU polling timeout cannot recover a physical bus cycle held indefinitely by faulty WAIT hardware.

| Access | Main at 98h | External at 88h |
|---|---|---|
| VRAM data | 98h | 88h |
| VDP control / status | 99h | 89h |
| Palette | 9Ah | 8Ah |
| Indirect command registers | 9Bh | 8Bh |
| port4 / extended-register lock | 9Ch | 8Ch |
| geo3d index / status | 9Dh | 8Dh |
| geo3d data | 9Fh | 8Fh |

Ports base+5/base+7 are confirmed in the official [geo3d bus adapter](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/geo3d/geo3d_bus.v). Offset 6 (8Eh) is reserved for MegaRAM and is not used.

## Initialization and synchronization

The cartridge loader uses BIOS slot services, but no longer calls CHGMOD. The selected VDP is initialized directly to SCREEN 7 FIL, including palette and both VRAM pages. The FIL bit remains determined by the ROM variant; detection does not infer which FIL implementation a V9968 uses.

Only the selected VDP enables VBlank interrupts. The IM2 handler selects its S0, acknowledges VBlank and advances the demo, music and input clocks. The internal VDP remains interrupt-disabled when external is selected. This avoids counting two clocks. External VBlank must reach the MSX interrupt line, as in the cartridge FPGA wiring. No BIOS calls, ROM-bank changes or drawing occur inside the handler. The app keeps the existing 60 Hz setup.

VDP command, geo3d busy and next-VBlank waits have bounded polling. The whiteout hold also uses the bounded wait rather than HALT. On failure, interrupts and PSG output stop and the application stays in a diagnostic loop. Border indices: 14 = unsupported VDP or command/device timeout, 10 = missing geo3d, 9 = missing VBlank. Their visible colors depend on the active palette. `video_error` distinguishes codes 1 (VDP busy), 2 (VDP type), 3 (geo3d busy), 4 (VBlank), 5 (geo3d detection). Reset retries detection. BIOS border visibility depends on the connected display; no BASIC exit is performed.

## Emulator launch and checks

Normal launchers still use main V9968 + geo3d. To insert the external expansion and show its video source:

```bat
run-turbor.bat 8m external
run-msx2plus-cbios.bat 2m external
```

These commands need the emulator's `HRA_V9968` and `geo3d88` extensions. The launcher option configures the emulator, not the ROM's choice. On hardware, detection needs no flag. The emulator must display the `V9968` video source rather than `MSX` when using the external device.

```powershell
tools\verify-demo.ps1 -Profile 2m -Machine CB -Vdp external -Seconds 150 -Fit -ManualCamera -Headless
tools\verify-controls.ps1 -Profile 2m -Machine CB -Vdp external
tools\verify-devices.ps1 -Case missing-vdp
tools\verify-devices.ps1 -Case missing-geo
tools\verify-devices.ps1 -Case external-missing-geo
tools\verify-devices.ps1 -Case lost-irq
tools\verify-devices.ps1 -Case lost-irq-hold
```

`verify-devices.ps1` deliberately disables an emulated VDP interrupt for the last two fault tests. It never edits game progression to force a pass. See [verification](../VERIFICATION.md) for current ROM hashes and results. FPGA, SX-2 and current native FIL runtime remain unverified.

Reference: [Night Raven initialization](https://github.com/kanon-ai/V9968_Geo3D_SampleDemo/blob/main/demos/night-raven/src/player.asm).
