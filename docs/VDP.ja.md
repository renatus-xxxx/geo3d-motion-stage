[English](VDP.md) | [日本語](VDP.ja.md)

# 内蔵・外部V9968への対応

同じROMで外部V9968を優先し、なければBIOSが示す本体側V9968を選びます。選択した機器のgeo3dが必須です。標準V9938／V9958での代替描画は行いません。両容量・両FIL版に共通の処理です。

## 検出手順

`src/device.c`は[HRA!さんの公式check_vdp_type.asm](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/v9968/detect/check_vdp_type.asm)のアルゴリズムをCへ適応しています。この検出処理の参照元については[MITの表示](../licenses/MIT-VDP-DETECT.txt)を残しています。

1. CPU割り込みを停止します。BIOSページ0は引き続きマップされています。BIOSの0006h／0007hの一致とMSX2以降の世代を確認し、本体VDPの垂直・水平割り込み許可を解除します。
2. S1を読み、R21のFID（bit 0）を0にしてS1を再読します。`(S1 >> 1) & 31`が3ならV9968です。最後にステータス選択をS0へ戻します。R21には副作用があり、選択したVDPは後で初期化します。BIOSのR21保存領域は書き換えません。
3. BIOSが88hブロックを指すバージョンアップアダプターの場合は二重検出を避けます。それ以外は公式サンプル同様に外部制御ポート89hを2回読み、両方bit 7が1なら未接続とします。それ以外は同じS1／FID判定を行います。
4. 外部のIDが3なら外部を優先します。選択した制御ポートからVDP・geo3dの全ポートを決定します。
5. geo3dのCOLORレジスタ44hに55hとAAhを書いて読み戻し、元の値へ戻します。描画コマンドを実行せず応答を確認します。外部V9968にgeo3dがない場合は停止し、別画面へ勝手に切り替えません。

公式資料には、データバスにプルアップがない機種では未接続の誤認があり得ると記載されています。追加のgeo3d読み戻しは一定値の未駆動応答を排除しますが、すべての電気的構成を保証するものではありません。検出はコールドブート／リセット向けで、ホットスワップや別プログラムの画面状態維持を目的としません。故障した機器がWAITを保持してCPUのI/O命令自体を停止させた場合は、ソフトウェアのタイムアウトでは復帰できません。

| アクセス | 本体98hブロック | 外部88hブロック |
|---|---|---|
| VRAMデータ | 98h | 88h |
| VDP制御・ステータス | 99h | 89h |
| パレット | 9Ah | 8Ah |
| 間接コマンドレジスタ | 9Bh | 8Bh |
| geo3dインデックス・状態 | 9Dh | 8Dh |
| geo3dデータ | 9Fh | 8Fh |

geo3dのbase+5／base+7は公式の[バスアダプター](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/geo3d/geo3d_bus.v)で確認しています。オフセット6（8Eh）はMegaRAM用で、使用しません。

## 初期化・同期

ROMローダーはBIOSのスロット処理を利用しますが、CHGMODは呼びません。選択したVDPへSCREEN 7 FIL、パレット、両VRAMページを直接設定します。FILの設定ビットはROMの種類で決まり、自動検出でFIL実装の世代まで推定しません。

VBlank割り込みを許可するのは選択したVDPだけです。IM2ハンドラーはそのS0を選択してVBlankを解除し、デモ・音楽・入力の時計を進めます。外部選択時は本体VDPの割り込みを禁止したままにし、二重に時計を数えることを防ぎます。外部のVBlankが公式カートリッジFPGA同様にMSXの割り込み線へ接続されている必要があります。割り込み中にBIOS呼び出し、ROMバンク変更、描画は行いません。60 Hz設定は維持します。

VDPコマンド、geo3d busy、次のVBlankの待機には上限があります。白画面保持中もHALTではなく上限付き待機を使います。異常時は割り込みとPSG音声を停止し、診断ループへ入ります。ボーダーの色番号は14＝未対応VDPまたは機器タイムアウト、10＝geo3d未検出、9＝VBlankなしです。実際の色は現在のパレットに依存します。`video_error`は1＝VDP busy、2＝VDP種類、3＝geo3d busy、4＝VBlank、5＝geo3d検出の失敗を区別します。リセットで再検出します。本体ボーダーが見えるかはディスプレイの接続先に依存し、BASICへは戻りません。

## エミュレータ起動と検証

通常のbatは引き続き本体側V9968＋geo3dを使います。外部拡張を接続し、その映像を表示する場合：

```bat
run-turbor.bat 8m external
run-msx2plus-cbios.bat 2m external
```

エミュレータの`HRA_V9968`と`geo3d88`拡張が必要です。この引数はエミュレータ構成用で、ROMの選択を強制しません。実機では指定不要です。外部映像を表示するときはエミュレータの映像ソースを`MSX`ではなく`V9968`にします。

```powershell
tools\verify-demo.ps1 -Profile 2m -Machine CB -Vdp external -Seconds 150 -Fit -ManualCamera -Headless
tools\verify-controls.ps1 -Profile 2m -Machine CB -Vdp external
tools\verify-devices.ps1 -Case missing-vdp
tools\verify-devices.ps1 -Case missing-geo
tools\verify-devices.ps1 -Case external-missing-geo
tools\verify-devices.ps1 -Case lost-irq
tools\verify-devices.ps1 -Case lost-irq-hold
```

最後の2つは故障試験としてエミュレータのVDP割り込みを意図的に禁止します。ゲーム進行を書き換えて合格させることはありません。最新ROMのハッシュと結果は[検証記録](../VERIFICATION.ja.md)を参照してください。FPGA、SX-2、今回のnative FIL版の動作は未検証です。
