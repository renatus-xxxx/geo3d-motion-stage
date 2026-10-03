[English](MEDIA.md) | [日本語](MEDIA.ja.md)

# デモ動画とGIFの再生成

設定済み実行環境、ビルド済みROM、Windows PowerShell、FFmpegが必要です。通常のROMビルド・起動にはFFmpegは不要です。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\encode-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-preview.ps1
```

FFmpegがPATHにない場合は、後ろの2つのスクリプトへ`-FFmpeg C:\Tools\ffmpeg\bin\ffmpeg.exe`を指定します。パスは例です。

録画はR800版アプリを640×480・42秒で記録し、実際のキーマトリクス入力を使用します。T/Rのオン・オフ、4種類の人物モード、カメラ回転を示します。Eでアプリ自身の白画面終了を実行し、動画編集でホワイトアウトは追加しません。

MP4はH.264映像とAAC音声で、画面内に収まる小さな英語字幕を付け、入力コンテナのメタデータはコピーしません。エンコーダーや出力形式のタグは付く場合があります。独自制作の8秒PSGループを収録し、元の楽曲は含みません。

`preview.gif`は字幕なし録画から作る30秒・480×360・10 FPSのループアニメーションです。最適化した64色GIFパレットを使用します。音声はなく、READMEのプレビュー向けです。アプリ自体は512×424・16色です。

スクリプトは`dist/motion-stage-demo.mp4`と`preview.gif`を更新します。中間AVIとログはGit除外対象の`output`と`build`に残します。