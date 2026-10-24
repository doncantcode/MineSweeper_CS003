; -------------------------------------------------------------------
; Program start
; -------------------------------------------------------------------
start:
    mov [StackTop],sp           ; restored by ExitGame (see below)
    cld
    ; Check command tail for /t or -t (self-test mode)
    mov cl, [80h]
    or cl, cl
    jz .normalBoot
    mov si, 81h
.chkCmd:
    lodsb
    cmp al, '/'
    je .chkSwitch
    cmp al, '-'
    jne .nextCh
.chkSwitch:
    mov al, [si]
    or al, 20h
    cmp al, 't'
    je .doTest
.nextCh:
    dec cl
    jnz .chkCmd
    jmp .normalBoot

.doTest:
    mov byte [TestMode], 1
    call RunTestSuite
    mov ax, 4C00h
    int 21h

.normalBoot:
MenuEntry:                      ; ExitGame comes back here (stack reset)
    mov ax,0003h                ; 80x25 text: intro + main menu
    int 10h
    call HideCursor
    cmp byte [ProgressLoaded],0
    jne .progressReady
    call LoadProgress
    mov byte [ProgressLoaded],1
.progressReady:
    call MainMenu               ; sets [CurrentMode]; Exit never returns
    call SpeakerOff             ; silence menu music before switching to game
    mov word [MenuNoteLeft], 0
    mov word [MenuMusicPtr], track3
    mov word [NoteLeft], 0
    mov word [MusicPtr], SongTable
    mov byte [SfxOn], 0
    mov byte [MageScans], 0
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
    cmp byte [CurrentMode],1    ; Endless opens on the level select
    jne .drawBoard
    call GoLevelSelect
    jmp .boardShown
.drawBoard:
    call DrawStatic
    call Redraw
.boardShown:
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

    ; --- Level select: arrows / Enter / digits / ESC ---
    cmp byte [EndlessState],4
    jne .chkVictoryKeys
    call LevelSelectKey
    jmp GameLoop

.chkVictoryKeys:

    ; --- Check Endless Menu states ---
    cmp byte [EndlessState],1   ; Victory Menu
    jne .chkShopKeys
    cmp al,27                   ; ESC
    je .toLevels
    cmp al,'3'
    je .toLevels
    cmp al,'l'
    je .toLevels
    cmp al,'L'
    je .toLevels
    cmp al,'1'
    je .vicContinue
    cmp al,'c'
    je .vicContinue
    cmp al,'C'
    je .vicContinue
    cmp al,13                   ; Enter
    je .vicContinue
    cmp al,32                   ; Space
    je .vicContinue
    cmp al,'2'
    je .vicShop
    cmp al,'s'
    je .vicShop
    cmp al,'S'
    je .vicShop
    cmp al,'i'
    je .vicShop
    cmp al,'I'
    je .vicShop
    jmp GameLoop

.vicContinue:
    inc byte [CurrentLevel]
    mov byte [EndlessState],0
    call NewGame
    call DrawStatic
    call Redraw
    jmp GameLoop

.vicShop:
    mov byte [EndlessState],2
    mov byte [ShopMsg],0
    call Redraw
    jmp GameLoop

.toLevels:
    call GoLevelSelect
    jmp GameLoop

.chkShopKeys:
    cmp byte [EndlessState],2   ; Item Shop
    jne .chkGameOverKeys
    cmp al,27
    je .toLevels
    cmp al,'1'
    je .shop1
    cmp al,'o'
    je .shop1
    cmp al,'O'
    je .shop1
    cmp al,'2'
    je .shop2
    cmp al,'l'
    je .shop2
    cmp al,'L'
    je .shop2
    cmp al,'3'
    je .shop3
    cmp al,'d'
    je .shop3
    cmp al,'D'
    je .shop3
    cmp al,'4'
    je .shopNext
    cmp al,13
    je .shopNext
    cmp al,32
    je .shopNext
    cmp al,'c'
    je .shopNext
    cmp al,'C'
    je .shopNext
    jmp GameLoop

.shop1:
    call ShopBuyOracle
    jmp GameLoop
.shop2:
    call ShopBuyRadar
    jmp GameLoop
.shop3:
    call ShopBuyDetector
    jmp GameLoop
.shopNext:
    inc byte [CurrentLevel]
    mov byte [EndlessState],0
    call NewGame
    call DrawStatic
    call Redraw
    jmp GameLoop

.chkGameOverKeys:
    cmp byte [EndlessState],3   ; Game Over: any key -> level select
    je .toLevels

.normalKeys:
    cmp al,27                   ; ESC: Endless -> levels, else main menu
    jne .notEsc
    cmp byte [CurrentMode],1
    je .toLevels
    jmp ExitGame
.notEsc:
    or al,20h                   ; to lower case
    cmp al,'m'
    je .mute
    cmp al,'r'
    jne .chkBomb
    call DoRestart
    jmp GameLoop

.chkBomb:
    cmp al,'b'
    jne .chkScan
    cmp byte [GameOver],0
    jne GameLoop
    cmp byte [BombCount],0
    jne .bombReady
    mov byte [KitMsgN],6
    mov byte [KitMsgT],36
    mov word [EventPtr],EvNoBombs
    call Redraw
    jmp GameLoop
.bombReady:
    xor byte [BombArmed],1
    mov byte [ScanArmed],0
    mov byte [RadarArmed],0
    mov word [EventPtr],EvBombArmed
    cmp byte [BombArmed],0
    jne .bombLogged
    mov word [EventPtr],EvCancel
.bombLogged:
    call Redraw
    jmp GameLoop

.chkScan:
    cmp al,'s'                  ; mage: arm / disarm 3x3 scanner
    jne .chkPotion1
    cmp byte [SelectedClass],2
    jne GameLoop
    cmp byte [GameOver],0
    jne GameLoop
    cmp byte [MinesPlaced],0    ; no mines yet: a scan would find nothing
    jne .scanBoardReady
    mov word [EventPtr],EvScanFirst
    call Redraw
    jmp GameLoop
.scanBoardReady:
    cmp byte [MageScans],0
    jne .scanOk
    mov byte [KitMsgN],3
    mov byte [KitMsgT],36
    mov word [EventPtr],EvNoScan
    call Redraw
    jmp GameLoop
.scanOk:
    mov byte [BombArmed],0
    mov byte [RadarArmed],0
    xor byte [ScanArmed],1
    mov word [EventPtr],EvScanArmed
    cmp byte [ScanArmed],0
    jne .scanLogged
    mov word [EventPtr],EvCancel
.scanLogged:
    call Redraw
    jmp GameLoop

.chkPotion1:
    cmp byte [CurrentMode],1    ; potions are Endless-only items
    jne GameLoop
    cmp al,'1'
    je .useOracle
    cmp al,'o'
    jne .chkPotion2
.useOracle:
    call UsePotionOracle
    jmp GameLoop

.chkPotion2:
    cmp al,'2'
    je .useRadar
    cmp al,'l'
    jne .chkPotion3
.useRadar:
    call UsePotionRadar
    jmp GameLoop

.chkPotion3:
    cmp al,'3'
    je .useDetector
    cmp al,'d'
    jne GameLoop
.useDetector:
    call UsePotionDetector
    jmp GameLoop

.mute:
    call ToggleMusic
    jmp GameLoop

ExitGame:
    call SpeakerOff
    mov word [NoteLeft], 0
    mov word [MusicPtr], SongTable
    mov byte [SfxOn], 0
    mov word [MenuNoteLeft], 0
    mov word [MenuMusicPtr], track3
    mov sp,[StackTop]           ; may be reached from inside a call
    jmp MenuEntry               ; back to main menu

DoRestart:
    call NewGame
    call DrawStatic
    call Redraw
    ret

%include "src/test_suite.inc"
