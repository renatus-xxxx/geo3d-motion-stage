[English](THIRD_PARTY.md) | [日本語](THIRD_PARTY.ja.md)

# 参照資料とデータ

## Perfume BVH

**出典：[Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)**。公式の一次配布プロジェクトを出典とします。

- 入力: `aachan.bvh`, `kashiyuka.bvh`, `nocchi.bvh`
- 取得・検証: `tools/get-bvh.ps1` に各SHA-256を記載。

BVHには関節モーションが含まれます。人体メッシュ、MSXプログラム、変換ツールはこのプロジェクトで作成しました。


公式記事では、モーションデータとサンプルコード等をファンの二次創作向けに提供し、二次創作を公式に認めたオープンソース・プロジェクトと説明されています。このデモはそのファン制作の二次創作として扱います。
ビルドはassets/へ配置したBVHを検証し、変換データをROMへ収録します。二次配布リポジトリからの自動取得は行いません。公式プロジェクトではBVHとMP3を提供していますが、このデモはBVHのみを使い、MP3は使用・配布しません。現在ある入力ファイルを公式サイトから再取得したという意味ではなく、一次配布元への出典表記です。
未変換のBVHはGitから除外します。配布用の変換済みデータを含むROMはdist/へ収録しています。
参照元は上記の公式記事です。記事に特定のSPDXライセンス名や汎用的な利用条件一覧が記載されているとは扱いません。商用素材ライブラリ等への無制限な再配布を宣言する構成にはしていません。
BVHの利用方針と機種設定XMLの表記は別のものです。

## V9968 / geo3d / openMSX

- V9968 + geo3d: https://github.com/alexmoncks/V9968_Cartridge/tree/main/geo3d
- V9968原版: https://github.com/hra1129/V9968_Cartridge
- openMSX: https://github.com/openMSX/openMSX
- ASCII-X mapper: https://www.grauw.nl/projects/ascii-x/
- z88dk: https://github.com/z88dk/z88dk
- C-BIOS: https://cbios.sourceforge.net/

機種定義は既存のローカル検証環境からコピーします。
openMSXとその機種定義はGPL、C-BIOSはその配布ライセンスに従います。
エミュレータ・BIOSのコピーはGit対象外のローカル配置で、
FS-A1GT BIOSをこのリポジトリから配布する構成にはしていません。

機種設定tools/machines/MOTIONGT.xmlとMOTIONCB.xmlはopenMSXのGPL-2.0の機種定義から派生し、V9968を選ぶよう変更しています。対応ライセンスはlicenses/GPL-2.0.txtです。バイナリのBIOS・エミュレータは配布しません。

GPL-2.0表記は上記の2つのXML設定ファイルだけに適用し、アプリのコードやBVHモーションには適用しません。


## V9968検出アルゴリズム

HRA!さん（t.hara、2025年）のMITライセンスの公式検出サンプルを参考に、src/device.cの検出手順を実装しました。[元コードと変更点](docs/VDP.ja.md)、[著作権・MIT許諾文](licenses/MIT-VDP-DETECT.txt)を参照してください。この表示は検出サンプル由来の部分に限り、アプリ全体のライセンス表明ではありません。新規コード全体にMITを主張するものではありません。
