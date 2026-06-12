;==============================================================================
; pointer-color.ahk - レイヤー状態に応じてマウスポインタの色を切り替える
;
; torabo-tsuki LP のファームウェア（config/keymap.keymap の layer_listeners）が
; 送信するキーを検知し、SetSystemCursor API でカーソルを色付き矢印
; (cursors/*.cur) に差し替える。
; ※ Windows 11 ではアクセシビリティのカーソル色レジストリを書き換えても
;    反映されないため、SetSystemCursor による直接差し替え方式を採用。
;
;   F23: オートマウスレイヤー進入 → 緑
;        （離脱通知はない。キーコードを送るとファームウェア側の
;          require-prior-idle-ms 判定と干渉してレイヤーの再有効化が
;          ブロックされるため、マウス入力のアイドル時間から推定する）
;   F21: スクロールレイヤー進入 / F22: 離脱 → ピンク
;
; 色を変えたい場合は make-cursors.ps1 を編集して再実行する。
;
; 必要環境: AutoHotkey v2 (winget install AutoHotkey.AutoHotkey)
; 自動起動: Win+R → shell:startup にこのファイルのショートカットを置く
;==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
InstallMouseHook  ; A_TimeIdleMouse を物理マウス入力ベースにするため

MOUSE_CUR  := A_ScriptDir "\cursors\arrow_mouse.cur"   ; オートマウス中: 緑
SCROLL_CUR := A_ScriptDir "\cursors\arrow_scroll.cur"  ; スクロール中: ピンク

; オートマウスレイヤーのタイムアウト推定値 (ms)
; ファームウェアの zip_temp_layer は最終入力から700msでレイヤーを抜けるため、
; それより少し長めにとる
IDLE_TIMEOUT := 750

; 差し替え対象のシステムカーソルID（矢印・Iビーム・手）
CURSOR_IDS := [32512, 32513, 32649]  ; OCR_NORMAL, OCR_IBEAM, OCR_HAND

for f in [MOUSE_CUR, SCROLL_CUR] {
    if !FileExist(f) {
        MsgBox "カーソルファイルが見つかりません:`n" f "`n`nmake-cursors.ps1 を実行して生成してください。"
        ExitApp 1
    }
}

mouseActive  := false
scrollActive := false

OnExit (*) => RestoreCursors()
SetTimer CheckIdle, 100

; "*" 付きで修飾キー押下中（Ctrl+スクロール等）でも検知する
*F23:: {
    global mouseActive := true
    UpdateCursor()
}
*F21:: {
    global scrollActive := true
    UpdateCursor()
}
*F22:: {
    global scrollActive := false
    UpdateCursor()
}
; 旧ファームウェア（離脱時にF24を送る版）との互換: アプリに届かないよう抑制のみ
*F24:: {
}

; マウス入力が途切れたらオートマウスレイヤー終了とみなして色を戻す。
; スクロール中（mo押下中）はホイール操作が止まっていても維持し、F22で抜ける。
CheckIdle() {
    global mouseActive, scrollActive
    if (mouseActive && !scrollActive && A_TimeIdleMouse > IDLE_TIMEOUT) {
        mouseActive := false
        UpdateCursor()
    }
    ; 安全弁: F22を取り逃した場合（BT切断等）に色が固着しないようにする
    if (scrollActive && A_TimeIdleMouse > 5000) {
        scrollActive := false
        mouseActive := false
        UpdateCursor()
    }
}

UpdateCursor() {
    if scrollActive
        SetColoredCursors(SCROLL_CUR)
    else if mouseActive
        SetColoredCursors(MOUSE_CUR)
    else
        RestoreCursors()
}

SetColoredCursors(curFile) {
    ; SetSystemCursor はハンドルの所有権を奪うため、IDごとに読み込み直す
    for id in CURSOR_IDS {
        h := DllCall("LoadCursorFromFile", "Str", curFile, "Ptr")
        if h
            DllCall("SetSystemCursor", "Ptr", h, "UInt", id)
    }
}

RestoreCursors() {
    ; SPI_SETCURSORS = 0x57: ユーザー設定のカーソルスキームを再読み込み
    DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)
}
