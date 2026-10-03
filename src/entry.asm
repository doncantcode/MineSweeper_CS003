; -------------------------------------------------------------------
; Program start
; -------------------------------------------------------------------
start:
    cld
    mov ax,0003h                ; 80x25 text: intro + main menu
    int 10h
    call MainMenu               ; sets [CurrentMode]; Exit never returns
    mov ax,0013h                ; VGA mode 13h for the game
    int 10h
    call SetPalette

    xor ax,ax                   ; reset mouse driver (cursor hidden)
    int 33h
    mov ax,7                    ; X range 0..639
    xor cx,cx
    mov dx,639
    int 33h
    mov ax,8                    ; Y range 0..199
    xor cx,cx
    mov dx,199
    int 33h

    call NewGame
    call DrawStatic
    call Redraw
    SHOWM

GameLoop:
    call UpdateTimer

    mov ah,01h                  ; key waiting?
    int 16h
    jnz KeyPressed

    mov ax,0003h                ; poll mouse
    int 33h
    and bl,3
    jz .released
    cmp byte [PrevMouse],0
    jne GameLoop                ; still holding: ignore until released
    mov [PrevMouse],bl
    shr cx,1                    ; 0..639 -> 0..319
    mov [MouseX],cx
    mov [MouseY],dx
    call HandleClick
    jmp GameLoop
.released:
    mov byte [PrevMouse],0
    jmp GameLoop

KeyPressed:
    mov ah,00h
    int 16h
    cmp al,27                   ; ESC
    je ExitGame
    or al,20h                   ; to lower case
    cmp al,'m'
    je .mute
    cmp al,'r'
    jne GameLoop
    call DoRestart
    jmp GameLoop
.mute:
    call ToggleMusic
    jmp GameLoop

ExitGame:
    call SpeakerOff
    mov ax,0003h
    int 10h
    jmp start                   ; back to the main menu

DoRestart:
    call NewGame
    call Redraw
    ret
