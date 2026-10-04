; -------------------------------------------------------------------
; Mouse click handling.  MouseX/MouseY = pixel, PrevMouse = buttons
; -------------------------------------------------------------------
HandleClick:
    pusha

    ; --- face button (new game) ---
    mov ax,[MouseX]
    cmp ax,149
    jl .board
    cmp ax,171
    jge .board
    mov ax,[MouseY]
    cmp ax,12
    jl .board
    cmp ax,34
    jge .board
    test byte [PrevMouse],1
    jz .out
    call DoRestart
    jmp .out

    ; --- board ---
.board:
    cmp byte [GameOver],0
    jne .out

    mov ax,[MouseX]
    sub ax,START_X
    jl .out
    cmp ax,GRID_COLS*16
    jge .out
    shr ax,4
    mov dl,al                   ; column
    mov ax,[MouseY]
    sub ax,START_Y
    jl .out
    cmp ax,GRID_ROWS*16
    jge .out
    shr ax,4
    mov dh,al                   ; row

    mov bh,dh
    mov bl,dl
    call CellIndex              ; SI = cell index

    test byte [PrevMouse],1
    jnz .left
    test byte [PrevMouse],2
    jnz .right
    jmp .out

.left:
    cmp byte [ScanArmed],0      ; mage scanner armed?
    je .plainLeft
    mov byte [ScanArmed],0
    cmp byte [MageScans],0
    je .plainLeft               ; no charges: click opens normally
    dec byte [MageScans]
    mov byte [KitMsgN],2        ; "SCANNED!" for a moment
    mov byte [KitMsgT],36
    call ScanArea               ; DH:DL still hold the target cell
    call Redraw
    jmp .out
.plainLeft:
    cmp byte [BombArmed],0
    jne .useBomb
    test byte [Board+si],6      ; flagged or already open
    jnz .out
    cmp byte [Started],0
    jne .go
    mov byte [Started],1        ; first click: start timer, be safe
    mov byte [TimerOn],1
    mov word [TickAcc],0
    test byte [Board+si],1
    jz .go
    call RelocateMine
.go:
    test byte [Board+si],1
    jnz .boom
    call RevealCell
    call CheckWin
    call Redraw
    jmp .out
.useBomb:
    cmp byte [Started],0
    jne .dropBomb
    mov byte [Started],1
    mov byte [TimerOn],1
    mov word [TickAcc],0
    test byte [Board+si],1
    jz .dropBomb
    call RelocateMine
.dropBomb:
    mov byte [BombArmed],0
    dec byte [BombCount]
    call BombArea               ; DH:DL remains the chosen centre
    mov byte [KitMsgN],5
    mov byte [KitMsgT],36
    call CheckWin
    call Redraw
    jmp .out
.boom:
    cmp byte [SelectedClass],1  ; tank with a shield left?
    jne .realBoom
    cmp byte [TankShield],0
    je .realBoom
    dec byte [TankShield]       ; absorb the blast...
    or byte [Board+si],4        ; ...and pin the mine: flag stays down
    mov byte [KitMsgN],1        ; "SHIELD!" for a moment
    mov byte [KitMsgT],36
    call Redraw
    jmp .out
.realBoom:
    mov byte [GameOver],1
    mov byte [TimerOn],0
    mov [HitCell],si
    call RevealMines
    call Redraw
    mov si,SfxBoom
    call StartSfx
    jmp .out

.right:
    test byte [Board+si],2      ; can't flag an open tile
    jnz .out
    xor byte [Board+si],4       ; toggle flag
    call Redraw

.out:
    popa
    ret
