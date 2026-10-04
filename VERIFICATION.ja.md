[English](VERIFICATION.md) | [日本語](VERIFICATION.ja.md)

# 検証結果

WindowsのV9968 + geo3d対応openMSXで検証。実機・SX-2と、今回のnative FIL ROMの実行は未検証です。旧版native ROMのblueMSX+確認は、今回のROMの検証結果には含めません。

## ROM

| ROM | Bytes | C payload bytes | SHA-256 |
|---|---:|---:|---|
| MOTION8.ROM | 8388608 | 8457 | `de19b53ff95d4d223b58aaaa49e2686da96bb0ee7156048557ad8c15ac6e651f` |
| MOT8N.ROM | 8388608 | 8388 | `d9428d4daa65d08f87d8607ae75898bea1e9f814a985aee461952059c216e726` |
| MOTION2.ROM | 2097152 | 11781 | `dbc49b47ab4ad0a868b48a4efd860308741958521045ee7ca2cbd7191e9c08f2` |
| MOT2N.ROM | 2097152 | 11712 | `16dc99148096ea0719e484950b7c4307d098188dce1ddcc73f09d360f7c9d59a` |

8 MiBはASCII16-X・20 Hz・1,410姿勢、2 MiBは標準ASCII16・10 Hz・705姿勢。どちらも16 bit座標・法線、約70.5秒。起動バンクの111バイトはC payloadと別です。Windows z88dkで4つのROMをビルドしました。

RAM配置：Cコード・定数は8400hからRAMへコピー。BSS上限はE000h未満をビルド時に検証。IM2表はE000h、割り込みジャンプはE1E1h、起動ヘルパーはE200h、スタックはF300h。最小64 KiBのメインRAM、256 KiBのV9968 VRAMが必要です。

## 検証環境

FS-A1GT BIOS / R800 DRAM / 512 KiB RAM (MOTIONGT); C-BIOS 0.29 MSX2+ JP / Z80 / 64 KiB RAM (MOTIONCB).

BASICコマンド、ディスク、セーブ状態なしのROM起動。SCREEN 7 FIL 512×424・16色・RGB5、geo3dの焦点距離320、中心256/212、近クリップ48。60 Hzに設定します。旧FILはR20=11h/R21=7Ah、nativeはR20=31h/R21=3Ah。50 Hz再生は今回の対象外です。

openMSX: `21.0-unknown`, executable SHA-256 `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`.

正確なソースリビジョンとビルド日は未記録です。参照forkから同一バイナリを再現できる保証はありません。

## 機能・品質

- 両容量・両CPUでコールドブート、CPUモード、自然な1周と再開始、白画面・音楽フェード、リセット後の起動を確認。
- 実際のキーマトリクス入力でD/T/R/C/M/Space/E/Escを検証。ミュート中も音楽時計を進め、再有効時の音程を再設定します。
- 自動デモは外部入力列を使わず、ROM内の時刻ベース処理で表示効果・人物選択・回転・ズームを切り替えます。
- 8 MiBの253,800頂点・304,560面、2 MiBの126,900頂点・152,280面の保存座標／法線を照合。境界箱は5,640＋2,820個が元の頂点走査結果と完全一致。
- 自動デモの全表示フレームで、人物・過去姿勢・映り込みの全頂点を独立投影し、近クリップ面と512×424画面内を確認。上位バンク256以上も使用確認。低FPSでは最後の姿勢を飛ばす可能性があるため、最大バンク完全一致を毎回は要求しません。
- 手動カメラも両容量・両CPUで実キー入力により回転・ズーム・人物選択を検証。効果有効時を含め人物の全頂点を画面内に、床の四隅を近クリップ面より奥に保持できることを確認。
- 2 MiBの自動マッパー判別は検証用openMSXでは起動せず、ASCII16を明示して起動成功。実機SX-2ローダーは未検証です。

## 性能（表示FPS）

| Profile / CPU | Plain BGM on/off | Effects BGM on/off | Scan plain/effects |
|---|---:|---:|---:|
| 8m / R800 | 15.00 / 15.00 | 8.57 / 8.57 | 12.87 / 6.00 |
| 8m / Z80 | 6.00 / 6.13 | 2.30 / 2.30 | 3.53 / 1.23 |
| 2m / R800 | 15.00 / 15.00 | 8.57 / 8.57 | 12.17 / 5.63 |
| 2m / Z80 | 5.00 / 5.00 | 2.07 / 2.13 | 3.17 / 1.20 |

エミュレータ時間8〜38秒の30秒間、3人・固定手動カメラで測定。効果ありは残像＋映り込み。走査版は同じモデル・カメラ・描画で境界だけを頂点から毎回計算する比較用ビルドです。実機性能ではありません。

PSG処理は1割り込みあたりZ80約535／291 µs（有／無）、R800約103／60 µs。BGM停止によるFPS差は小さいため標準では有効。16 bit単位の法線コピー案は通常FPSが変わらず、コードが27バイト増えたため不採用。

## 長時間稼働

| ROM / CPU | Time basis | Status |
|---|---|---|
| 8m / R800 | 6 h real time | PASS |
| 8m / Z80 | 6 h real time | PASS |
| 2m / R800 | 6 h real time | PASS |
| 2m / Z80 | 6 h real time | PASS |
| 8m / Z80 | 8 h emulated time | PASS |
| 2m / Z80 | 8 h emulated time | PASS |

- 8m/R800/6h: `PASS seconds=21600 loops=301 whiteouts=301 clock_wraps=19 frame_wraps=4 max_bank=354 wall_seconds=21604`
- 8m/Z80/6h: `PASS seconds=21600 loops=300 whiteouts=300 clock_wraps=19 frame_wraps=1 max_bank=354 wall_seconds=21601`
- 2m/R800/6h: `PASS seconds=21600 loops=301 whiteouts=301 clock_wraps=19 frame_wraps=4 max_bank=119 wall_seconds=21603`
- 2m/Z80/6h: `PASS seconds=21600 loops=299 whiteouts=299 clock_wraps=19 frame_wraps=1 max_bank=119 wall_seconds=21601`
- 8m/Z80/8h: `PASS seconds=28800 loops=400 whiteouts=400 clock_wraps=26 frame_wraps=2 max_bank=354 wall_seconds=2547`
- 2m/Z80/8h: `PASS seconds=28800 loops=399 whiteouts=399 clock_wraps=26 frame_wraps=1 max_bank=119 wall_seconds=2188`

最終ROMのハッシュを記録し、ROMをコピーした独立プロセスで実行。6時間は実時間、8時間は高速実行した仮想時間です。ウィンドウ描画を停止してもMSX側のgeo3d／VDP命令とVBlank待機は実行します。再起動や修正前に中断した時間は含みません。16 bit時計の桁あふれと表示枚数の桁あふれも集計します。

## レビュー・参照

Claude Codeの指摘に対応し、VDP初期化中の割り込み、R800の待機猶予、エラー保持、重複接続情報、bakeメタデータ、検証時計の競合・検証ゼロ件、上位バンク、床の近クリップ面を修正しました。

- [SX-2 / OCM ESE-MegaRAM history](https://github.com/gnogni/ocm-pld-dev/blob/master/history.txt)
- [ASCII16-X specification](https://www.grauw.nl/projects/ascii-x/ascii16-x/)
- [V9968 command engine](https://github.com/hra1129/V9968_Cartridge/blob/main/fpga/V9968_Cartridge_TangNano20K/src/v9968/vdp_command.v)
- [BVH primary source](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/)
