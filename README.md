
[torabo-tsuki LP](https://github.com/sekigon-gonnoc/torabo-tsuki-lp)用のZMKファームウェア

* _centralがついているuf2をトラックボールがついている方に、_peripheralを反対側に書き込んでください
* キーマップはkeymap-editorおよびzmk-studioで編集できます

## マウスポインタの色変更（Windows）

オートマウスレイヤー・スクロールレイヤーの出入りで F21〜F24 をホストに送信し、`host/pointer-color.ahk` がそれを検知してポインタ色を切り替えます（オートマウス中=緑、スクロール中=ピンク）。

1. AutoHotkey v2 をインストール: `winget install AutoHotkey.AutoHotkey`
2. `host/pointer-color.ahk` をダブルクリックで起動（自動起動するには `shell:startup` にショートカットを配置）

カーソルの差し替えは `SetSystemCursor` API で行います（Windows 11 ではアクセシビリティのカーソル色レジストリを書き換えても反映されないため）。色を変えたい場合は `host/make-cursors.ps1` の色指定を編集して再実行し、スクリプトを再起動してください。スクリプトが動いていないPCでは F21〜F24 がそのまま届く点に注意してください。