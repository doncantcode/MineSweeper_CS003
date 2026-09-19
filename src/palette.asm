; -------------------------------------------------------------------
; Palette: gradient background (32..51), number colours (52..59),
; classic light/dark grey for tile faces and shadows (7, 8)
; -------------------------------------------------------------------
SetPalette:
    pusha
    cld
    mov dx,3C8h
    mov al,7
    out dx,al
    inc dx
    mov si,PalGrays
    mov cx,6
    rep outsb

    dec dx
    mov al,32
    out dx,al
    inc dx
    xor bl,bl
    mov cx,20
.grad:
    mov al,bl
    shr al,2
    add al,3                    ; R
    out dx,al
    mov al,bl
    shr al,1
    add al,6                    ; G
    out dx,al
    mov al,bl
    add al,16                   ; B
    out dx,al
    inc bl
    loop .grad

    dec dx
    mov al,52
    out dx,al
    inc dx
    mov si,PalNums
    mov cx,24
    rep outsb
    popa
    ret
