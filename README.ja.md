[English](README.md) | [日本語](README.ja.md)

# geo3d-motion-stage


**V9968 + geo3dを搭載したMSX向けの3Dダンスデモ**です。3人の低ポリゴン人物がBVHモーションを踊ります。**SCREEN 7 FIL・512×424・16色**で、過去姿勢の残像、床への映り込み、オリジナルPSG BGMを表示・再生します。

![R800エミュレータでのアニメーションプレビュー](preview.gif)

## ダウンロード

ビルド済みROMで試す場合、コンパイラは不要です。

| ダウンロード | 対象 |
|---|---|
| [MOTION.rom](dist/MOTION.rom) | FILが**R21 bit6**の旧V9968 openMSX実装。R800・Z80で検証済み |
| [MOTION-native.rom](dist/MOTION-native.rom) | FILが**R20 bit5**の現行FPGA仕様。ビルド確認のみ、実機未検証 |
| [デモ動画](dist/motion-stage-demo.mp4) | 英語字幕・BGM付き、42秒のR800録画 |

両ROMとも**8MiB・ASCII16-X**です。**V9968・256KB VRAM・geo3d・64KB以上のメインRAM**が必要です。標準V9958だけのMSX2+や未改造のopenMSXでは動きません。R800を推奨します。Z80でも動作しますが描画速度は低くなります。

詳しくは[配布バイナリとチェックサム](dist/README.ja.md)を参照してください。BIOS・エミュレータ本体は含みません。

## 技術解説

[日本語 PDF](docs/geo3d-motion-stage-technical-guide.ja.pdf) | [English PDF](docs/geo3d-motion-stage-technical-guide.en.pdf)

BVHの関節階層、bake、低ポリゴン形状の生成、ASCII16-XのROMバンク、geo3d描画を説明する全22枚の図解スライドです。コード引用とともに、カメラの透視投影、過去姿勢の残像、床への映り込み、SCREEN 7 FILの2つの設定経路を解説します。

## Windowsで起動

ASCII16-Xと上記の旧FIL仕様に対応したWindows版[V9968 + geo3d openMSX](https://github.com/alexmoncks/openMSX)、使用する機種のBIOSを用意してください。

1. このリポジトリをCloneまたはダウンロードします。
2. `openmsx.exe`と`share`を含むディレクトリを指定してセットアップします。

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup-runtime.ps1 -EmulatorRoot C:\Tools\openMSX-V9968 -SystemROMs C:\MSX\systemroms -CBIOS C:\MSX\cbios
   ```

   パスは例です。turboR用に`-SystemROMs`、C-BIOS用に`-CBIOS`を指定します。[必要ファイル一覧](docs/RUNTIME.ja.md)も参照してください。
3. **FS-A1GT / R800**は`run-turbor.bat`、**MSX2+ / C-BIOS / Z80**は`run-msx2plus-cbios.bat`で起動します。`run.bat`はR800を選びます。

起動batはローカルのビルドがあればそれを使い、なければ`dist/MOTION.rom`を使います。ディスク、BASICコマンド、セーブ状態は不要です。

## 操作

| キー | 操作 |
|---|---|
| 左右 | カメラを左右に回転、最大±45度 |
| 上下 | 床の上から見下ろす範囲でカメラを上下に回転 |
| Shift＋上下 | 人物が画面に収まる範囲でズーム |
| **T** — Trails | 2段階の過去姿勢を表示／非表示 |
| **R** — Reflection | 床への映り込みを表示／非表示 |
| **C** — Character | 全員→aachan→kashiyuka→nocchi→全員 |
| **M** — Music | BGMのミュート／解除 |
| Space | 一時停止／再開 |
| **E** — End | 終端演出を早く開始 |
| Esc | モーション・音楽を再開始し、カメラを初期化 |

初期状態は全員表示、残像・映り込みOFFです。約**70.5秒**でアプリ自身が白へフェードし、BGMも減衰・停止します。白画面を保持するので、Escで再開始してください。

## モーションデータの出典

**BVHモーションデータ：[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)。**

公式の一次配布元である **Perfume global site project #001** が提供したBVHモーションを変換してROMに収録しています。出典は上記の公式ページです。同プロジェクトではBVHとMP3が提供されていますが、このデモで使用するのはBVHのみです。人体メッシュ、MSXビューアー、PSG BGMは新規制作で、公式MP3は使用・配布しません。独立した非公式デモです。

[公式記事](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)が説明する、モーションデータを用いたファンの二次創作として制作・配布します。この記事をBVHへの包括的なライセンス付与とは扱いません。データと新規コードの区別は[第三者資料](THIRD_PARTY.ja.md)を参照してください。

## ソースからビルド

Windowsの**z88dk**、Windows PowerShell、.NET Frameworkを使います。Python・WSLは不要です。

```bat
set Z88DK=C:\z88dk
build.bat
build-native.bat
```

`build.bat`は`build/MOTION.rom`、`build-native.bat`は別のnative-FIL版を生成します。ビルド前に公式プロジェクトの`aachan.bvh`、`kashiyuka.bvh`、`nocchi.bvh`を`assets/`へ配置してください。SHA-256で照合し、オフラインでビルドします。二次配布リポジトリからの自動取得は行いません。リンク先の公式記事は一次プロジェクトの紹介ページで、BVHへの直接ダウンロードURLではありません。

動画・GIFの再生成だけFFmpegが必要です。通常のビルドと起動には不要です。[メディア生成手順](docs/MEDIA.ja.md)を参照してください。

## 性能と技術情報

| 表示 | R800 | Z80 |
|---|---:|---:|
| 3人・効果OFF | 約15 FPS | 約4 FPS |
| 1人・効果OFF | 約15 FPS | 約4.6 FPS |
| 3人・残像＋反射 | 約6 FPS | 約1.3 FPS |

エミュレータの測定値で、実機の値ではありません。姿勢は20Hzで、描画が遅い場合は姿勢を間引き、踊り自体を遅くしません。FILはインターレースなので、動く輪郭にフィールド差が出る場合があります。native-FIL版の実機動作は未検証です。

固定長バッファ、整数・固定小数点演算、ROMバンク切り替えを使用しています。1人60頂点・72三角形で、geo3dが変換、陰影、面の並び替え、塗りつぶしを担当します。

- [構成・データ形式](docs/DESIGN.ja.md)
- [検証結果と制約](VERIFICATION.ja.md)

## 第三者資料の表記

[tools/machines/MOTIONGT.xml](tools/machines/MOTIONGT.xml)と[tools/machines/MOTIONCB.xml](tools/machines/MOTIONCB.xml)はopenMSXの機種定義から派生しているため、[GPL-2.0](licenses/GPL-2.0.txt)を維持します。この表記は2つの設定ファイルだけに適用し、アプリのコードやBVHモーションには適用しません。BVHの出典と利用方針は[第三者資料](THIRD_PARTY.ja.md)を参照してください。

### ビルド版の使い分け

| スクリプト | 出力 | FILの実装 |
|---|---|---|
| `build.bat`（通常設定） | `build/MOTION.rom` | 検証済みgeo3d版openMSX向け。R21 bit6を使用し、VRAMコピーで画面を表示 |
| `build-native.bat` | `build/MOTION-native.rom` | 現行V9968 FPGAの設定に対応。R20 bit5を使用し、表示ページを切り替え |

両方ともモーション・操作・BGMは共通で、8MB ASCII16-X ROMです。nativeはR800専用という意味ではありません。付属の起動batは`MOTION.rom`を選択します。

`build-native.bat`は既存の変換済みモーションを再利用します。BVHや変換処理を変更した場合は、先に`build.bat`、続けて`build-native.bat`を実行してください。`build.bat`は常に通常版を作ります。native版は`build-native.bat`を使用してください。

現行の[blueMSX+ V9968 + geo3dブランチ](https://github.com/Hesoten/blueMSX-plus/tree/experimental/v9968-geo3d)もFILにR20 bit5を使用します。2026-10-03に、指定の **v3.1.1 experimental V9968 + geo3d版 `2090cd2`** と`MOTION-native.rom`で検証しました。FS-A1GT BIOS・V9968/256KB VRAM・ASCII16-X・速度100%で、コールドブート、人物のアニメーション、床の描画、自動再生、最後の白画面を確認しました。動く輪郭にはインターレースのフィールド差らしい縞が見える場合があり、滑らかなフレームも確認しています。描画が常に完全であるという検証ではありません。Windows入力操作ランタイムが初期化できなかったため、キー操作・効果切り替え・音声・CPUモードの読み取り・リセットは今回未検証です。FPGA実機も未検証です。geo3dを含まない通常版は対象外です。


上記のblueMSX+表示確認は、修正前のnative ROM（SHA-256 `b3ad44a7fee37fed948f5ab5d5407b4bc04f8c352ca005b168ab106bb302b26e`）の結果です。今回のレビュー修正版native ROMは再ビルド済みですが、blueMSX+での表示再確認と実機検証は未実施です。

性能表は公開前の機能検証時の測定値です。今回の最終レビュー修正版を同一条件で再測定した表ではなく、性能の目安として掲載しています。
