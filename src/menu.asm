; -------------------------------------------------------------------
; Text-mode front end (80x25): startup intro, main menu, gamemode and
; class submenus.  Blue chrome with black stage bands and cyan
; pinstripes, boxed centred layout, silent input via int 21h ah=07h
; (no Enter needed).  [CurrentMode] values are unchanged
; (0 vanilla, 1 endless, 2 rapid).
; -------------------------------------------------------------------

; --- text helpers ---------------------------------------------------

; ClearScr: fresh 80x25, cleared to blue/white chrome
ClearScr:
    pusha
    mov ax,0003h
    int 10h
    mov ax,0600h                ; scroll whole window = clear with attr
    mov bh,1Fh                  ; blue background, white text
    mov cx,0000h
    mov dx,184Fh
    int 10h
    mov ah,02h                  ; cursor home
    mov bh,0
    xor dx,dx
    int 10h
    popa
    ret

; Band: fill rows CH..DH with attribute BH (colour stage behind content)
Band:
    pusha
    mov ax,0600h
    mov cl,0
    mov dl,79
    int 10h
    popa
    ret

; WaitKey: AL = keypress, no echo
WaitKey:
    mov ah,07h
    int 21h
    ret

; PrintStr: DS:SI -> $-terminated string via DOS (legacy helper)
PrintStr:
    pusha
    mov dx,si
    mov ah,09h
    int 21h
    popa
    ret

; PrintAttr: write 0-terminated string at the cursor, BL = colour attr
PrintAttr:
    pusha
.ch:
    lodsb
    or al,al
    jz .done
    mov ah,09h                  ; write char + attribute at cursor
    mov bh,0
    mov cx,1
    int 10h
    push ax
    mov ah,03h                  ; read cursor, then step one column
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

; PrintA: PrintAttr with explicit placement.  DH=row DL=col BL=attr
PrintA:
    pusha
    mov ah,02h
    mov bh,0
    int 10h
    call PrintAttr
    popa
    ret

; StrLen: SI -> 0-terminated string, CX = length
StrLen:
    push si
    xor cx,cx
.l:
    cmp byte [si],0
    je .done
    inc si
    inc cx
    jmp .l
.done:
    pop si
    ret

; PrintCRow: centred on row DH, BL = attr, SI -> 0-terminated string
PrintCRow:
    pusha
    call StrLen
    mov ax,80
    sub ax,cx
    shr ax,1
    mov dl,al
    mov ah,02h
    mov bh,0
    int 10h
    call PrintAttr
    popa
    ret

; TypeStr: centred typewriter line on row DH (for the intro status)
TypeStr:
    pusha
    call StrLen
    mov ax,80
    sub ax,cx
    shr ax,1
    mov dl,al
    mov ah,02h
    mov bh,0
    int 10h
.ch:
    lodsb
    or al,al
    jz .done
    mov ah,09h
    mov bh,0
    mov cx,1
    int 10h
    push ax
    mov ah,03h                  ; advance the cursor one column
    mov bh,0
    int 10h
    inc dl
    mov ah,02h
    int 10h
    pop ax
    push cx
    mov cx,0                    ; ~40 ms per character
    mov dx,9C40h
    mov ah,86h
    int 15h
    pop cx
    jmp .ch
.done:
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

; DrawBar: reverse-video status bar along the bottom row
DrawBar:
    pusha
    mov bl,70h
    mov si,bar_fill
    mov dh,24
    xor dl,dl
    call PrintA
    mov si,bar_left
    xor dl,dl
    call PrintA
    mov si,bar_ver
    mov dl,75
    call PrintA
    popa
    ret

; --- intro ----------------------------------------------------------

ShowIntro:
    pusha
    call ClearScr

    ; backdrop: cyan pinstripes around a black stage
    mov ch,2
    mov dh,2
    mov bh,30h
    call Band
    mov ch,3
    mov dh,15
    mov bh,00h
    call Band
    mov ch,16
    mov dh,16
    mov bh,30h
    call Band

    ; frame on the stage
    mov bl,0Fh
    mov si,box_top
    mov dh,3
    mov dl,1
    call PrintA
    mov si,box_bot
    mov dh,15
    mov dl,1
    call PrintA
    mov si,box_side
    mov ch,4
.sides:
    mov dh,ch
    mov dl,1
    call PrintA
    mov dl,78
    call PrintA
    inc ch
    cmp ch,15
    jb .sides

    ; upper wire, MINE, lower wire, SWEEPER
    mov bl,07h
    mov si,wire_l
    mov dh,5
    mov dl,34
    call PrintA
    mov bl,0Ch
    mov si,wire_m
    mov dl,39
    call PrintA
    mov bl,07h
    mov si,wire_r
    mov dl,40
    call PrintA

    mov bl,0Eh
    mov si,art_mine1
    mov dh,6
    mov dl,28
    call PrintA
    inc dh
    mov si,art_mine2
    call PrintA
    inc dh
    mov si,art_mine3
    call PrintA
    inc dh
    mov si,art_mine4
    call PrintA

    mov bl,07h
    mov si,wire_l
    mov dh,10
    mov dl,34
    call PrintA
    mov bl,0Ch
    mov si,wire_m
    mov dl,39
    call PrintA
    mov bl,07h
    mov si,wire_r
    mov dl,40
    call PrintA

    mov bl,0Bh
    mov si,art_swp1
    mov dh,11
    mov dl,20
    call PrintA
    inc dh
    mov si,art_swp2
    call PrintA
    inc dh
    mov si,art_swp3
    call PrintA
    inc dh
    mov si,art_swp4
    call PrintA

    mov dh,17                   ; sub-title
    mov bl,1Bh
    mov si,msg_dosEd
    call PrintCRow

    mov dh,19                   ; tactical status, typed out
    mov bl,1Bh
    mov si,msg_scan
    call TypeStr
    call Delay350

    mov dh,20
    mov bl,1Ah
    mov si,msg_mines
    call PrintCRow
    call Delay350

    mov dh,22
    mov bl,1Fh
    mov si,msg_anykey
    call PrintCRow

    call DrawBar
    call WaitKey
    mov byte [IntroShown],1
    popa
    ret

; --- main menu ------------------------------------------------------

MainMenu:
    cmp byte [IntroShown],0     ; intro only on first boot
    jne .loop
    call ShowIntro
.loop:
    call ClearScr
    mov dh,2                    ; masthead
    mov bl,1Eh
    mov si,msg_mTitle
    call PrintCRow
    mov dh,3
    mov bl,1Bh
    mov si,msg_dosEd
    call PrintCRow

    mov ch,5                    ; stage for the option box
    mov dh,14
    mov bh,00h
    call Band
    mov ch,15
    mov dh,15
    mov bh,30h
    call Band

    mov bl,0Fh
    mov si,box_topS
    mov dh,7
    mov dl,27
    call PrintA
    mov si,box_botS
    mov dh,13
    mov dl,27
    call PrintA
    mov si,box_side
    mov ch,8
.sides:
    mov dh,ch
    mov dl,27
    call PrintA
    mov dl,54
    call PrintA
    inc ch
    cmp ch,13
    jb .sides

    mov bl,1Eh                  ; [1]
    mov si,key1
    mov dh,9
    mov dl,31
    call PrintA
    mov bl,0Fh
    mov si,opt_play
    mov dl,34
    call PrintA

    mov bl,1Eh                  ; [2]
    mov si,key2
    mov dh,10
    mov dl,31
    call PrintA
    mov bl,0Fh
    mov si,opt_credits
    mov dl,34
    call PrintA

    mov bl,1Eh                  ; [3]
    mov si,key3
    mov dh,11
    mov dl,31
    call PrintA
    mov bl,0Fh
    mov si,opt_exit
    mov dl,34
    call PrintA

    mov dh,17                   ; prompt
    mov bl,17h
    mov si,msg_pick
    call PrintCRow

    call DrawBar
    call WaitKey
    cmp al,'1'
    je .play
    cmp al,'2'
    je .credits
    cmp al,'3'
    je .exit
    jmp .loop                   ; anything else: redraw
.play:
    call ModeMenu               ; AL=0 -> Back, no mode picked
    or al,al
    jz .loop
    call ClassMenu              ; AL=0 -> Back, no class picked
    or al,al
    jz .loop
    ret                         ; mode + class set: boot the game
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
    mov dh,3
    mov bl,1Eh
    mov si,txt_modeTitle
    call PrintCRow

    mov ch,5
    mov dh,11
    mov bh,00h
    call Band
    mov ch,12
    mov dh,12
    mov bh,30h
    call Band

    mov bl,0Fh
    mov si,opt_vanilla
    mov dh,7
    mov dl,16
    call PrintA
    mov si,opt_endless
    mov dh,8
    call PrintA
    mov si,opt_rapid
    mov dh,9
    call PrintA
    mov si,opt_back
    mov dh,10
    call PrintA

    mov dh,14
    mov bl,17h
    mov si,msg_pick
    call PrintCRow

    call DrawBar
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

; --- class submenu --------------------------------------------------

; ClassMenu: returns AL=1 with [SelectedClass] set, or AL=0 for Back.
; [3] Artificer is locked: shows a message and forces re-selection.
ClassMenu:
.loop:
    call ClearScr
    mov dh,3
    mov bl,1Eh
    mov si,txt_classTitle
    call PrintCRow

    mov ch,5
    mov dh,11
    mov bh,00h
    call Band
    mov ch,12
    mov dh,12
    mov bh,30h
    call Band

    mov bl,0Fh
    mov si,opt_tank
    mov dh,7
    mov dl,16
    call PrintA
    mov si,opt_mage
    mov dh,8
    call PrintA
    mov bl,17h                  ; grey: locked entry
    mov si,opt_artificer
    mov dh,9
    call PrintA
    mov bl,0Fh
    mov si,opt_classBack
    mov dh,10
    call PrintA

    mov dh,14
    mov bl,17h
    mov si,msg_pick
    call PrintCRow

    call DrawBar
    call WaitKey
    cmp al,'1'
    je .tank
    cmp al,'2'
    je .mage
    cmp al,'3'
    je .locked
    cmp al,'4'
    je .back
    jmp .loop
.tank:
    mov byte [SelectedClass],1
    jmp .picked
.mage:
    mov byte [SelectedClass],2
    mov byte [MageScans],1      ; one scan per full session
.picked:
    mov al,1
    ret
.locked:
    mov dh,14
    mov bl,1Ch
    mov si,msg_classLocked
    call PrintCRow
    call Delay350
    call Delay350
    call Delay350
    call Delay350               ; give the message a moment to read
    jmp .loop
.back:
    xor al,al
    ret

; --- exit -----------------------------------------------------------

ExitToDos:
    call ClearScr
    mov ch,11
    mov dh,13
    mov bh,00h
    call Band
    mov dh,12
    mov bl,1Ah
    mov si,msg_exit1
    call PrintCRow
    mov dh,13
    mov bl,17h
    mov si,msg_exit2
    call PrintCRow
    mov ax,4C00h                ; back to DOS
    int 21h

; --- strings --------------------------------------------------------

art_mine1: db ' __  __  __  _  _   ___',0
art_mine2: db '|  \/  || | | \| | | __|',0
art_mine3: db '| |\/| || | | |\ | | __ \',0
art_mine4: db '|_|  |_||_| |_| |_||___/',0

art_swp1: db ' ___ __  __  ___   ___   ___  ___   ___',0
art_swp2: db '/ __|\ \ / /| __| | __| | _ \| __| | _ \',0
art_swp3: db '\__ \ \ V / | __ \| __ \|  _/| __ \|   /',0
art_swp4: db '|___/  \_/  |___/ |___/ |_|  |___/ |_|_\',0

wire_l:     db '=====',0
wire_m:     db '@',0
wire_r:     db '=====',0

box_top:    db 0C9h, 76 dup(0CDh), 0BBh, 0
box_bot:    db 0C8h, 76 dup(0CDh), 0BCh, 0
box_topS:   db 0C9h, 26 dup(0CDh), 0BBh, 0
box_botS:   db 0C8h, 26 dup(0CDh), 0BCh, 0
box_side:   db 0BAh, 0

bar_fill:   times 80 db ' '
            db 0
bar_left:   db ' MINESWEEPER - DOS EDITION',0
bar_ver:    db 'V1.0 ',0

msg_dosEd:  db 'D O S   E D I T I O N',0
msg_mTitle: db 'M I N E S W E E P E R',0
msg_scan:   db 'SCANNING GRID FIELD...',0
msg_mines:  db '10 MINES LOCATED!',0
msg_anykey: db 'PRESS ANY KEY TO CONTINUE',0

txt_modeTitle: db 'SELECT GAMEMODE',0
opt_vanilla:   db ' [1] VANILLA - CLASSIC SWEEP, TIMER COUNTS UP',0
opt_endless:   db ' [2] ENDLESS - RELAXED SWEEP, NO TIME LIMIT',0
opt_rapid:     db ' [3] RAPID - 60 SECOND COUNTDOWN!',0
opt_back:      db ' [4] BACK TO MAIN MENU',0

txt_classTitle: db 'SELECT CLASS',0
opt_tank:       db ' [1] TANK - ABSORBS ONE BLAST PER LEVEL',0
opt_mage:       db ' [2] MAGE - PRESS S THEN CLICK: SCAN A 3X3 AREA',0
opt_artificer:  db ' [3] ARTIFICER (UNAVAILABLE)',0
opt_classBack:  db ' [4] BACK',0
msg_classLocked: db 'Class currently unavailable!',0

key1:       db '[1]',0
key2:       db '[2]',0
key3:       db '[3]',0
opt_play:   db ' PLAY',0
opt_credits: db ' CREDITS',0
opt_exit:   db ' EXIT TO DOS',0

msg_pick:   db 'SELECT AN OPTION...',0
msg_exit1:  db 'MINEFIELD SECURED. THANK YOU FOR SWEEPING.',0
msg_exit2:  db 'GRID TERMINATED - RETURNING TO DOS...',0
