; -------------------------------------------------------------------
; Program start
; -------------------------------------------------------------------
start:
    cld
    mov ax,0003h                ; 80x25 text: intro + main menu
    int 10h
    cmp byte [ProgressLoaded],0
    jne .progressReady
    call LoadProgress
    mov byte [ProgressLoaded],1
.progressReady:
    call MainMenu               ; sets [CurrentMode]; Exit never returns
    cmp byte [SelectedClass],2  ; grant the mage's session scan for this run
    jne .noMageScan
    mov byte [MageScans],1
.noMageScan:
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
    jne .chkBomb
    call DoRestart
    jmp GameLoop
.chkBomb:
    cmp al,'b'                  ; arm a collected bomb for the next tile click
    jne .chkScan
    cmp byte [GameOver],0
    jne GameLoop
    cmp byte [BombCount],0
    jne .bombReady
    mov byte [KitMsgN],6
    mov byte [KitMsgT],36
    call Redraw
    jmp GameLoop
.bombReady:
    xor byte [BombArmed],1
    mov byte [ScanArmed],0
    call Redraw
    jmp GameLoop
.chkScan:
    cmp al,'s'                  ; mage: arm / disarm the 3x3 scanner
    jne GameLoop
    cmp byte [SelectedClass],2
    jne GameLoop
    cmp byte [MageScans],0
    jne .scanOk
    mov byte [KitMsgN],3        ; no charges: say so briefly
    mov byte [KitMsgT],36
    call Redraw
    jmp GameLoop
.scanOk:
    mov byte [BombArmed],0
    xor byte [ScanArmed],1
    call Redraw                 ; status flips to ARMED! / SCAN RDY
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
