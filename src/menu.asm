; -------------------------------------------------------------------
; Game Mode Selection Menu
; -------------------------------------------------------------------

ShowModeMenu:
    pusha

    call DrawBackground

    ; centered menu window
    BEVEL 1,80,30,160,140,7

    ; title
    TXT 5,14,15,'SELECT MODE'

    ; buttons
    BEVEL 1,100,65,120,25,7
    TXT 9,16,15,'VANILLA'

    BEVEL 1,100,100,120,25,7
    TXT 13,16,15,'ENDLESS'

    BEVEL 1,100,135,120,25,7
    TXT 17,17,15,'RAPID'

    SHOWM

.waitClick:
    mov ax,0003h                ; read mouse state
    int 33h

    test bx,1                   ; left mouse button pressed?
    jz .waitClick

    shr cx,1                    ; mouse X: 0..639 -> 0..319

    ; X must be inside all three buttons
    cmp cx,100
    jb .waitRelease
    cmp cx,219
    ja .waitRelease

    ; Vanilla: Y = 65..89
    cmp dx,65
    jb .waitRelease
    cmp dx,89
    jbe .vanilla

    ; Endless: Y = 100..124
    cmp dx,100
    jb .waitRelease
    cmp dx,124
    jbe .endless

    ; Rapid: Y = 135..159
    cmp dx,135
    jb .waitRelease
    cmp dx,159
    jbe .rapid

.waitRelease:
    mov ax,0003h
    int 33h
    test bx,1
    jnz .waitRelease
    jmp .waitClick

.vanilla:
    mov byte [CurrentMode],0
    jmp .selected

.endless:
    mov byte [CurrentMode],1
    jmp .selected

.rapid:
    mov byte [CurrentMode],2

.selected:
    ; wait until mouse button is released
.release:
    mov ax,0003h
    int 33h
    test bx,1
    jnz .release

    HIDEM
    popa
    ret
