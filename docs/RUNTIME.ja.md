[English](RUNTIME.md) | [日本語](RUNTIME.ja.md)

# 実行環境の準備

ROMにはV9968・geo3d・ASCII16-X対応が必要です。**公式の未改造openMSXや標準V9958だけでは動作しません。** 検証用エミュレータは[alexmoncks/openMSX](https://github.com/alexmoncks/openMSX)の派生版です。`dist/MOTION8.ROM`にはFILをR21 bit6で実装したWindows版を使用します。

エミュレータ、BIOS、未変換BVHは配布しません。`tools/machines`の2つのGPL-2.0機種定義は[openMSXの機種定義](https://github.com/openMSX/openMSX/tree/RELEASE_21_0/share/machines)から派生しています。

## 用意するファイル

`-EmulatorRoot`には`openmsx.exe`と、`geo3d`拡張を含む`share`ディレクトリが必要です。このリポジトリのコピー先`emulator`自身は指定しないでください。

**FS-A1GT / R800**の場合、`-SystemROMs`のディレクトリへ配置します。

- `fs-a1gt_firmware.rom`
- `fs-a1gt_kanjifont.rom`

**MSX2+ / C-BIOS / Z80**の場合、`-CBIOS`のディレクトリへ配置します。

- `cbios_main_msx2+_jp.rom`
- `cbios_logo_msx2+.rom`
- `cbios_sub.rom`
- `cbios_music.rom`

検証版は[C-BIOS 0.29](https://cbios.sourceforge.net/)です。エミュレータに同梱されている場合もあります。機種定義にはSHA-1があるため、別版のBIOSでは確認した実ファイルに合わせて識別子の変更が必要な場合があります。

## 設定と起動

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup-runtime.ps1 -EmulatorRoot C:\Tools\openMSX-V9968 -SystemROMs C:\MSX\systemroms -CBIOS C:\MSX\cbios
```

パスは例です。必要な機種のBIOSオプションだけを指定できます。スクリプトはローカル`emulator`が存在しない場合のみエミュレータをコピーし、機種定義と指定BIOSをGit除外対象の実行環境へ配置します。既存エミュレータのファイルは保持します。

- `run-turbor.bat`：MOTIONGT / R800を選択。
- `run-msx2plus-cbios.bat`：MOTIONCB / Z80を選択。
- `run.bat`：標準ではMOTIONGTを選択。

`build/MOTION8.ROM`があれば使用し、なければ`dist/MOTION8.ROM`を使用します。配布ROMの実行にはz88dkやBVHの取得は不要です。ディスクやセーブ状態を接続しません。

## native FIL版

`dist/MOT8N.ROM`は現行FPGAのFIL設定R20 bit5と表示ページ切り替えに対応します。上記の旧FILエミュレータ向けではありません。blueMSX+ 2090cd2では起動・自動再生・白画面終了を限定的に確認しましたが、動く輪郭のフィールド差も観測しています。操作、音声、CPUモード読み取り、リセットは同環境では未確認です。実機での動作と性能は未検証です。

検証した旧FIL版openMSXの実行ファイルはバージョン`21.0-unknown`、SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`です。正確なソースリビジョンとビルド日は記録がないため、参照リンクから同じバイナリを再現できると保証するものではありません。


上記のblueMSX+表示確認は、修正前のnative ROM（SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`）の結果です。今回のレビュー修正版native ROMは再ビルド済みですが、blueMSX+での表示再確認と実機検証は未実施です。

## 容量の選択

起動batに 2m を指定すると MOTION2.ROM と標準ASCII16を選びます。省略時は MOTION8.ROM とASCII16-Xです。例：un-msx2plus-cbios.bat 2m。nativeの2 MiB版は MOT2N.ROM です。2 MiB版の自動マッパー判別は検証用openMSXで起動せず、ASCII16を明示してください。SX-2では対応ESE-MegaRAMをローダーで選び、V9968 + geo3dも必要です。実機は未検証です。
