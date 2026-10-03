[English](MEDIA.md) | [日本語](MEDIA.ja.md)

# Recreate the demo video and GIF

Requires a configured runtime, a built ROM, Windows PowerShell and FFmpeg. The regular ROM build and launcher do not need FFmpeg.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\encode-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-preview.ps1
```

If FFmpeg is not on PATH, pass `-FFmpeg C:\Tools\ffmpeg\bin\ffmpeg.exe` to the last two scripts. Paths are examples.

The capture records the R800 application at 640×480 for 42 seconds, using actual key-matrix input. It demonstrates T/R on and off, all four character modes and camera rotation. E triggers the application's own whiteout ending; no video whiteout is added in post-processing.

The MP4 uses H.264 video and AAC audio, with smaller English captions inside the frame. Source container metadata is not copied; encoder/muxer tags may still be written. The original eight-second PSG loop is included; the source song is not.

`preview.gif` is a looping 30-second, 480×360, 10 FPS animation made from the uncaptioned capture, with an optimized 64-color GIF palette. It has no audio and is intended as a compact README preview. The application itself remains 512×424, 16 colors.

The media scripts update `dist/motion-stage-demo.mp4` and `preview.gif`; the intermediate AVI and logs stay under ignored `output` and `build` directories.
