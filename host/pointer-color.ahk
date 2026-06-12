;==============================================================================
; pointer-color.ahk - レイヤー状態に応じてマウスポインタの色を切り替える
;
; torabo-tsuki LP のファームウェア（config/keymap.keymap の layer_listeners）が
; レイヤー出入りで送信する F21-F24 を検知し、Windows のアクセシビリティ
; カーソル色を書き換える。
;
;   F23: オートマウスレイヤー進入 / F24: 離脱
;   F21: スクロールレイヤー進入   / F22: 離脱
;
; 必要環境: AutoHotkey v2 (winget install AutoHotkey.AutoHotkey)
; 自動起動: Win+R → shell:startup にこのファイルのショートカットを置く
;==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; 色設定 (0xRRGGBB)
MOUSE_COLOR  := 0x00C800  ; オートマウス中: 緑
SCROLL_COLOR := 0xFF40A0  ; スクロール中: ピンク

REG_KEY := "HKCU\Software\Microsoft\Accessibility"

; 起動時点の設定を保存（復元用。未設定なら既定の白カーソル相当）
origType  := RegRead(REG_KEY, "CursorType", 0)
origColor := RegRead(REG_KEY, "CursorColor", 0xFFFFFF)

mouseActive  := false
scrollActive := false

OnExit (*) => RestoreCursor()

; "*" 付きで修飾キー押下中（Ctrl+スクロール等）でも検知する
*F23:: {
    global mouseActive := true
    UpdateCursor()
}
*F24:: {
    global mouseActive := false
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

UpdateCursor() {
    if scrollActive
        SetCursorColor(SCROLL_COLOR)
    else if mouseActive
        SetCursorColor(MOUSE_COLOR)
    else
        RestoreCursor()
}

SetCursorColor(rgb) {
    ; レジストリの CursorColor は COLORREF (0x00BBGGRR)
    bgr := ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 0xFF)
    RegWrite 6, "REG_DWORD", REG_KEY, "CursorType"  ; 6 = カスタム色カーソル
    RegWrite bgr, "REG_DWORD", REG_KEY, "CursorColor"
    ApplyCursors()
}

RestoreCursor() {
    RegWrite origType, "REG_DWORD", REG_KEY, "CursorType"
    RegWrite origColor, "REG_DWORD", REG_KEY, "CursorColor"
    ApplyCursors()
}

ApplyCursors() {
    ; SPI_SETCURSORS = 0x57, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 0x3
    DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0x3)
}
