[English](NATIVE.md) | [日本語](NATIVE.ja.md)

# 単独PCアプリと描画の共通化

MSX側の転送はlib/libv9968のv9968.c／geo3d.cを共有します。ROMマッパー、割り込み、入力、音楽、演出はアプリに残します。CMakeは同階層のlibv9968とコピーした4ファイルのハッシュを照合し、APIの食い違いを検出します。

PC版は生成済みmotion-banks.binを直接読み、MSX BIOS、ROMローダー、外部MSXエミュレータを使いません。通常のROM・データをビルド後、次を実行します。

```bat
set OPENAL_SOFT_ROOT=E:\dependencies\openal-soft-1.25.2-bin
cmake -S . -B E:/work/motion-native -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake -DMOTION_PROFILE=8m
cmake --build E:/work/motion-native --config Release
ctest --test-dir E:/work/motion-native -C Release --output-on-failure
cd /d E:\work\motion-native\Release
motion-stage.exe
```

2 MiB／10 Hz素材を使う場合はMOTION_PROFILE=2mを指定し、別のビルドディレクトリを使います。MOTION_NATIVE_FIL=ONはR20 FIL、OFFはアプリの従来R21 FIL表示配置を選びます。画像比較は表示ページと論理VRAMの並びを揃えます。SCREEN7の物理VRAMをそのまま論理画面として比較しないでください。

T/R/C、Space、M、D、E、Esc、方向キーの意味を維持します。Shift＋方向キーのズームに加え、Z/Xも使用できます。英字コマンドは大文字でも使えます。PC版のBGMはlibv9968のオプションPSGモジュールとOpenAL Softで再生します。曲の処理を共有し、MSXのPSG再生は従来どおりです。

--ticks 4400は状態を書き換えずデモを一周検証し、--test-inputは手動操作と再開始を確認します。--at 800 --dump capture.vramは描画だけを固定時刻で比較する検証用です。ゲーム進行や性能検証とは区別します。Ubuntu／macOSはこのWindows環境では未検証で、実機と走査位相までの一致も未検証です。


## PSG音声

[libv9968の音声導入手順](../libv9968/doc/AUDIO.ja.md)に従ってOpenAL Softを導入してください。PCバイナリの再配布時には公式パッケージの表示を保持します。`--ticks 960 --wav bgm.wav` で再生機器を開かず16秒を記録できます。通常のウィンドウ実行ではOpenAL Softを開き、アプリの60 Hz時計に合わせて再生します。録音は描画回数に依存しません。実機の音声とUbuntu/macOSの再生は未検証です。
