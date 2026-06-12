# 色付き矢印カーソル (.cur) を生成する
# 色を変えたい場合はこのスクリプト末尾の色指定を変更して再実行する
Add-Type -AssemblyName System.Drawing

function New-ArrowCursor([string]$Path, [System.Drawing.Color]$Fill) {
    $size = 32
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # 標準的な矢印の輪郭（ホットスポットは左上 (0,0)）
    [System.Drawing.PointF[]]$pts = @(
        (New-Object System.Drawing.PointF 1, 1),
        (New-Object System.Drawing.PointF 1, 24),
        (New-Object System.Drawing.PointF 7, 19),
        (New-Object System.Drawing.PointF 11, 28),
        (New-Object System.Drawing.PointF 15, 26),
        (New-Object System.Drawing.PointF 11, 18),
        (New-Object System.Drawing.PointF 19, 18)
    )
    $brush = New-Object System.Drawing.SolidBrush $Fill
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1.5
    $g.FillPolygon($brush, $pts)
    $g.DrawPolygon($pen, $pts)
    $g.Dispose()

    # 32bppピクセルデータ (ボトムアップ BGRA)
    $px = New-Object byte[] ($size * $size * 4)
    $i = 0
    for ($y = $size - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $size; $x++) {
            $c = $bmp.GetPixel($x, $y)
            $px[$i++] = $c.B; $px[$i++] = $c.G; $px[$i++] = $c.R; $px[$i++] = $c.A
        }
    }
    $bmp.Dispose()

    $andMaskBytes = ($size / 8) * $size  # 1bpp ANDマスク（アルファ使用のため全0）
    $bmpDataSize = 40 + $px.Length + $andMaskBytes

    $ms = New-Object System.IO.MemoryStream
    $w = New-Object System.IO.BinaryWriter $ms
    # ICONDIR: reserved=0, type=2(cursor), count=1
    $w.Write([uint16]0); $w.Write([uint16]2); $w.Write([uint16]1)
    # ICONDIRENTRY: w, h, colors, reserved, hotspotX, hotspotY, size, offset
    $w.Write([byte]$size); $w.Write([byte]$size); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]0); $w.Write([uint16]0)   # ホットスポット (0,0)
    $w.Write([uint32]$bmpDataSize); $w.Write([uint32]22)
    # BITMAPINFOHEADER（高さはXOR+ANDで2倍）
    $w.Write([uint32]40); $w.Write([int32]$size); $w.Write([int32]($size * 2))
    $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]0)
    $w.Write([uint32]($px.Length + $andMaskBytes))
    $w.Write([int32]0); $w.Write([int32]0); $w.Write([uint32]0); $w.Write([uint32]0)
    $w.Write($px)
    $w.Write((New-Object byte[] $andMaskBytes))
    [System.IO.File]::WriteAllBytes($Path, $ms.ToArray())
    $w.Dispose()
    Write-Host "generated: $Path"
}

$dir = Join-Path $PSScriptRoot "cursors"
New-Item -ItemType Directory -Force $dir | Out-Null
New-ArrowCursor (Join-Path $dir "arrow_mouse.cur")  ([System.Drawing.Color]::FromArgb(0x00, 0xC8, 0x00))  # オートマウス中: 緑
New-ArrowCursor (Join-Path $dir "arrow_scroll.cur") ([System.Drawing.Color]::FromArgb(0xFF, 0x40, 0xA0))  # スクロール中: ピンク
