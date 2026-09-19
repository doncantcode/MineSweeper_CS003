; -------------------------------------------------------------------
; Game state
; -------------------------------------------------------------------
NewGame:
    pusha
    push ds
    pop es
    cld
    mov di,Board
    mov cx,CELLS
    xor al,al
    rep stosb

    mov ah,00h
    int 1Ah
    xor [RndSeed],dx

    xor bl,bl                   ; mines placed
.place:
    call GetRandom
    xor dx,dx
    mov cx,CELLS
    div cx                      ; DX = 0..80
    mov si,dx
    test byte [Board+si],1
    jnz .place
    or byte [Board+si],1
    inc bl
    cmp bl,TOTAL_MINES
    jb .place

    call ComputeNumbers

    mov byte [GameOver],0
    mov byte [Started],0
    mov byte [TimerOn],0
    mov word [Seconds],0
    mov word [TickAcc],0
    mov word [HitCell],0FFFFh
    popa
    ret

GetRandom:
    push dx
    mov ax,[RndSeed]
    mov dx,25173
    mul dx
    add ax,13849
    mov [RndSeed],ax
    pop dx
    ret

; BH=row BL=col -> SI = index   (AX preserved)
CellIndex:
    push ax
    mov al,bh
    mov ah,GRID_COLS
    mul ah
    add al,bl
    xor ah,ah
    mov si,ax
    pop ax
    ret

; Fill high nibble of every safe cell with its neighbour-mine count
ComputeNumbers:
    pusha
    xor si,si
    xor ch,ch
.r:
    xor cl,cl
.c:
    and byte [Board+si],0Fh
    test byte [Board+si],1
    jnz .n
    call CountMines
    shl al,4
    or [Board+si],al
.n:
    inc si
    inc cl
    cmp cl,GRID_COLS
    jb .c
    inc ch
    cmp ch,GRID_ROWS
    jb .r
    popa
    ret

; CH=row CL=col -> AL = mines around
CountMines:
    push bx
    push dx
    push si
    xor dl,dl
    mov bh,ch
    dec bh
.lr:
    cmp bh,0
    jl .nr
    cmp bh,GRID_ROWS
    jge .nr
    mov bl,cl
    dec bl
.lc:
    cmp bl,0
    jl .nc
    cmp bl,GRID_COLS
    jge .nc
    call CellIndex
    test byte [Board+si],1
    jz .nc
    inc dl
.nc:
    inc bl
    mov al,cl
    inc al
    cmp bl,al
    jle .lc
.nr:
    inc bh
    mov al,ch
    inc al
    cmp bh,al
    jle .lr
    mov al,dl
    pop si
    pop dx
    pop bx
    ret

; First click must never be a mine: move it to the first free cell
; SI = clicked cell
RelocateMine:
    pusha
    xor bx,bx
.find:
    test byte [Board+bx],1
    jz .found
    inc bx
    jmp .find
.found:
    or byte [Board+bx],1
    and byte [Board+si],0FEh
    call ComputeNumbers
    popa
    ret

; Flood fill.  BH=row BL=col
RevealCell:
    pusha
    call CellIndex
    test byte [Board+si],6      ; opened or flagged
    jnz .done
    or byte [Board+si],2
    mov al,[Board+si]
    and al,0F0h
    jnz .done                   ; has neighbour mines -> stop
    mov dh,bh
    dec dh
.rr:
    cmp dh,0
    jl .rn
    cmp dh,GRID_ROWS
    jge .rn
    mov dl,bl
    dec dl
.cc:
    cmp dl,0
    jl .cn
    cmp dl,GRID_COLS
    jge .cn
    push bx
    mov bh,dh
    mov bl,dl
    call RevealCell
    pop bx
.cn:
    inc dl
    mov al,bl
    inc al
    cmp dl,al
    jle .cc
.rn:
    inc dh
    mov al,bh
    inc al
    cmp dh,al
    jle .rr
.done:
    popa
    ret

RevealMines:                    ; show all un-flagged mines
    pusha
    xor si,si
.l:
    mov al,[Board+si]
    test al,1
    jz .n
    test al,4
    jnz .n
    or byte [Board+si],2
.n:
    inc si
    cmp si,CELLS
    jb .l
    popa
    ret

CheckWin:
    pusha
    xor si,si
.l:
    mov al,[Board+si]
    test al,1
    jnz .n
    test al,2
    jz .out                     ; a safe tile is still closed
.n:
    inc si
    cmp si,CELLS
    jb .l
    mov byte [GameOver],2       ; won
    mov byte [TimerOn],0
    xor si,si
.f:
    test byte [Board+si],1      ; flag every mine
    jz .fn
    or byte [Board+si],4
.fn:
    inc si
    cmp si,CELLS
    jb .f
    mov si,SfxWin               ; board cleared: victory fanfare
    call StartSfx
.out:
    popa
    ret
