; -------------------------------------------------------------------
; Screen composition
;
; Text in mode 13h goes through PrintAt (video.asm), which paints each
; cell's background from [TextBg]: 0FFh (the default) repaints the
; sidebar gradient, any other value is a solid colour.  Routines that
; print onto a panel or dialog set [TextBg] first and put 0FFh back
; when they are done.
; -------------------------------------------------------------------
DrawBackground:
    pusha
    xor si,si
    xor bx,bx
.b:
    mov ax,si
    add al,32
    mov [FillCol],al
    xor ax,ax
    mov cx,320
    mov dx,10
    call FillRect
    add bx,10
    inc si
    cmp si,20
    jb .b
    popa
    ret

DrawStatic:
    pusha
    HIDEM                       ; never draw under a visible mouse cursor
    mov byte [TextBg],0FFh
    call DrawBackground

    ; Window drop shadow (kept on screen: stops at row 199)
    mov byte [FillCol],0
    mov ax,[WinX]
    add ax,4
    mov bx,[WinY]
    add bx,4
    mov cx,[WinW]
    mov dx,[WinH]
    sub dx,2
    call FillRect

    ; Window frame
    BEVEL 1,[WinX],[WinY],[WinW],[WinH],7

    ; Header panel
    BEVEL 0,[HeaderX],[HeaderY],[HeaderW],26,7

    ; Board frame
    mov al,[CurCols]
    xor ah,ah
    cmp byte [TileSize],16
    jne .sz8w
    shl ax,4
    jmp .gotW
.sz8w:
    shl ax,3
.gotW:
    mov cx,ax
    add cx,4                    ; width = BoardWidth + 4

    mov al,[CurRows]
    xor ah,ah
    cmp byte [TileSize],16
    jne .sz8h
    shl ax,4
    jmp .gotH
.sz8h:
    shl ax,3
.gotH:
    mov dx,ax
    add dx,4                    ; height = BoardHeight + 4

    mov ax,[StartX]
    dec ax
    dec ax
    mov bx,[StartY]
    dec bx
    dec bx
    call DrawBevel0

    ; Draw classic sidebar if window leaves room
    cmp word [WinX],70
    jb .doneStatic

    ; --- LEFT SIDEBAR: CONTROLS, then the SKILL / LAST USE panel ---
    TXT 1,1,14,'MINE'
    TXT 2,1,14,'SWEEPER'
    TXT 4,1,15,'CONTROLS'
    TXT 5,1,11,'LMB'
    TXT 5,5,7,'open'
    TXT 6,1,11,'RMB'
    TXT 6,5,7,'flag'
    TXT 7,1,11,'R'
    TXT 7,5,7,'reset'
    TXT 8,1,11,'ESC'
    cmp byte [CurrentMode],1
    je .escLevels
    TXT 8,5,7,'menu'
    jmp .escDone
.escLevels:
    TXT 8,5,7,'lvls'
.escDone:
    TXT 9,1,11,'M'
    TXT 9,5,7,'music'
    TXT 10,1,11,'B'
    TXT 10,5,7,'bomb'
    cmp byte [SelectedClass],2
    jne .noScanKey
    TXT 11,1,11,'S'
    TXT 11,5,7,'scan'
.noScanKey:
    cmp byte [CurrentMode],1
    jne .noPotionKeys
    TXT 12,1,11,'1-3'
    TXT 12,5,7,'items'
.noPotionKeys:
    TXT 14,1,15,'SKILL'
    TXT 19,1,15,'LAST USE'

    ; --- RIGHT SIDEBAR: STATUS, BOARD, CLASS ---
    TXT 1,31,15,'STATUS'
    TXT 6,31,15,'BOARD'
    call DrawBoardInfoText
    TXT 10,31,15,'CLASS'
    call DrawClassStaticText

    ; If Endless mode: draw static labels for Shrapnel and Potions
    cmp byte [CurrentMode],1
    jne .doneStatic
    TXT 16,31,15,'SHRAPNEL'
    TXT 19,31,15,'POTIONS'
    TXT 20,31,11,'1 Safe'
    TXT 21,31,11,'2 Line'
    TXT 22,31,11,'3 Det'
    call DrawEndlessStats

.doneStatic:
    SHOWM
    popa
    ret

; DrawBevel0 helper: AX=x, BX=y, CX=w, DX=h (sunken)
DrawBevel0:
    pusha
    mov byte [BevTL],8
    mov byte [BevBR],15
    mov byte [BevFace],7
    call DrawBevel
    popa
    ret

Redraw:
    pusha
    HIDEM
    mov byte [TextBg],0FFh
    cmp byte [EndlessState],1
    jne .chkShop
    call DrawVictoryMenu
    jmp .out
.chkShop:
    cmp byte [EndlessState],2
    jne .chkGameOver
    call DrawItemShop
    jmp .out
.chkGameOver:
    cmp byte [EndlessState],3
    jne .chkLevelSel
    call DrawGameOverScreen
    jmp .out
.chkLevelSel:
    cmp byte [EndlessState],4
    jne .normalDraw
    call DrawLevelBody
    jmp .out
.normalDraw:
    call RenderBoard
    call DrawHeader
    cmp word [WinX],70
    jb .skipSidebars
    call DrawStatus
    call DrawKit
    call DrawSkillPanel
    cmp byte [CurrentMode],1
    jne .chkWin
    call DrawEndlessStats
.chkWin:
    cmp byte [GameOver],2
    jne .out
    cmp byte [CurrentMode],1    ; Endless shows its own victory menu
    je .out
    call DrawRewardPopup
    jmp .out
.skipSidebars:
    call DrawCompactHud         ; wide boards: status lives in the header
.out:
    mov byte [TextBg],0FFh
    SHOWM
    popa
    ret

DrawTimer:
    pusha
    HIDEM
    mov ax,[Seconds]
    mov di,[HeaderX]
    add di,104
    call DrawLed
    SHOWM
    popa
    ret

RenderBoard:
    pusha
    xor si,si
    xor ch,ch                  ; row
.row:
    xor cl,cl                  ; col
.col:
    mov al,cl
    xor ah,ah
    cmp byte [TileSize],16
    jne .sz8x
    shl ax,4
    jmp .gotTileX
.sz8x:
    shl ax,3
.gotTileX:
    add ax,[StartX]
    mov [OrgX],ax

    mov al,ch
    xor ah,ah
    cmp byte [TileSize],16
    jne .sz8y
    shl ax,4
    jmp .gotTileY
.sz8y:
    shl ax,3
.gotTileY:
    add ax,[StartY]
    mov [OrgY],ax

    mov al,[Board+si]
    call DrawCell
    inc si
    inc cl
    cmp cl,[CurCols]
    jb .col
    inc ch
    cmp ch,[CurRows]
    jb .row
    popa
    ret

; AL = cell byte, SI = cell index, tile origin in [OrgX],[OrgY]
DrawCell:
    pusha
    mov [CellVal],al
    test al,2
    jnz .opened

    ; Unopened tile
    cmp byte [TileSize],16
    jne .unopen8
    BEVEL 1,[OrgX],[OrgY],16,16,7
    test byte [CellVal],4
    jz .cellOut
    mov si,FlagRects
    call DrawRects
    jmp .cellOut
.unopen8:
    BEVEL 1,[OrgX],[OrgY],8,8,7
    test byte [CellVal],4
    jz .cellOut
    mov si,FlagRects8
    call DrawRects
    jmp .cellOut

.opened:
    mov al,7
    cmp si,[HitCell]
    jne .col
    mov al,12                   ; stepped-on mine
.col:
    mov [CellCol],al
    cmp byte [TileSize],16
    jne .open8

    ; 16x16 opened tile
    mov byte [FillCol],8
    mov ax,[OrgX]
    mov bx,[OrgY]
    mov cx,16
    mov dx,16
    call FillRect
    mov al,[CellCol]
    mov [FillCol],al
    mov ax,[OrgX]
    inc ax
    mov bx,[OrgY]
    inc bx
    mov cx,15
    mov dx,15
    call FillRect

    mov al,[CellVal]
    test al,1
    jz .num16
    mov si,MineRects
    call DrawRects
    jmp .cellOut
.num16:
    shr al,4
    jz .cellOut
    mov bl,al
    xor bh,bh
    mov dl,[NumColors+bx-1]
    mov [GlC],dl
    mov byte [GlS],2
    mov dx,[OrgX]
    add dx,5
    mov [GlX],dx
    mov dx,[OrgY]
    add dx,3
    mov [GlY],dx
    call DrawGlyph
    jmp .cellOut

.open8:
    ; 8x8 opened tile
    mov byte [FillCol],8
    mov ax,[OrgX]
    mov bx,[OrgY]
    mov cx,8
    mov dx,8
    call FillRect
    mov al,[CellCol]
    mov [FillCol],al
    mov ax,[OrgX]
    inc ax
    mov bx,[OrgY]
    inc bx
    mov cx,7
    mov dx,7
    call FillRect

    mov al,[CellVal]
    test al,1
    jz .num8
    mov si,MineRects8
    call DrawRects
    jmp .cellOut
.num8:
    shr al,4
    jz .cellOut
    mov bl,al
    xor bh,bh
    mov dl,[NumColors+bx-1]
    mov [GlC],dl
    mov byte [GlS],1
    mov dx,[OrgX]
    add dx,3
    mov [GlX],dx
    mov dx,[OrgY]
    add dx,1
    mov [GlY],dx
    call DrawGlyph

.cellOut:
    popa
    ret

DrawHeader:
    pusha
    xor cx,cx                   ; count flags
    xor si,si
.cnt:
    test byte [Board+si],4
    jz .nx
    inc cx
.nx:
    inc si
    cmp si,[CurCells]
    jb .cnt

    mov ax,[CurMines]
    sub ax,cx                   ; mines left
    mov di,[HeaderX]
    add di,5
    call DrawLed
    mov ax,[Seconds]
    mov di,[HeaderX]
    add di,104
    call DrawLed
    call DrawFace
    popa
    ret

; LED counter: AX = signed value, DI = box x
DrawLed:
    pusha
    mov [LedVal],ax
    mov [LedX],di
    mov bx,[HeaderY]
    inc bx
    inc bx
    BEVEL 0,di,bx,39,21,0

    mov byte [GlS],3
    mov byte [GlC],12
    mov bx,[HeaderY]
    add bx,5
    mov [GlY],bx
    mov bx,[LedX]
    add bx,3
    mov [GlX],bx
    mov ax,[LedVal]
    or ax,ax
    jns .pos
    neg ax
    cmp ax,99
    jbe .negok
    mov ax,99
.negok:
    mov [LedVal],ax
    mov byte [FillCol],12       ; minus sign
    mov ax,[GlX]
    mov bx,[HeaderY]
    add bx,11
    mov cx,9
    mov dx,3
    call FillRect
    add word [GlX],12
    mov ax,[LedVal]
    jmp .two
.pos:
    cmp ax,999
    jbe .three
    mov ax,999
.three:
    xor dx,dx
    mov bx,100
    div bx
    push dx
    call DrawGlyph
    add word [GlX],12
    pop ax
.two:
    mov bl,10
    div bl                      ; AL tens, AH ones
    push ax
    call DrawGlyph
    add word [GlX],12
    pop ax
    mov al,ah
    call DrawGlyph
    popa
    ret

DrawFace:
    pusha
    mov bx,[HeaderY]
    inc bx
    inc bx
    BEVEL 1,149,bx,22,22,7
    mov word [OrgX],152
    mov bx,[HeaderY]
    add bx,5
    mov [OrgY],bx
    mov si,FaceDisc
    call DrawRects
    mov al,[GameOver]
    mov si,FaceHappy
    cmp al,1
    jne .n1
    mov si,FaceDead
.n1:
    cmp al,2
    jne .go
    mov si,FaceCool
.go:
    call DrawRects
    popa
    ret

; Vanilla / Rapid win banner over the board, showing what was earned
DrawRewardPopup:
    pusha
    BEVEL 1,86,73,148,54,1
    mov byte [TextBg],1
    mov dh,10
    mov bl,14
    mov si,StrRewardTitle
    call PrintCentered

    mov di,RewardBuf            ; "+<n> SHRAPNELS"
    mov byte [di],'+'
    inc di
    mov ax,[EarnedShrapnel]
    call StrCatWord
    mov si,StrRewardSuffix
    call StrCatStr
    mov dh,12
    mov bl,15
    mov si,RewardBuf
    call PrintCentered

    mov dh,14
    mov bl,11
    mov si,StrRewardHint
    call PrintCentered
    mov byte [TextBg],0FFh
    popa
    ret

; GetStatusMsg: SI -> current status text, BL = its colour
GetStatusMsg:
    mov si,StrPlay
    mov bl,10
    cmp byte [BombArmed],0
    je .chkRadar
    mov si,StrBombReady
    mov bl,14
    ret
.chkRadar:
    cmp byte [RadarArmed],0
    je .scanArmed
    mov si,StrRadarArmed
    mov bl,14
    ret
.scanArmed:
    cmp byte [ScanArmed],0
    je .kitmsg
    mov si,StrArmed
    mov bl,14
    ret
.kitmsg:
    cmp byte [KitMsgT],0
    je .gamest
    mov al,[KitMsgN]
    dec al
    cmp al,10
    jae .gamest
    xor ah,ah
    push di
    mov di,ax
    shl di,1
    mov si,[KitMsgTab+di]
    mov bl,[KitMsgCol+di]
    pop di
    ret
.gamest:
    mov al,[GameOver]
    cmp al,1
    jne .n1
    mov si,StrLost
    mov bl,12
    ret
.n1:
    cmp al,2
    jne .done
    mov si,StrWin
    mov bl,14
.done:
    ret

; Transient kit / potion messages, KitMsgN = 1..10
KitMsgTab   dw StrShield, StrScanned, StrNoScan, StrBombGet, StrBombUsed
            dw StrNoBombs, StrOracleFound, StrRowSwept, StrMineFlagged
            dw StrNoPotions
KitMsgCol   dw 11, 11, 12, 11, 14, 12, 10, 10, 10, 12

DrawStatus:
    pusha
    BEVEL 0,242,20,76,16,0      ; 8 characters at cols 31..38
    call GetStatusMsg
    mov byte [TextBg],0
    mov dh,3
    mov dl,31
    call PrintAt
    mov byte [TextBg],0FFh
    popa
    ret

; GetKitText: SI -> class line (0 = none), BL = colour,
;             DI -> second (hint) line or 0
GetKitText:
    xor si,si
    xor di,di
    cmp byte [SelectedClass],1
    je .tank
    cmp byte [SelectedClass],2
    je .mage
    cmp byte [SelectedClass],3
    jne .done
    mov bl,11
    mov si,StrArtItems
    ret
.tank:
    mov bl,11
    mov si,StrShldOn
    cmp byte [TankShield],0
    jne .done
    mov bl,8
    mov si,StrShldOff
    ret
.mage:
    mov di,StrScanHint
    mov bl,11
    mov si,StrScanOn
    cmp byte [MageScans],0
    jne .done
    mov bl,8
    mov si,StrScanOff
.done:
    ret

; UpdateBombStr: write the bomb count digit into StrBombs
UpdateBombStr:
    push ax
    mov al,[BombCount]
    cmp al,9
    jbe .ok
    mov al,9
.ok:
    add al,'0'
    mov [StrBombs+7],al
    pop ax
    ret

DrawKit:
    pusha
    call GetKitText
    or si,si
    jz .hint
    mov dh,12
    mov dl,31
    call PrintAt
.hint:
    or di,di
    jz .bombs
    mov bl,7
    mov si,di
    mov dh,13
    mov dl,31
    call PrintAt
.bombs:
    call UpdateBombStr
    mov bl,14
    mov si,StrBombs
    mov dh,14
    mov dl,31
    call PrintAt
    popa
    ret

; DrawCompactHud: wide Endless boards leave no room for the sidebars,
; so the essentials go on the window face either side of the header:
;   left  (cols 1..9) : status / level / class kit
;   right (cols 30..38): bombs / shrapnel / potions (safe/line/det)
DrawCompactHud:
    pusha
    mov byte [TextBg],7
    mov cl,9                    ; clear both flanks
    mov dh,1
.clr:
    mov dl,1
    call PrintSpaces
    mov dl,30
    call PrintSpaces
    inc dh
    cmp dh,3
    jbe .clr

    call GetStatusMsg           ; row 1 left: status
    call DarkColour
    mov dh,1
    mov dl,1
    call PrintAt

    mov dh,2                    ; row 2 left: level
    mov dl,1
    mov bl,1
    mov si,StrHudLvl
    call PrintAt
    mov al,[CurrentLevel]
    xor ah,ah
    mov dl,5
    call PrintWordAt

    call GetKitText             ; row 3 left: class kit
    or si,si
    jz .right
    call DarkColour
    mov dh,3
    mov dl,1
    call PrintAt

.right:
    call UpdateBombStr          ; row 1 right: bombs
    mov dh,1
    mov dl,30
    mov bl,1
    mov si,StrBombs
    call PrintAt

    mov dh,2                    ; row 2 right: shrapnel balance
    mov si,StrHudShr
    call PrintAt
    mov ax,[Shrapnels]
    mov dl,34
    call PrintWordAt

    mov di,RewardBuf            ; row 3 right: "P<safe>/<line>/<det>"
    mov byte [di],'P'
    inc di
    mov al,[PotionOracle]
    xor ah,ah
    call StrCatWord
    mov byte [di],'/'
    inc di
    mov al,[PotionRadar]
    call StrCatWord
    mov byte [di],'/'
    inc di
    mov al,[PotionDetector]
    call StrCatWord
    mov dh,3
    mov dl,30
    mov bl,1
    mov si,RewardBuf
    call PrintAt

    mov byte [TextBg],0FFh
    popa
    ret

; DarkColour: map a bright HUD colour in BL to a readable one on the
; light-grey window face (bright -> dark variant, greys -> black)
DarkColour:
    and bl,7
    cmp bl,7
    jne .ok
    xor bl,bl
.ok:
    ret

; DrawBoardInfoText: displays BOARD description on rows 7..9 of right sidebar
DrawBoardInfoText:
    pusha
    cmp byte [CurrentMode],1
    je .endlessBoard

    TXT 7,31,7,'9x9 grid'
    TXT 8,31,7,'10 mines'
    popa
    ret

.endlessBoard:
    ; Row 7: LVL <CurrentLevel> (the real level, even past 10)
    TXT 7,31,14,'LVL '
    mov al,[CurrentLevel]
    xor ah,ah
    mov dh,7
    mov dl,35
    mov bl,14
    call PrintWordAt

    ; Rows 8-9 describe the board actually in play (levels 11+ reuse 10)
    mov al,[CurrentLevel]
    or al,al
    jnz .lvlNz
    mov al,1
.lvlNz:
    cmp al,10
    jbe .lvlOk
    mov al,10
.lvlOk:
    xor ah,ah
    dec al                      ; 0..9
    shl ax,1
    mov si,ax
    push si
    mov si,[LvlGridTab+si]
    mov dh,8
    mov dl,31
    mov bl,7
    call PrintAt

    ; Row 9: Mines from LvlMinesTab
    pop si
    mov si,[LvlMinesTab+si]
    mov dh,9
    mov dl,31
    mov bl,7
    call PrintAt
    popa
    ret

; DrawClassStaticText: displays class name at row 11, col 31
DrawClassStaticText:
    pusha
    cmp byte [SelectedClass],1
    jne .clsMage
    mov si,StrClsTank
    jmp .clsDraw
.clsMage:
    cmp byte [SelectedClass],2
    jne .clsArtificer
    mov si,StrClsMage
    jmp .clsDraw
.clsArtificer:
    cmp byte [SelectedClass],3
    jne .clsNone
    mov si,StrClsArtificer
    jmp .clsDraw
.clsNone:
    mov si,StrClsNone
.clsDraw:
    mov dh,11
    mov dl,31
    mov bl,14
    call PrintAt
    popa
    ret

; DrawEndlessStats: updates dynamic Shrapnel balance and potion counts on right sidebar
DrawEndlessStats:
    pusha
    mov byte [TextBg],0FFh
    ; Row 17: Shrapnels count (up to 5 digits)
    mov dh,17
    mov dl,31
    mov cl,8
    call PrintSpaces
    mov ax,[Shrapnels]
    mov bl,14
    call PrintWordAt

    ; Rows 20-22: potion counts, 2-digit field at cols 38..39
    mov dh,20
    mov si,PotionOracle
.pot:
    mov dl,38
    mov cl,2
    call PrintSpaces
    mov al,[si]
    xor ah,ah
    call PrintWordAt
    inc si
    inc dh
    cmp dh,22
    jbe .pot
    popa
    ret

; DrawVictoryMenu: modal screen for Level Victory in Endless Mode
; Dialog: x 40..279, y 18..181 -> text columns 6..33, rows 4..21
DrawVictoryMenu:
    pusha
    ; Drop shadow
    mov byte [FillCol],0
    mov ax,44
    mov bx,22
    mov cx,240
    mov dx,164
    call FillRect

    ; Blue dialog box
    BEVEL 1,40,18,240,164,1
    mov byte [TextBg],1

    mov dh,4
    mov bl,14                   ; bright yellow title
    mov si,StrVicTitle
    call PrintCentered

    ; Level info
    mov dh,6
    mov dl,6
    mov bl,15
    mov si,StrVicLvlPrefix
    call PrintAt
    mov al,[CurrentLevel]
    xor ah,ah
    mov dl,12
    mov bl,14
    call PrintWordAt

    ; Level name
    mov al,[CurrentLevel]
    or al,al
    jnz .vNameNz
    mov al,1
.vNameNz:
    cmp al,10
    jbe .vNameLe10
    mov al,10
.vNameLe10:
    dec al
    mov bl,6
    mul bl
    mov si,ax
    mov si,[LevelTable+si+4]
    mov dh,6
    mov dl,16
    mov bl,11
    call PrintAt

    ; Base Reward
    mov dh,8
    mov dl,6
    mov bl,7
    mov si,StrVicBase
    call PrintAt
    mov ax,[BaseShrapnel]
    mov dl,20
    mov bl,15
    call PrintWordAt

    ; Artificer passive?
    cmp byte [SelectedClass],3
    jne .earnedLine
    mov dh,9
    mov dl,6
    mov bl,14                   ; yellow
    mov si,StrVicArtBonus
    call PrintAt

.earnedLine:
    mov dh,10
    mov dl,6
    mov bl,10                   ; green
    mov si,StrVicEarned
    call PrintAt
    mov ax,[EarnedShrapnel]
    mov dl,21
    mov bl,14
    call PrintWordAt

    ; Total Shrapnel Balance
    mov dh,11
    mov dl,6
    mov bl,15
    mov si,StrVicBalance
    call PrintAt
    mov ax,[Shrapnels]
    mov dl,15
    mov bl,14
    call PrintWordAt

    ; Newly unlocked level
    mov al,[JustUnlocked]
    or al,al
    jz .options
    mov si,StrVicAllBeaten
    cmp al,MAX_LEVEL
    ja .unlockMsg
    mov di,RewardBuf            ; "LEVEL n UNLOCKED!"
    push ax
    mov si,StrVicLvlPrefix
    call StrCatStr
    pop ax
    xor ah,ah
    call StrCatWord
    mov si,StrVicUnlocked
    call StrCatStr
    mov si,RewardBuf
.unlockMsg:
    mov dh,13
    mov bl,10
    call PrintCentered

.options:
    ; Options (rows 15 / 17 / 19 are the mouse targets in HandleClick)
    mov dh,15
    mov dl,6
    mov bl,10                   ; green
    mov si,StrVicOptA
    call PrintAt

    mov dh,17
    mov bl,14                   ; yellow
    mov si,StrVicOptB
    call PrintAt

    mov dh,19
    mov bl,15
    mov si,StrVicOptC
    call PrintAt

    mov dh,21
    mov bl,11                   ; cyan
    mov si,StrVicPrompt
    call PrintCentered
    mov byte [TextBg],0FFh
    popa
    ret

; DrawItemShop: modal screen for purchasing potions
; Dialog: x 8..311, y 8..187 -> text columns 2..37, rows 2..21
DrawItemShop:
    pusha
    ; Drop shadow
    mov byte [FillCol],0
    mov ax,12
    mov bx,12
    mov cx,304
    mov dx,180
    call FillRect

    ; Blue dialog box
    BEVEL 1,8,8,304,180,1
    mov byte [TextBg],1

    mov dh,2
    mov bl,14                   ; yellow
    mov si,StrShopTitle
    call PrintCentered

    ; Shrapnel balance
    mov dh,4
    mov dl,3
    mov bl,15
    mov si,StrShopBal
    call PrintAt
    mov ax,[Shrapnels]
    mov dl,14
    mov bl,14
    call PrintWordAt

    ; Items: name row, then description row (rows 6/9/12 are the
    ; mouse targets in HandleClick)
    mov dh,6
    mov si,StrShopItm1
    mov di,StrShopDesc1
    mov al,[PotionOracle]
    call DrawShopItem
    mov dh,9
    mov si,StrShopItm2
    mov di,StrShopDesc2
    mov al,[PotionRadar]
    call DrawShopItem
    mov dh,12
    mov si,StrShopItm3
    mov di,StrShopDesc3
    mov al,[PotionDetector]
    call DrawShopItem

    ; Option 4: Next Level
    mov dh,15
    mov dl,3
    mov bl,10                   ; green
    mov si,StrShopNext
    call PrintAt

    ; Message line (ShopMsg): 1 = no funds, 2..4 = bought, 5 = at max
    mov al,[ShopMsg]
    or al,al
    jz .shopPrompt
    cmp al,5
    ja .shopPrompt
    dec al
    xor ah,ah
    mov si,ax
    shl si,1
    mov bl,[ShopMsgCol+si]
    mov si,[ShopMsgTab+si]
    mov dh,18
    call PrintCentered

.shopPrompt:
    mov dh,21
    mov bl,11                   ; cyan
    mov si,StrShopPrompt
    call PrintCentered
    mov byte [TextBg],0FFh
    popa
    ret

ShopMsgTab  dw StrShopNeed, StrShopBuy1, StrShopBuy2, StrShopBuy3, StrShopMax
ShopMsgCol  dw 12, 10, 10, 10, 12

; DrawShopItem: DH = row, SI = name, DI = description, AL = quantity
DrawShopItem:
    pusha
    mov dl,3
    mov bl,11
    call PrintAt
    mov dl,28
    mov si,StrShopQty
    call PrintAt
    xor ah,ah
    mov dl,33
    mov bl,14
    call PrintWordAt
    inc dh
    mov dl,5
    mov bl,7
    mov si,di
    call PrintAt
    popa
    ret

; DrawGameOverScreen: modal screen when hitting a mine in Endless Mode
; Dialog: x 36..283, y 34..159 -> text columns 5..34
DrawGameOverScreen:
    pusha
    ; Drop shadow
    mov byte [FillCol],0
    mov ax,40
    mov bx,38
    mov cx,248
    mov dx,126
    call FillRect

    ; Red dialog box
    BEVEL 1,36,34,248,126,4
    mov byte [TextBg],4

    mov dh,6
    mov bl,14                   ; yellow
    mov si,StrGoTitle
    call PrintCentered

    mov dh,8
    mov bl,12                   ; red
    mov si,StrGoMine
    call PrintCentered

    mov dh,10
    mov bl,15
    mov si,StrGoEndless
    call PrintCentered

    mov dh,12
    mov dl,9
    mov bl,7
    mov si,StrGoLvl
    call PrintAt
    mov al,[CurrentLevel]
    xor ah,ah
    mov dl,28
    mov bl,14
    call PrintWordAt

    mov dh,14
    mov dl,9
    mov bl,7
    mov si,StrVicBalance
    call PrintAt
    mov ax,[Shrapnels]
    mov dl,18
    mov bl,14
    call PrintWordAt

    mov dh,17
    mov bl,11                   ; cyan
    mov si,StrGoPrompt
    call PrintCentered
    mov byte [TextBg],0FFh
    popa
    ret

; PrintCentered: DH = row, BL = colour, SI = string; centred on 40 cols
PrintCentered:
    pusha
    xor cx,cx
    push si
.len:
    lodsb
    or al,al
    jz .gotLen
    inc cx
    jmp .len
.gotLen:
    pop si
    mov dl,40
    sub dl,cl
    jnc .fits
    xor dl,dl
.fits:
    shr dl,1
    call PrintAt
    popa
    ret

; StrCatWord: AX = value written as decimal at DI; DI -> new terminator
StrCatWord:
    push ax
    call WordToStr
.end:
    cmp byte [di],0
    je .done
    inc di
    jmp .end
.done:
    pop ax
    ret

; StrCatStr: copy 0-terminated SI to DI; DI -> new terminator
StrCatStr:
    push ax
    push si
.cp:
    lodsb
    mov [di],al
    or al,al
    jz .done
    inc di
    jmp .cp
.done:
    pop si
    pop ax
    ret

; -------------------------------------------------------------------
; Skill / last-use panel (left sidebar, rows 15-17 and 20-23)
; -------------------------------------------------------------------
DrawSkillPanel:
    pusha
    call GetSkillDesc
    mov dh,15
    mov dl,1
    mov cl,3
    mov bl,11
    mov bh,11
    call PrintBlock

    mov bl,14                   ; event: headline yellow, details grey
    mov si,[EventPtr]
    or si,si
    jnz .haveEvent
    mov si,EvDefault
    mov bl,7
.haveEvent:
    mov dh,20
    mov dl,1
    mov cl,4
    mov bh,7
    call PrintBlock
    popa
    ret

; GetSkillDesc: SI -> description of the class skill in its current state
GetSkillDesc:
    mov si,SkNone
    mov al,[SelectedClass]
    cmp al,1
    jne .mage
    mov si,SkTankOn
    cmp byte [TankShield],0
    jne .done
    mov si,SkTankOff
    ret
.mage:
    cmp al,2
    jne .art
    mov si,SkMageUsed
    cmp byte [MageScans],0
    je .done
    mov si,SkMageRdy
    cmp byte [ScanArmed],0
    je .done
    mov si,SkMageArm
    ret
.art:
    cmp al,3
    jne .done
    mov si,SkArt
.done:
    ret

; PrintBlock: SI = text with '|' line breaks ('#' -> [EventNum]),
; DH/DL = first row / column, CL = lines in the field (all cleared to
; 9 columns), BL = colour of the first line, BH = colour of the rest
PrintBlock:
    pusha
    mov ch,cl
.line:
    mov di,LineBuf
.copy:
    mov al,[si]
    or al,al
    jz .endLine
    inc si
    cmp al,'|'
    je .endLine
    cmp al,'#'
    jne .store
    mov ax,[EventNum]
    call StrCatWord
    jmp .copy
.store:
    mov [di],al
    inc di
    jmp .copy
.endLine:
    mov byte [di],0
    push cx
    mov cl,9
    call PrintSpaces
    pop cx
    push si
    mov si,LineBuf
    call PrintAt
    pop si
    mov bl,bh
    inc dh
    dec ch
    jnz .line
    popa
    ret

; -------------------------------------------------------------------
; Endless level select screen (EndlessState 4)
;   Panel x 10..309, y 6..193; boxes 44x40 at x = 34 + col*52,
;   y = 56 + row*48 (must match LevelSelectClick)
; -------------------------------------------------------------------
DrawLevelFrame:
    pusha
    mov byte [TextBg],0FFh
    call DrawBackground
    mov byte [FillCol],0        ; drop shadow
    mov ax,14
    mov bx,10
    mov cx,300
    mov dx,188
    call FillRect
    BEVEL 1,10,6,300,188,1
    mov byte [TextBg],1
    mov dh,2
    mov bl,14
    mov si,StrLsTitle
    call PrintCentered
    mov dh,4
    mov bl,15
    mov si,StrLsSub
    call PrintCentered
    mov dh,23
    mov bl,11
    mov si,StrLsHint
    call PrintCentered
    mov byte [TextBg],0FFh
    popa
    ret

; DrawLevelBody: the 10 boxes plus the info lines for the selection
DrawLevelBody:
    pusha
    xor cl,cl
.box:
    mov al,cl
    call DrawLevelBox
    inc cl
    cmp cl,MAX_LEVEL
    jb .box

    mov byte [TextBg],1
    mov dh,19                   ; clear the three info rows
.clr:
    mov dl,2
    mov cl,36
    call PrintSpaces
    inc dh
    cmp dh,21
    jbe .clr

    ; Row 19: "LEVEL n - <name>" or "LEVEL n - LOCKED"
    mov di,RewardBuf
    mov si,StrVicLvlPrefix
    call StrCatStr
    mov al,[LevelSel]
    inc al
    xor ah,ah
    call StrCatWord
    mov si,StrLsDash
    call StrCatStr
    mov al,[LevelSel]
    inc al
    cmp al,[UnlockedLevel]
    ja .lockedInfo

    mov al,[LevelSel]           ; unlocked: name + board size
    mov bl,6
    mul bl
    mov bx,ax
    mov si,[LevelTable+bx+4]
    call StrCatStr
    mov dh,19
    mov si,RewardBuf
    push bx
    mov bl,14
    call PrintCentered
    pop bx

    mov di,RewardBuf            ; Row 20: "CxR GRID   M MINES"
    mov al,[LevelTable+bx]
    xor ah,ah
    call StrCatWord
    mov byte [di],'x'
    inc di
    mov al,[LevelTable+bx+1]
    call StrCatWord
    mov si,StrLsGrid
    call StrCatStr
    mov ax,[LevelTable+bx+2]
    call StrCatWord
    mov si,StrLsMines
    call StrCatStr
    jmp .detail

.lockedInfo:
    mov si,StrLsLocked
    call StrCatStr
    mov dh,19
    mov bl,12
    mov si,RewardBuf
    call PrintCentered
    mov di,RewardBuf            ; Row 20: "BEAT LEVEL n TO UNLOCK"
    mov si,StrLsBeat
    call StrCatStr
    mov al,[LevelSel]
    xor ah,ah
    call StrCatWord
    mov si,StrLsToUnlock
    call StrCatStr
.detail:
    mov dh,20
    mov bl,7
    mov si,RewardBuf
    call PrintCentered

    ; Row 21: "still locked" notice, otherwise unlock progress
    cmp byte [KitMsgT],0
    je .progress
    cmp byte [KitMsgN],11
    jne .progress
    mov dh,21
    mov bl,12
    mov si,StrLsStillLock
    call PrintCentered
    jmp .done
.progress:
    mov di,RewardBuf            ; "UNLOCKED: n / 10"
    mov si,StrLsProgress
    call StrCatStr
    mov al,[UnlockedLevel]
    cmp al,MAX_LEVEL
    jbe .cntOk
    mov al,MAX_LEVEL
.cntOk:
    xor ah,ah
    call StrCatWord
    mov si,StrLsOf10
    call StrCatStr
    mov dh,21
    mov bl,11
    mov si,RewardBuf
    call PrintCentered
.done:
    mov byte [TextBg],0FFh
    popa
    ret

; DrawLevelBox: AL = box index 0..9
;   unlocked & beaten: raised grey, green number + tick
;   unlocked (next to play): raised grey, blue number + play arrow
;   locked: dark, grey number + padlock (the "grayed-out" state)
;   selected: yellow ring around the box
DrawLevelBox:
    pusha
    mov [LsIdx],al
    xor ah,ah
    mov dl,5
    div dl                      ; AL = row, AH = column
    push ax
    mov al,ah
    mov dl,52
    mul dl
    add ax,34
    mov [OrgX],ax
    pop ax
    xor ah,ah
    mov dl,48
    mul dl
    add ax,56
    mov [OrgY],ax

    mov byte [FillCol],1        ; selection ring (panel colour = none)
    mov al,[LsIdx]
    cmp al,[LevelSel]
    jne .ring
    mov byte [FillCol],14
.ring:
    mov ax,[OrgX]
    sub ax,3
    mov bx,[OrgY]
    sub bx,3
    mov cx,50
    mov dx,46
    call FillRect

    mov al,[LsIdx]
    inc al
    cmp al,[UnlockedLevel]
    ja .locked
    mov byte [BevTL],15
    mov byte [BevBR],8
    mov byte [BevFace],7
    mov byte [GlC],1
    mov si,IconPlay
    je .draw                    ; = UnlockedLevel: the next one to beat
    mov byte [GlC],2
    mov si,IconCheck
    jmp .draw
.locked:
    mov byte [BevTL],7
    mov byte [BevBR],0
    mov byte [BevFace],8
    mov byte [GlC],7
    mov si,IconLock
.draw:
    push si
    mov ax,[OrgX]
    mov bx,[OrgY]
    mov cx,44
    mov dx,40
    call DrawBevel

    mov byte [GlS],3            ; level number, centred
    mov ax,[OrgY]
    add ax,6
    mov [GlY],ax
    mov al,[LsIdx]
    inc al
    cmp al,10
    jb .oneDigit
    mov ax,[OrgX]
    add ax,11
    mov [GlX],ax
    mov al,1
    call DrawGlyph
    add word [GlX],12
    xor al,al
    call DrawGlyph
    jmp .icon
.oneDigit:
    mov bx,[OrgX]
    add bx,17
    mov [GlX],bx
    call DrawGlyph
.icon:
    pop si
    call DrawRects
    popa
    ret
