[English](MEDIA.md) | [日本語](MEDIA.ja.md)

# ROM内デモの録画

メディア生成にはWindows PowerShell、FFmpeg、設定済みV9968 + geo3d openMSXが必要です。Python・WSL不要の通常ビルド・起動とは別の処理です。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\encode-demo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-preview.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package-release.ps1
```

両容量をR800とZ80で録画し、アプリのデモ時計が実際に開始するところから収録します。外部キー入力やエミュレータスクリプトで演出・カメラを操作せず、ROM自身が進行します。アプリの自然なホワイトアウト、独自PSG音楽、自動再開始の検証を含みます。

エンコードでは左8 MiB・右2 MiBの比較動画をCPU別に2本と、R800の全編デモを作ります。比較は同じ71.4秒の範囲で、アプリの白画面で終えます。動画側の白化・音楽フェード・モーション補間は加えません。共通のデインターレース処理でFILの縞を軽減します。小さい英語ラベルを960×400内に収め、H.264／AACとし、元のメタデータを引き継ぎません。

`preview.gif`は最初の30秒・480×360・10 fps・音なしです。アプリ自体は512×424・16色です。中間AVI・ログ・個人の実行環境はGit対象外に残し、ROMと圧縮MP4だけを配布します。BIOS、エミュレータ、raw BVHは配布しません。
