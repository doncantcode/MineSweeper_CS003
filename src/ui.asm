; -------------------------------------------------------------------
; Screen composition
; -------------------------------------------------------------------
DrawBackground:
    pusha
    xor si,si
    xor bx,bx
.b:
    mov ax,si
    add al,32
    mov [FillCol],al
    xor ax,ax
    mov cx,320
    mov dx,10
    call FillRect
    add bx,10
    inc si
    cmp si,20
    jb .b
    popa
    ret

DrawStatic:
    pusha
    call DrawBackground

    mov byte [FillCol],0        ; window drop shadow
    mov ax,85
    mov bx,7
    mov cx,158
    mov dx,193
    call FillRect

    BEVEL 1,81,3,158,193,7      ; window
    BEVEL 0,86,8,148,30,7       ; header panel
    BEVEL 0,86,43,148,148,7     ; board frame

    TXT 1,1,14,'MINE'
    TXT 2,1,14,'SWEEPER'
    TXT 5,1,15,'CONTROLS'
    TXT 7,1,11,'L-Click'
    TXT 8,1,7,'open tile'
    TXT 10,1,11,'R-Click'
    TXT 11,1,7,'flag tile'
    TXT 13,1,11,'R / Face'
    TXT 14,1,7,'new game'
    TXT 16,1,11,'ESC'
    TXT 17,1,7,'menu'
    TXT 19,1,11,'M'
    TXT 20,1,7,'music'

    TXT 1,31,15,'STATUS'
    TXT 6,31,15,'BOARD'
    TXT 7,31,7,'9x9 grid'
    TXT 8,31,7,'10 mines'
    TXT 10,31,15,'CLASS'

    cmp byte [SelectedClass],1  ; class name under it
    jne .clsMage
    mov si,StrClsTank
    jmp .clsDraw
.clsMage:
    cmp byte [SelectedClass],2
    jne .clsNone
    mov si,StrClsMage
    jmp .clsDraw
.clsNone:
    mov si,StrClsNone
.clsDraw:
    mov dh,11
    mov dl,31
    mov bl,14
    call PrintAt
    popa
    ret

Redraw:
    pusha
    HIDEM
    call RenderBoard
    call DrawHeader
    call DrawStatus
    call DrawKit
    SHOWM
    popa
    ret

DrawTimer:
    pusha
    HIDEM
    mov ax,[Seconds]
    mov di,190
    call DrawLed
    SHOWM
    popa
    ret

RenderBoard:
    pusha
    xor si,si
    xor ch,ch
.row:
    xor cl,cl
.col:
    mov al,cl
    xor ah,ah
    shl ax,4
    add ax,START_X
    mov [OrgX],ax
    mov al,ch
    xor ah,ah
    shl ax,4
    add ax,START_Y
    mov [OrgY],ax
    mov al,[Board+si]
    call DrawCell
    inc si
    inc cl
    cmp cl,GRID_COLS
    jb .col
    inc ch
    cmp ch,GRID_ROWS
    jb .row
    popa
    ret

; AL = cell byte, SI = cell index, tile origin in [OrgX],[OrgY]
DrawCell:
    pusha
    mov [CellVal],al
    test al,2
    jnz .opened

    BEVEL 1,[OrgX],[OrgY],16,16,7     ; raised, unopened tile
    test byte [CellVal],4
    jz .out
    mov si,FlagRects
    call DrawRects
    jmp .out

.opened:
    mov al,7
    cmp si,[HitCell]
    jne .col
    mov al,12                   ; the mine you stepped on
.col:
    mov [CellCol],al
    mov byte [FillCol],8        ; thin dark border
    mov ax,[OrgX]
    mov bx,[OrgY]
    mov cx,16
    mov dx,16
    call FillRect
    mov al,[CellCol]
    mov [FillCol],al
    mov ax,[OrgX]
    inc ax
    mov bx,[OrgY]
    inc bx
    mov cx,15
    mov dx,15
    call FillRect

    mov al,[CellVal]
    test al,1
    jz .number
    mov si,MineRects
    call DrawRects
    jmp .out
.number:
    shr al,4
    jz .out
    mov bl,al
    xor bh,bh
    mov dl,[NumColors+bx-1]
    mov [GlC],dl
    mov byte [GlS],2
    mov dx,[OrgX]
    add dx,5
    mov [GlX],dx
    mov dx,[OrgY]
    add dx,3
    mov [GlY],dx
    call DrawGlyph
.out:
    popa
    ret

DrawHeader:
    pusha
    xor cx,cx                   ; count flags
    xor si,si
.cnt:
    test byte [Board+si],4
    jz .nx
    inc cx
.nx:
    inc si
    cmp si,CELLS
    jb .cnt
    mov ax,TOTAL_MINES
    sub ax,cx                   ; mines left (may go negative)
    mov di,91
    call DrawLed
    mov ax,[Seconds]
    mov di,190
    call DrawLed
    call DrawFace
    popa
    ret

; LED counter: AX = signed value, DI = box x
DrawLed:
    pusha
    mov [LedVal],ax
    mov [LedX],di
    BEVEL 0,di,12,39,21,0

    mov byte [GlS],3
    mov byte [GlC],12
    mov word [GlY],15
    mov bx,[LedX]
    add bx,3
    mov [GlX],bx
    mov ax,[LedVal]
    or ax,ax
    jns .pos
    neg ax
    cmp ax,99
    jbe .negok
    mov ax,99
.negok:
    mov [LedVal],ax
    mov byte [FillCol],12       ; minus sign
    mov ax,[GlX]
    mov bx,21
    mov cx,9
    mov dx,3
    call FillRect
    add word [GlX],12
    mov ax,[LedVal]
    jmp .two
.pos:
    cmp ax,999
    jbe .three
    mov ax,999
.three:
    xor dx,dx
    mov bx,100
    div bx
    push dx
    call DrawGlyph
    add word [GlX],12
    pop ax
.two:
    mov bl,10
    div bl                      ; AL tens, AH ones
    push ax
    call DrawGlyph
    add word [GlX],12
    pop ax
    mov al,ah
    call DrawGlyph
    popa
    ret

DrawFace:
    pusha
    BEVEL 1,149,12,22,22,7
    mov word [OrgX],152
    mov word [OrgY],15
    mov si,FaceDisc
    call DrawRects
    mov al,[GameOver]
    mov si,FaceHappy
    cmp al,1
    jne .n1
    mov si,FaceDead
.n1:
    cmp al,2
    jne .go
    mov si,FaceCool
.go:
    call DrawRects
    popa
    ret

DrawStatus:
    pusha
    BEVEL 0,244,20,72,16,0
    mov si,StrPlay
    mov bl,10
    cmp byte [ScanArmed],0      ; scanner armed: persistent prompt
    je .kitmsg
    mov si,StrArmed
    mov bl,14
    jmp .go
.kitmsg:
    cmp byte [KitMsgT],0        ; transient skill message
    je .gamest
    mov al,[KitMsgN]
    cmp al,1
    jne .m2
    mov si,StrShield
    mov bl,11
    jmp .go
.m2:
    cmp al,2
    jne .m3
    mov si,StrScanned
    mov bl,11
    jmp .go
.m3:
    mov si,StrNoScan
    mov bl,12
    jmp .go
.gamest:
    mov al,[GameOver]
    cmp al,1
    jne .n1
    mov si,StrLost
    mov bl,12
.n1:
    cmp al,2
    jne .go
    mov si,StrWin
    mov bl,14
.go:
    mov dh,3
    mov dl,31
    call PrintAt
    popa
    ret

; DrawKit: class kit state line(s) under CLASS (called from Redraw)
DrawKit:
    pusha
    cmp byte [SelectedClass],1
    je .tank
    cmp byte [SelectedClass],2
    je .mage
    jmp .out
.tank:
    mov bl,11
    mov si,StrShldOn
    cmp byte [TankShield],0
    jne .td
    mov bl,8
    mov si,StrShldOff
.td:
    mov dh,12
    mov dl,31
    call PrintAt
    jmp .out
.mage:
    mov bl,11
    mov si,StrScanOn
    cmp byte [MageScans],0
    jne .md
    mov bl,8
    mov si,StrScanOff
.md:
    mov dh,12
    mov dl,31
    call PrintAt
    mov bl,7
    mov si,StrScanHint
    mov dh,13
    mov dl,31
    call PrintAt
.out:
    popa
    ret
