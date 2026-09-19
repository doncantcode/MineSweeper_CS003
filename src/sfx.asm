; -------------------------------------------------------------------
; Sound effects, same (frequency, ticks) format as SongTable
; -------------------------------------------------------------------
SfxBoom:                        ; mine goes off: crack, then a rumble
    dw 400,1, 250,1, 180,1, 140,1, 110,1, 90,1
    dw 130,1, 70,1, 100,1, 60,1, 85,1, 50,1
    dw 65,1, 42,1, 52,1, 34,1
    dw 40,2, 28,2, 22,2
    dw 0,2
    dw 0FFFFh, 0

SfxWin:                         ; board cleared: rising D major fanfare
    dw 587,2, 740,2, 880,2, 1175,3
    dw 0,1
    dw 880,1, 1175,1, 1480,1, 1760,3
    dw 1175,6, 0,2
    dw 0FFFFh, 0
