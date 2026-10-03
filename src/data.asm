; ===================================================================
; DATA
; ===================================================================
StrPlay     db 'Playing',0
StrLost     db 'BOOM!',0
StrWin      db 'You win!',0
StrClsTank  db 'TANK',0
StrClsMage  db 'MAGE',0
StrClsNone  db '-',0

PalGrays    db 48,48,48, 32,32,32
PalNums     db 0,0,63,  0,32,0,  63,0,0,  0,0,32
            db 32,0,0,  0,32,32, 0,0,0,   32,32,32
NumColors   db 52,53,54,55,56,57,58,59

; 3x5 font, digits 0..9, one byte per row (bits 2..0 = pixels)
Font3x5     db 7,5,5,5,7        ; 0
            db 2,6,2,2,7        ; 1
            db 7,1,7,4,7        ; 2
            db 7,1,7,1,7        ; 3
            db 5,5,7,1,1        ; 4
            db 7,4,7,1,7        ; 5
            db 7,4,7,5,7        ; 6
            db 7,1,2,2,2        ; 7
            db 7,5,7,5,7        ; 8
            db 7,5,7,1,7        ; 9

; Sprite = list of rectangles: x, y, w, h, colour  (0FFh terminates)
FlagRects   db 6,3,1,1,12       ; red pennant
            db 5,4,2,1,12
            db 4,5,3,1,12
            db 3,6,4,1,12
            db 4,7,3,1,12
            db 5,8,2,1,12
            db 6,9,1,1,12
            db 7,3,2,9,0        ; pole
            db 5,11,6,1,0       ; base
            db 3,12,10,2,0
            db 0FFh

MineRects   db 5,4,6,1,0
            db 4,5,8,6,0
            db 5,11,6,1,0
            db 2,7,12,2,0
            db 7,2,2,12,0
            db 3,3,2,2,0
            db 11,3,2,2,0
            db 3,11,2,2,0
            db 11,11,2,2,0
            db 5,5,2,2,15       ; glint
            db 0FFh

FaceDisc    db 5,0,6,1,14
            db 3,1,10,1,14
            db 2,2,12,1,14
            db 1,3,14,10,14
            db 0,5,16,6,14
            db 2,13,12,1,14
            db 3,14,10,1,14
            db 5,15,6,1,14
            db 0FFh

FaceHappy   db 4,5,2,3,0
            db 10,5,2,3,0
            db 4,9,1,1,0
            db 11,9,1,1,0
            db 5,10,6,1,0
            db 0FFh

FaceDead    db 3,4,1,1,0        ; X eyes
            db 5,4,1,1,0
            db 4,5,1,1,0
            db 3,6,1,1,0
            db 5,6,1,1,0
            db 10,4,1,1,0
            db 12,4,1,1,0
            db 11,5,1,1,0
            db 10,6,1,1,0
            db 12,6,1,1,0
            db 5,10,6,1,0       ; frown
            db 4,11,1,1,0
            db 11,11,1,1,0
            db 0FFh

FaceCool    db 2,4,5,3,0        ; sunglasses
            db 9,4,5,3,0
            db 7,4,2,1,0
            db 3,5,1,1,15
            db 10,5,1,1,15
            db 4,9,1,1,0
            db 11,9,1,1,0
            db 5,10,6,1,0
            db 0FFh
