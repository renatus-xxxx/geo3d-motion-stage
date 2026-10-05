[English](VERIFICATION.md) | [日本語](VERIFICATION.ja.md)

# 検証結果

## port4修正版（2026-10-05）

R21による検出前にport4へ00hを書き、R20／R21のロックを解除します。本体9Ch・外部8Chを対象とし、動作実績のあるNight Ravenと同じ初期化順序です。4 ROMを再ビルド・配布更新しました。コード増加は13バイト、32768バイト以降のモーションデータは旧版と一致します。

従来FIL版のR800／Z80・8 MiB／2 MiB・内蔵／外部の8構成で、各150秒（エミュレータ時間）の描画・操作・デモ完走・ホワイトアウト・自動再開始がPASS。ログはローカルoutput/verify-*-port4/events.txt。native FIL版はビルド確認のみ、FPGA実機での修正効果は未確認です。以前の操作・リセット・故障・長時間検証は下記の旧ハッシュに対する結果で、このROMへ引き継ぎません。

| ROM | SHA-256 |
|---|---|
| MOTION8.ROM | `ed3b6a0b885e405cbe9a41b93a6e0fbd8d833a18ad28804c0be91babb7e08c06` |
| MOT8N.ROM | `8fc8449a233c4cfdc7f500f5586dbd8606bd0039da699ba181323c4c4405370c` |
| MOTION2.ROM | `36ee57762e52119b32752b1793ea1170a4adcce78934eb32fc927b68a8435cec` |
| MOT2N.ROM | `da1a70d17dcb0bfd4eba9f18fb4238d7a11beefc273cddac3c5c5eab2f9d29eb` |

## 内蔵・外部VDP対応版（2026-10-05）

WindowsのV9968 + geo3d対応openMSX 21.0-unknownで検証。エミュレータのSHA-256は `140c7a8cdbffda42488e7cf8fedcc2fd735a01bc68ac891d93f8b96db337c7bd`。GTはFS-A1GT BIOS／R800 DRAM／512 KiB RAM、CBはC-BIOS 0.29 MSX2+ JP／Z80／64 KiB RAMです。BASICコマンド・ディスク・セーブ状態は使用していません。

Windows z88dkで4つのROMをビルドしました。容量、モーションデータ、法線、FIL設定、必要RAMは維持しています。コードは8400hへコピーし、BSS上限E000h未満をビルド時に検証します。ポートとエラーコードは[検出・同期の仕様](docs/VDP.ja.md)を参照してください。

| ROM | バイト数 | SHA-256 |
|---|---:|---|
| MOTION8.ROM | 8388608 | `594c27ffc53e069f1718dd903c61ad067d794ede7a5cc96876caa543650d358a` |
| MOT8N.ROM | 8388608 | `163e69a50816ee5beded32ca28207aec8895ac4740d84123d59174c8f140450e` |
| MOTION2.ROM | 2097152 | `8a1b590b4f3044dd1c5ccec3ac5a088dec8bb76c9f00e6c056a9acf14ae8dcab` |
| MOT2N.ROM | 2097152 | `25ff090ee622df5c2ca3fafc9791f8b85a14ccd24bbfc40e4fb1e6b67d0f8d70` |

## 今回のROMの回帰検証

各デモ検証は仮想時間150秒です。実際のキー入力で人物選択、残像・映り込み、カメラの限界操作を行い、頂点の投影と床の近クリップを検査した後、自然なホワイトアウトと自動再開始を確認します。別の操作検証で、停止、ミュートと音楽位相、終了演出、Esc／D、リセット後のコールドブートを確認します。external行では本体・外部の両V9968が存在し、外部優先を検証しています。起動時にVDP・geo3dの選択ポートも確認しています。

| 容量／CPU／選択VDP | デモ・投影 | 操作・リセット |
|---|---|---|
| 8m / GT / internal | PASS | PASS |
| 8m / GT / external | PASS | PASS |
| 8m / CB / internal | PASS | PASS |
| 8m / CB / external | PASS | PASS |
| 2m / GT / internal | PASS | PASS |
| 2m / GT / external | PASS | PASS |
| 2m / CB / internal | PASS | PASS |
| 2m / CB / external | PASS | PASS |

追加で各CPUの2 MiB版を、標準内蔵V9958＋外部HRA_V9968／geo3d88で起動し、自然なデモ一巡を確認しました。標準内蔵V9958のみはエラー2、本体V9968のgeo3dなしと標準内蔵V9958＋外部V9968のgeo3dなしはエラー5で停止します。通常再生中と白画面保持中のそれぞれで、エミュレータのVBlank割り込みを意図的に禁止し、エラー4で時計が停止することを確認しました。HALTの無限待ちは発生しません。機器異常の5試験はすべてPASSです。

BGM有効・固定カメラ・通常描画の仮想時間30秒の測定は、R800が両容量15.00 FPS、Z80の8 MiBが6.00 FPS、2 MiBが5.00 FPSでした。エミュレータ上の結果で、実機性能ではありません。

## 制約と旧版の検証

今回のnative FIL ROMはビルドのみ確認しています。FPGA実機、SX-2実機、バスのプルアップ条件、バージョンアップアダプターによるBIOSポート変更は未検証です。内蔵・外部の機能試験は画面表示なしで行いますが、ゲストのgeo3d／VDP描画とVBlank待機は実行されます。外部2 MiB／Z80と8 MiB／R800では映像ソースV9968の画像を目視し、人物と床の映り込みも確認しました。両容量・両CPUの外部起動batを実際に起動し、throttle=true／speed=100、正しいCPUと制御ポート89hを確認しました。実機モニターの入力切り替えはプログラムの範囲外です。

旧版の実時間6時間・仮想時間8時間のPASSは `de19b53f…`（8 MiB）と `dbc49b47…`（2 MiB）に対する結果です。今回の新ROMでは6時間連続試験を再実施していません。既存の比較動画・プレビューは、同じモーションと表示設定を持つ旧版の収録です。

検出は[HRA!さんの公式サンプル](https://github.com/hra1129/V9968_Cartridge/blob/dceec5a50c7c2a5d107a0c6ce8d10cf232e43474/fpga/V9968_Cartridge_TangNano20K/src/v9968/detect/check_vdp_type.asm)に基づきます。適用範囲を限定した表示は[THIRD_PARTY.ja.md](THIRD_PARTY.ja.md)に記載しています。
