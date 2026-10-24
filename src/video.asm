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

; PrintAt: DH=row DL=col BL=colour SI=zero-terminated string.
; Draws the 8x8 ROM font straight into mode 13h video memory on the
; 40x25 character grid.  The cell background comes from [TextBg]:
; 0FFh = the sidebar gradient behind the cell, anything else = that
; solid colour (so text sits cleanly on dialogs and panels instead of
; on black BIOS boxes).  Text is clipped at column 40 - it never wraps
; onto the next row or scrolls the screen like BIOS teletype output.
PrintAt:
    pusha
    push es
    cmp word [FontSeg],0
    jne .haveFont
    push dx
    push bx
    push si
    mov ax,1130h                ; get ROM 8x8 font pointer -> ES:BP
    mov bh,3
    int 10h
    mov [FontOff],bp
    mov [FontSeg],es
    pop si
    pop bx
    pop dx
.haveFont:
    mov [TxtFg],bl
    mov al,dh
    xor ah,ah
    shl ax,3
    mov [TxtY],ax               ; pixel row of the text line
    mov cl,dl                   ; current column
.ch:
    lodsb
    or al,al
    jz .done
    cmp cl,40
    jae .done
    call DrawChar8
    inc cl
    jmp .ch
.done:
    pop es
    popa
    ret

; DrawChar8: AL = character, CL = column, [TxtY] = pixel row,
; [TxtFg] = colour, [TextBg] = background (0FFh = gradient)
DrawChar8:
    pusha
    push es
    xor ah,ah                   ; copy the glyph's 8 rows locally
    shl ax,3
    add ax,[FontOff]
    mov si,ax
    mov ax,[FontSeg]
    push ds
    push ds
    pop es
    mov di,GlyphBuf
    mov ds,ax
    movsw
    movsw
    movsw
    movsw
    pop ds

    mov bx,[TxtY]               ; DI = y*320 + col*8
    mov di,bx
    shl di,6
    mov ax,bx
    shl ax,8
    add di,ax
    xor ch,ch
    shl cx,3
    add di,cx
    mov ax,0A000h
    mov es,ax
    mov si,GlyphBuf
    mov bp,8
.row:
    mov al,[TextBg]
    cmp al,0FFh
    jne .bgSet
    mov ax,bx                   ; gradient band: colour 32 + y/10
    mov dl,10
    div dl
    add al,32
.bgSet:
    mov [TxtRowBg],al
    lodsb
    mov ah,al
    mov cx,8
.px:
    mov al,[TxtRowBg]
    shl ah,1
    jnc .put
    mov al,[TxtFg]
.put:
    stosb
    loop .px
    add di,312
    inc bx
    dec bp
    jnz .row
    pop es
    popa
    ret

; PrintSpaces: CL spaces at DH/DL with the current [TextBg] (clears a field, CL <= 40)
PrintSpaces:
    pusha
    mov si,Spaces40
    xor ch,ch
    sub si,cx
    add si,40
    call PrintAt
    popa
    ret

; WordToStr: AX = unsigned word, DI -> buffer (at least 6 bytes).
WordToStr:
    push bx
    push cx
    push dx
    push si
    mov si,di
    mov bx,10
    xor cx,cx
.divLp:
    xor dx,dx
    div bx
    push dx
    inc cx
    or ax,ax
    jnz .divLp
.popLp:
    pop dx
    add dl,'0'
    mov [si],dl
    inc si
    dec cx
    jnz .popLp
    mov byte [si],0
    pop si
    pop dx
    pop cx
    pop bx
    ret

; PrintWordAt: AX = unsigned word, DH = row, DL = col, BL = colour
PrintWordAt:
    pusha
    mov di,NumStrBuf
    call WordToStr
    mov si,NumStrBuf
    call PrintAt
    popa
    ret
