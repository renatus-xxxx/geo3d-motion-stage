[English](MEDIA.md) | [日本語](MEDIA.ja.md)

# Record the ROM-native demonstration

Windows PowerShell, FFmpeg and a configured V9968 + geo3d openMSX runtime are required for media generation. They are separate from the Python/WSL-free ROM build and launch.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\encode-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-preview.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package-release.ps1
```

The capture runs both capacities on R800 and Z80, recording from the application's actual demo-clock start. No keys or emulator scripts drive effects or cameras; the ROM does. Recording includes the natural application whiteout, original PSG audio and automatic restart verification.

Encoding creates two side-by-side comparisons, 8 MiB on the left and 2 MiB on the right, plus a full R800 demonstration. Both comparisons use the same 71.4-second span and end on the application's white screen. Post-processing does not add whiteout, audio fading or motion interpolation. A common deinterlace filter reduces FIL combing. Small English labels fit within the 960×400 comparison image. H.264/AAC copies omit source metadata.

`preview.gif` shows the first 30 seconds at 480×360/10 fps without audio. The application remains 512×424/16 colors. Intermediate AVI, logs and private runtime files stay in ignored directories. Distribution contains the ROMs and compressed MP4s, not BIOS, emulators or raw BVH.
