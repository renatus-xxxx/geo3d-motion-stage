[English](README.md) | [日本語](README.ja.md)

# ビルド済みバイナリ

| ファイル | 対象 | 検証 |
|---|---|---|
| [MOTION.rom](MOTION.rom) | 旧FILのV9968版openMSX：R21 bit6 | R800/Z80で再生、操作、終了、リセットを確認 |
| [MOTION-native.rom](MOTION-native.rom) | 現行FPGA設定：R20 bit5 | ビルド、blueMSX+ 2090cd2で起動・再生・白画面終了を確認。フィールド差を観測。操作・音声・実機は未検証 |
| [motion-stage-demo.mp4](motion-stage-demo.mp4) | 42秒のデモ | PSG音声とアプリ自身の終了演出を含むR800録画 |

両ROMは**8,388,608バイト・ASCII16-X**で、**256KB VRAMのV9968 + geo3d + 最低64KBメインRAM**が必要です。標準V9958だけのMSX向けではありません。

起動スクリプトは旧FIL版を選択します。[実行環境](../docs/RUNTIME.ja.md)を準備してください。BIOS・エミュレータは配布しません。[SHA256SUMS.txt](SHA256SUMS.txt)にチェックサム、[manifest.json](manifest.json)に容量と検証範囲を記載します。

## データの出典

BVHモーション：**[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)**。

ROMには`aachan.bvh`、`kashiyuka.bvh`、`nocchi.bvh`から変換した関節モーションを収録します。公式プロジェクトはBVHとMP3を提供していますが、このデモはBVHのみ使用し、公式MP3、元楽曲、WAV、BIOS、エミュレータは含みません。独立した非公式デモです。[NOTICE.txt](NOTICE.txt)と[第三者資料](../THIRD_PARTY.ja.md)も参照してください。公式プロジェクトが説明するファンの二次創作として利用し、モーションデータの利用方針は機種設定XMLの表記とは区別します。

上記のblueMSX+表示確認は、修正前のnative ROM（SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`）の結果です。今回のレビュー修正版native ROMは再ビルド済みですが、blueMSX+での表示再確認と実機検証は未実施です。
