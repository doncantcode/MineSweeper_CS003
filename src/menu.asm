; -------------------------------------------------------------------
; Text-mode front end (80x25): startup intro, main menu and the
; gamemode submenu.  Keyboard driven through int 21h ah=07h (silent
; read), so no Enter presses are needed.  Replaces the mode pick
; previously done by the graphics menu; [CurrentMode] values are
; unchanged (0 vanilla, 1 endless, 2 rapid).
; -------------------------------------------------------------------

; --- text helpers ---------------------------------------------------

; ClearScr: fresh 80x25 screen, cursor home
ClearScr:
    pusha
    mov ax,0003h
    int 10h
    popa
    ret

; WaitKey: AL = keypress, no echo
WaitKey:
    mov ah,07h
    int 21h
    ret

; PrintStr: DS:SI -> $-terminated string via DOS
PrintStr:
    pusha
    mov dx,si
    mov ah,09h
    int 21h
    popa
    ret

; PrintAttr: DS:SI -> 0-terminated string, BL = colour attribute
PrintAttr:
    pusha
.ch:
    lodsb
    or al,al
    jz .done
    mov ah,09h                    ; write char + attribute at cursor
    mov bh,0
    mov cx,1
    int 10h
    push ax
    mov ah,03h                    ; read cursor, then step one column
    mov bh,0
    int 10h
    inc dl
    cmp dl,80
    jb .set
    xor dl,dl
    inc dh
.set:
    mov ah,02h
    int 10h
    pop ax
    jmp .ch
.done:
    popa
    ret

; Crlf: teletype a line feed + carriage return
Crlf:
    pusha
    mov ah,0Eh
    mov al,10
    int 10h
    mov al,13
    int 10h
    popa
    ret

; Delay350: ~0.35 s pause (int 15h wait, CX:DX usec)
Delay350:
    pusha
    mov cx,5
    mov dx,5730h
    mov ah,86h
    int 15h
    popa
    ret

; --- intro ----------------------------------------------------------

ShowIntro:
    pusha
    mov bl,0Eh                    ; banner in bright yellow
    mov si,art_title1
    call PrintAttr
    call Crlf
    mov si,art_title2
    call PrintAttr
    call Crlf
    mov si,art_title3
    call PrintAttr
    call Crlf
    mov si,art_title4
    call PrintAttr
    call Crlf
    call Crlf
    mov bl,0Bh                    ; tactical status in cyan
    mov si,msg_scan
    call PrintAttr
    call Crlf
    call Delay350
    mov bl,0Ah                    ; mine report in green
    mov si,msg_mines
    call PrintAttr
    call Crlf
    call Delay350
    mov bl,07h
    mov si,msg_anykey
    call PrintAttr
    call WaitKey
    mov byte [IntroShown],1
    popa
    ret

; --- main menu ------------------------------------------------------

MainMenu:
    cmp byte [IntroShown],0       ; intro only on first boot
    jne .loop
    call ShowIntro
.loop:
    call ClearScr
    mov bl,0Eh
    mov si,txt_menuTitle
    call PrintAttr
    call Crlf
    call Crlf
    mov bl,0Fh
    mov si,opt_play
    call PrintAttr
    call Crlf
    mov si,opt_credits
    call PrintAttr
    call Crlf
    mov si,opt_exit
    call PrintAttr
    call Crlf
    call Crlf
    mov bl,07h
    mov si,msg_pick
    call PrintAttr
    call WaitKey
    cmp al,'1'
    je .play
    cmp al,'2'
    je .credits
    cmp al,'3'
    je .exit
    jmp .loop                     ; anything else: redraw
.play:
    call ModeMenu                 ; AL=0 -> Back, no mode picked
    or al,al
    jz .loop
    ret                           ; [CurrentMode] set: boot the game
.credits:
    call ClearScr
    call show_credits
    jmp .loop
.exit:
    call ExitToDos

; --- gamemode submenu -----------------------------------------------

; ModeMenu: returns AL=1 with [CurrentMode] set, or AL=0 for Back
ModeMenu:
.loop:
    call ClearScr
    mov bl,0Eh
    mov si,txt_modeTitle
    call PrintAttr
    call Crlf
    call Crlf
    mov bl,0Fh
    mov si,opt_vanilla
    call PrintAttr
    call Crlf
    mov si,opt_endless
    call PrintAttr
    call Crlf
    mov si,opt_rapid
    call PrintAttr
    call Crlf
    mov si,opt_back
    call PrintAttr
    call Crlf
    call Crlf
    mov bl,07h
    mov si,msg_pick
    call PrintAttr
    call WaitKey
    cmp al,'1'
    je .vanilla
    cmp al,'2'
    je .endless
    cmp al,'3'
    je .rapid
    cmp al,'4'
    je .back
    jmp .loop
.vanilla:
    mov byte [CurrentMode],0
    jmp .picked
.endless:
    mov byte [CurrentMode],1
    jmp .picked
.rapid:
    mov byte [CurrentMode],2
.picked:
    mov al,1
    ret
.back:
    xor al,al
    ret

; --- exit -----------------------------------------------------------

ExitToDos:
    call ClearScr
    mov bl,0Ah
    mov si,msg_exit1
    call PrintAttr
    call Crlf
    mov bl,07h
    mov si,msg_exit2
    call PrintAttr
    call Crlf
    mov ax,4C00h                  ; back to DOS
    int 21h

; --- strings --------------------------------------------------------

art_title1: db ' __  __   __   _  _    ___    ___  __  __   ___    ___    ___   ___    ___',0
art_title2: db '|  \/  | | |  | \| |  | __|  / __| \ \ / / | __|  | __|  | _ \ | __|  | _ \',0
art_title3: db '| |\/| | | |  | |\ |  | __ \ \__ \  \ V /  | __ \ | __ \ |  _/ | __ \ |   /',0
art_title4: db '|_|  |_| |_|  |_| |_| |___/  |___/   \_/   |___/  |___/  |_|   |___/  |_|_\',0

msg_scan:   db 'SCANNING GRID FIELD...',0
msg_mines:  db '10 MINES LOCATED!',0
msg_anykey: db 'PRESS ANY KEY TO CONTINUE',0

txt_menuTitle: db 'MINESWEEPER - MAIN MENU',0
opt_play:      db ' [1] PLAY',0
opt_credits:   db ' [2] CREDITS',0
opt_exit:      db ' [3] EXIT TO DOS',0

txt_modeTitle: db 'SELECT GAMEMODE',0
opt_vanilla:   db ' [1] VANILLA - CLASSIC SWEEP, TIMER COUNTS UP',0
opt_endless:   db ' [2] ENDLESS - RELAXED SWEEP, NO TIME LIMIT',0
opt_rapid:     db ' [3] RAPID - 60 SECOND COUNTDOWN!',0
opt_back:      db ' [4] BACK TO MAIN MENU',0

msg_pick:   db 'SELECT AN OPTION...',0
msg_exit1:  db 'MINEFIELD SECURED. THANK YOU FOR SWEEPING.',0
msg_exit2:  db 'GRID TERMINATED - RETURNING TO DOS...',0
