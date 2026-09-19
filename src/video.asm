; -------------------------------------------------------------------
; Drawing primitives
; -------------------------------------------------------------------
; FillRect: AX=x BX=y CX=w DX=h, colour in [FillCol]
FillRect:
    pusha
    push es
    cld
    mov di,bx
    shl di,8
    shl bx,6
    add di,bx
    add di,ax                   ; DI = y*320 + x
    mov ax,0A000h
    mov es,ax
    mov al,[FillCol]
    mov bp,dx
    or bp,bp
    jz .end
.row:
    push di
    push cx
    rep stosb
    pop cx
    pop di
    add di,320
    dec bp
    jnz .row
.end:
    pop es
    popa
    ret

; DrawBevel: AX=x BX=y CX=w DX=h ; [BevTL] [BevBR] [BevFace]
DrawBevel:
    pusha
    mov [BvX],ax
    mov [BvY],bx
    mov [BvW],cx
    mov [BvH],dx

    mov al,[BevBR]              ; whole rect in bottom/right colour
    mov [FillCol],al
    mov ax,[BvX]
    mov bx,[BvY]
    mov cx,[BvW]
    mov dx,[BvH]
    call FillRect

    mov al,[BevTL]              ; top/left highlight
    mov [FillCol],al
    mov ax,[BvX]
    mov bx,[BvY]
    mov cx,[BvW]
    sub cx,2
    mov dx,[BvH]
    sub dx,2
    call FillRect

    mov al,[BevFace]            ; face
    mov [FillCol],al
    mov ax,[BvX]
    add ax,2
    mov bx,[BvY]
    add bx,2
    mov cx,[BvW]
    sub cx,4
    mov dx,[BvH]
    sub dx,4
    call FillRect
    popa
    ret

; DrawRects: SI -> list of (x,y,w,h,colour), 0FFh ends.
; Coordinates are relative to [OrgX],[OrgY]
DrawRects:
    pusha
    cld
.next:
    lodsb
    cmp al,0FFh
    je .done
    xor ah,ah
    add ax,[OrgX]
    push ax
    lodsb
    xor ah,ah
    add ax,[OrgY]
    mov bx,ax
    lodsb
    xor ah,ah
    mov cx,ax
    lodsb
    xor ah,ah
    mov dx,ax
    lodsb
    mov [FillCol],al
    pop ax
    call FillRect
    jmp .next
.done:
    popa
    ret

; DrawGlyph: AL = digit 0..9, [GlX],[GlY] top-left, [GlS] scale, [GlC] colour
DrawGlyph:
    pusha
    xor ah,ah
    mov si,ax
    shl ax,2
    add si,ax                   ; digit * 5
    add si,Font3x5
    mov al,[GlC]
    mov [FillCol],al
    mov bp,[GlY]
    mov byte [GlRows],5
.row:
    lodsb
    mov [GlBits],al
    mov di,[GlX]
    mov byte [GlCols],3
.col:
    test byte [GlBits],4
    jz .skip
    mov ax,di
    mov bx,bp
    xor ch,ch
    mov cl,[GlS]
    mov dx,cx
    call FillRect
.skip:
    shl byte [GlBits],1
    xor ah,ah
    mov al,[GlS]
    add di,ax
    dec byte [GlCols]
    jnz .col
    xor ah,ah
    mov al,[GlS]
    add bp,ax
    dec byte [GlRows]
    jnz .row
    popa
    ret

; PrintAt: DH=row DL=col BL=colour SI=zero-terminated string (BIOS text)
PrintAt:
    pusha
    mov ah,02h
    xor bh,bh
    int 10h
.ch:
    lodsb
    or al,al
    jz .done
    mov ah,0Eh
    int 10h
    jmp .ch
.done:
    popa
    ret
