[English](README.md) | [日本語](README.ja.md)

# ビルド済みROMと動画

| ファイル | 容量／モーション | マッパー | FIL |
|---|---|---|---|
| [MOTION8.ROM](MOTION8.ROM) | 8 MiB／20 Hz | ASCII16-X | R21 bit6 |
| [MOT8N.ROM](MOT8N.ROM) | 8 MiB／20 Hz | ASCII16-X | native R20 bit5 |
| [MOTION2.ROM](MOTION2.ROM) | 2 MiB／10 Hz | ASCII16 | R21 bit6 |
| [MOT2N.ROM](MOT2N.ROM) | 2 MiB／10 Hz | ASCII16 | native R20 bit5 |

Nはnative FILです。全ROMがR800／Z80に対応し、自動デモを繰り返します。両容量とも16 bit法線の値を維持します。必要環境はV9968 + geo3d、VRAM 256 KiB、主RAM 64 KiB、60 Hzです。標準V9958だけでは不足します。2 MiBはASCII16を明示してください。検証環境の自動マッパー判別には対応していません。SX-2／FPGA実機は未検証です。

[全編デモ](motion-stage-demo.mp4) · [R800左右比較](comparison-r800.mp4) · [Z80左右比較](comparison-z80.mp4)

[チェックサム](SHA256SUMS.txt)と[マニフェスト](manifest.json)で配布ファイルを識別します。[検証](../VERIFICATION.ja.md)、[操作](../README.ja.md#操作)、[実行環境](../docs/RUNTIME.ja.md)を参照してください。native版のビルドと実行検証は区別して記載しています。BIOS・エミュレータは含みません。

BVHモーション：**[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)**。公式BVHを変換して収録し、公式MP3は使用せず、PSG音楽は独自制作です。[NOTICE](NOTICE.txt)と[第三者資料](../THIRD_PARTY.ja.md)を参照してください。プロジェクト全体のMIT／GPLは表明せず、GPLは2つの機種XMLだけに適用します。
