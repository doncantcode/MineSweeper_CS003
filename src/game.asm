; -------------------------------------------------------------------
; Game state
; -------------------------------------------------------------------

; SetupCurrentLevel: configures CurCols, CurRows, CurMines, CurCells,
; TileSize, StartX, StartY, Header and Window coordinates.
SetupCurrentLevel:
    pusha
    cmp byte [CurrentMode], 1   ; Endless mode?
    jne .notEndless

    ; Clamp CurrentLevel between 1 and 10 for table lookup
    mov al, [CurrentLevel]
    or al, al
    jnz .lvlNotZero
    mov al, 1
    mov [CurrentLevel], al
.lvlNotZero:
    cmp al, 10
    jbe .lvlWithin10
    mov al, 10
.lvlWithin10:
    dec al                      ; 0..9
    mov bl, 6                   ; 6 bytes per entry in LevelTable
    mul bl
    mov si, ax
    add si, LevelTable

    mov al, [si]
    mov [CurCols], al
    mov al, [si+1]
    mov [CurRows], al
    mov ax, [si+2]
    mov [CurMines], ax

    ; CurCells = CurCols * CurRows
    mov al, [CurCols]
    mov dl, [CurRows]
    mul dl                      ; AX = CurCols * CurRows
    mov [CurCells], ax

    ; TileSize: 16 for levels with cols <= 9 and rows <= 9, 8 otherwise
    cmp byte [CurCols], 9
    ja .useTile8
    cmp byte [CurRows], 9
    ja .useTile8

    mov byte [TileSize], 16
    ; BoardWidth = CurCols * 16
    mov al, [CurCols]
    xor ah, ah
    shl ax, 4
    mov bx, 320
    sub bx, ax
    shr bx, 1
    mov [StartX], bx
    mov word [StartY], 45
    mov word [HeaderY], 8
    jmp .commonLayout

.useTile8:
    mov byte [TileSize], 8
    ; BoardWidth = CurCols * 8
    mov al, [CurCols]
    xor ah, ah
    shl ax, 3
    mov bx, 320
    sub bx, ax
    shr bx, 1
    mov [StartX], bx
    mov word [StartY], 34
    mov word [HeaderY], 5
    jmp .commonLayout

.notEndless:
    mov byte [CurCols], 9
    mov byte [CurRows], 9
    mov word [CurMines], 10
    mov word [CurCells], 81
    mov byte [TileSize], 16
    mov word [StartX], 88
    mov word [StartY], 45
    mov word [HeaderY], 8

.commonLayout:
    mov word [HeaderX], 86
    mov word [HeaderW], 148

    ; WinX = StartX - 6, clamped <= 81 so the sidebars (x < 81 and
    ; x >= 240) stay clear.  Boards too wide for the sidebars get a
    ; full-width window instead (WinX < 70 -> compact HUD in the header
    ; row); 4 keeps the window's drop shadow on screen.
    mov ax, [StartX]
    sub ax, 6
    cmp ax, 81
    jbe .winXOk
    mov ax, 81
.winXOk:
    cmp ax, 70
    jae .winXNotTooSmall
    mov ax, 4
.winXNotTooSmall:
    mov [WinX], ax
    ; WinW = 320 - WinX*2
    mov bx, ax
    shl bx, 1
    mov cx, 320
    sub cx, bx
    mov [WinW], cx
    mov word [WinY], 2
    mov word [WinH], 196
    popa
    ret

NewGame:
    pusha
    call SetupCurrentLevel

    push ds
    pop es
    cld
    mov di, Board
    mov cx, MAX_CELLS
    xor al, al
    rep stosb

    mov byte [BombCount], 0
    mov byte [BombArmed], 0
    mov byte [RadarArmed], 0
    mov byte [KitMsgT], 0
    mov byte [KitMsgN], 0
    mov byte [MinesPlaced], 0
    mov byte [GameOver], 0
    mov byte [Started], 0
    mov byte [TimerOn], 0
    mov byte [EndlessState], 0
    mov byte [JustUnlocked], 0
    mov word [EventPtr], 0      ; fresh board: empty skill log
    mov word [HitCell], 0FFFFh

    mov ah, 00h
    int 1Ah
    xor [RndSeed], dx

    ; Set timer depending on game mode
    cmp byte [CurrentMode], 2    ; 2 = Rapid
    jne .normalTimer
    mov word [Seconds], 60       ; Rapid countdown
    jmp .timerSet

.normalTimer:
    mov word [Seconds], 0        ; Vanilla / Endless count upward

.timerSet:
    mov word [TickAcc], 0

    ; Character kit: fresh tank shield every level, scanner disarmed.
    mov byte [ScanArmed], 0
    cmp byte [SelectedClass], 1  ; Tank
    jne .noTankKit
    mov byte [TankShield], 1
    jmp .kitDone
.noTankKit:
    mov byte [TankShield], 0
.kitDone:
    popa
    ret

GetRandom:
    push dx
    mov ax, [RndSeed]
    mov dx, 25173
    mul dx
    add ax, 13849
    mov [RndSeed], ax
    pop dx
    ret

; PlaceMinesLazy: places mines avoiding the 3x3 surrounding (FirstRow, FirstCol)
; This guarantees the clicked tile has 0 adjacent mines -> triggers cascade opening!
PlaceMinesLazy:
    pusha
    xor bx, bx                  ; mines placed counter
.placeLoop:
    call GetRandom
    xor dx, dx
    mov cx, [CurCells]
    div cx                      ; DX = cell index (0 .. CurCells - 1)
    mov si, dx
    test byte [Board+si], 1     ; already a mine?
    jnz .placeLoop

    ; Check if (r, c) is within the 3x3 around (FirstRow, FirstCol)
    mov ax, si
    div byte [CurCols]          ; AL = row, AH = col
    mov cl, al
    sub cl, [FirstRow]
    jns .rowPos
    neg cl
.rowPos:
    cmp cl, 1
    ja .cellAllowed             ; row distance > 1 -> allowed!
    mov cl, ah
    sub cl, [FirstCol]
    jns .colPos
    neg cl
.colPos:
    cmp cl, 1
    jbe .placeLoop              ; inside 3x3 -> forbidden!

.cellAllowed:
    or byte [Board+si], 1       ; place mine
    inc bx
    cmp bx, [CurMines]
    jb .placeLoop

    call PlaceItems
    call ComputeNumbers
    mov byte [MinesPlaced], 1
    popa
    ret

; Every board has two item tiles and a random chance for a third.
PlaceItems:
    pusha
    mov byte [ItemTilesLeft], 2
    call GetRandom
    mov al, [RndSeed+1]
    cmp byte [SelectedClass], 3
    je .artificerChance
    test al, 1
    jz .place
    jmp .addThird
.artificerChance:
    and al, 3
    jz .place
.addThird:
    inc byte [ItemTilesLeft]
.place:
    call GetRandom
    xor dx, dx
    mov cx, [CurCells]
    div cx
    mov si, dx
    test byte [Board+si], 1+ITEM_BIT
    jnz .place
    or byte [Board+si], ITEM_BIT
    dec byte [ItemTilesLeft]
    jnz .place
    popa
    ret

; CountCells: AL = bit mask -> AX = cells having any of those bits
; (used to report how much a skill / potion opened or flagged)
CountCells:
    push bx
    push si
    mov bl, al
    xor ax, ax
    xor si, si
.l:
    test [Board+si], bl
    jz .n
    inc ax
.n:
    inc si
    cmp si, [CurCells]
    jb .l
    pop si
    pop bx
    ret

; BH=row BL=col -> SI = index   (AX, BX preserved)
CellIndex:
    push dx
    push ax
    mov al, bh
    xor ah, ah
    mov dl, [CurCols]
    xor dh, dh
    mul dx                      ; DX:AX = row * CurCols
    mov dl, bl
    xor dh, dh
    add ax, dx                  ; AX = row * CurCols + col
    mov si, ax
    pop ax
    pop dx
    ret

; Fill high nibble of every safe cell with its neighbour-mine count
ComputeNumbers:
    pusha
    xor si, si
    xor ch, ch                  ; row
.r:
    xor cl, cl                  ; col
.c:
    and byte [Board+si], 0Fh
    test byte [Board+si], 1
    jnz .n
    call CountMines
    shl al, 4
    or [Board+si], al
.n:
    inc si
    inc cl
    cmp cl, [CurCols]
    jb .c
    inc ch
    cmp ch, [CurRows]
    jb .r
    popa
    ret

; CH=row CL=col -> AL = mines around
CountMines:
    push bx
    push dx
    push si
    xor dl, dl
    mov bh, ch
    dec bh
.lr:
    cmp bh, 0
    jl .nr
    cmp bh, [CurRows]
    jge .nr
    mov bl, cl
    dec bl
.lc:
    cmp bl, 0
    jl .nc
    cmp bl, [CurCols]
    jge .nc
    call CellIndex
    test byte [Board+si], 1
    jz .nc
    inc dl
.nc:
    inc bl
    mov al, cl
    inc al
    cmp bl, al
    jle .lc
.nr:
    inc bh
    mov al, ch
    inc al
    cmp bh, al
    jle .lr
    mov al, dl
    pop si
    pop dx
    pop bx
    ret

; Flood fill. BH=row BL=col
RevealCell:
    pusha
    call CellIndex
    test byte [Board+si], 6      ; opened or flagged
    jnz .done
    or byte [Board+si], 2
    call CollectItem
    mov al, [Board+si]
    and al, 0F0h
    jnz .done                   ; has neighbour mines -> stop
    mov dh, bh
    dec dh
.rr:
    cmp dh, 0
    jl .rn
    cmp dh, [CurRows]
    jge .rn
    mov dl, bl
    dec dl
.cc:
    cmp dl, 0
    jl .cn
    cmp dl, [CurCols]
    jge .cn
    push bx
    mov bh, dh
    mov bl, dl
    call RevealCell
    pop bx
.cn:
    inc dl
    mov al, bl
    inc al
    cmp dl, al
    jle .cc
.rn:
    inc dh
    mov al, bh
    inc al
    cmp dh, al
    jle .rr
.done:
    popa
    ret

; SI = opened cell. Bit 3 marks an uncollected bomb pickup.
CollectItem:
    pusha
    test byte [Board+si], ITEM_BIT
    jz .done
    and byte [Board+si], 0F7h
    cmp byte [BombCount], 0FFh
    je .done
    inc byte [BombCount]
    mov byte [KitMsgN], 4
    mov byte [KitMsgT], 36
    mov word [EventPtr], EvBombGet
.done:
    popa
    ret

; Reveal only safe cells in the 3x3 centred on DH:DL; never flood-fill.
BombArea:
    pusha
    mov al, dh
    xor ah, ah
    mov bp, ax
    mov al, dl
    xor ah, ah
    mov di, ax
    mov si, -1
.dyloop:
    mov dx, -1
.dxloop:
    mov ax, bp
    add ax, si
    mov bx, di
    add bx, dx
    cmp ax, 0
    jl .next
    mov cx, ax
    cmp cl, [CurRows]
    jge .next
    cmp bx, 0
    jl .next
    mov cx, bx
    cmp cl, [CurCols]
    jge .next

    push dx
    push ax
    mov dl, [CurCols]
    mul dl
    add ax, bx
    mov bx, ax
    pop ax
    pop dx

    test byte [Board+bx], 1
    jnz .next
    and byte [Board+bx], 0FBh
    or byte [Board+bx], 2
    push si
    mov si, bx
    call CollectItem
    pop si
.next:
    inc dx
    cmp dx, 1
    jle .dxloop
    inc si
    cmp si, 1
    jle .dyloop
    popa
    ret

RevealMines:                    ; show all un-flagged mines
    pusha
    xor si, si
.l:
    mov al, [Board+si]
    test al, 1
    jz .n
    test al, 4
    jnz .n
    or byte [Board+si], 2
.n:
    inc si
    cmp si, [CurCells]
    jb .l
    popa
    ret

CheckWin:
    pusha
    cmp byte [GameOver], 0
    jne .out
    xor si, si
.l:
    mov al, [Board+si]
    test al, 1                  ; mine?
    jnz .n                      ; mines are skipped
    test al, 2                  ; safe cell opened?
    jz .out                     ; still unopened safe cell -> not won
.n:
    inc si
    cmp si, [CurCells]
    jb .l

    ; Board Cleared!
    mov byte [GameOver], 2
    mov byte [TimerOn], 0

    ; Base Shrapnel calculation:
    ; Cleared_Tiles = CurCells - CurMines
    ; Base_Shrapnel = Cleared_Tiles + (CurMines * 2) = CurCells + CurMines
    mov ax, [CurCells]
    add ax, [CurMines]
    mov [BaseShrapnel], ax

    ; Hero Class: Artificer
    ; Passive Skill: Doubles all Shrapnel earned
    ; Earned_Shrapnel = Base_Shrapnel * (Is_Artificer ? 2 : 1)
    cmp byte [SelectedClass], 3 ; Artificer?
    jne .notArtificer
    shl ax, 1                   ; 2x Shrapnel multiplier!
.notArtificer:
    mov [EarnedShrapnel], ax

    ; Add to permanent Shrapnels balance (capped at 0FFFFh)
    mov bx, [Shrapnels]
    add bx, ax
    jnc .storeShrapnel
    mov bx, 0FFFFh
.storeShrapnel:
    mov [Shrapnels], bx

    ; Artificer: log the doubled payout in the skill panel
    cmp byte [SelectedClass], 3
    jne .noArtLog
    mov [EventNum], ax
    mov word [EventPtr], EvArtBonus
.noArtLog:

    ; Endless: beating level N unlocks level N+1 (MAX_LEVEL+1 = all beaten)
    mov byte [JustUnlocked], 0
    cmp byte [CurrentMode], 1
    jne .noUnlock
    mov al, [CurrentLevel]
    cmp al, MAX_LEVEL
    ja .noUnlock
    inc al
    cmp al, [UnlockedLevel]
    jbe .noUnlock
    mov [UnlockedLevel], al
    mov [JustUnlocked], al
.noUnlock:
    call SaveProgress

    ; Flag every mine on the board
    xor si, si
.f:
    test byte [Board+si], 1
    jz .fn
    or byte [Board+si], 4
.fn:
    inc si
    cmp si, [CurCells]
    jb .f

    mov si, SfxWin
    call StartSfx

    ; In Endless Mode, open the Level Victory Menu!
    cmp byte [CurrentMode], 1   ; Endless Mode?
    jne .out
    mov byte [EndlessState], 1  ; 1 = Level Victory Menu

.out:
    popa
    ret

ScanArea:
    pusha
    mov al, dh
    xor ah, ah
    mov bp, ax
    mov al, dl
    xor ah, ah
    mov di, ax
    mov si, -1
.dyloop:
    mov dx, -1
.dxloop:
    mov ax, bp
    add ax, si
    mov bx, di
    add bx, dx
    cmp ax, 0
    jl .next
    mov cx, ax
    cmp cl, [CurRows]
    jge .next
    cmp bx, 0
    jl .next
    mov cx, bx
    cmp cl, [CurCols]
    jge .next

    push dx
    push ax
    mov dl, [CurCols]
    mul dl
    add ax, bx
    mov bx, ax
    pop ax
    pop dx

    test byte [Board+bx], 1
    jz .next
    or byte [Board+bx], 4
.next:
    inc dx
    cmp dx, 1
    jle .dxloop
    inc si
    cmp si, 1
    jle .dyloop
    popa
    ret

; -------------------------------------------------------------------
; Potion 1: Oracle's Sight (Cost: 10 Shrapnel)
; Instantly highlights/reveals one guaranteed safe tile on current board.
; Logic: Scans board array sequentially for TILE_COVERED_SAFE (0x00).
; -------------------------------------------------------------------
UsePotionOracle:
    pusha
    cmp byte [GameOver], 0
    jne .done
    cmp byte [PotionOracle], 0
    jne .haveOracle
    mov byte [KitMsgN], 10      ; "NO POTIONS!"
    mov byte [KitMsgT], 36
    mov word [EventPtr], EvNoPotion
    call Redraw
    jmp .done
.haveOracle:
    cmp byte [MinesPlaced], 0
    jne .minesOk
    mov al, [CurRows]
    shr al, 1
    mov [FirstRow], al
    mov al, [CurCols]
    shr al, 1
    mov [FirstCol], al
    call PlaceMinesLazy
    mov byte [Started], 1
    mov byte [TimerOn], 1
.minesOk:
    ; Scan sequentially for 0x00 (covered, safe, 0 neighbor mines)
    xor si, si
.scan0:
    cmp byte [Board+si], 0
    je .found
    inc si
    cmp si, [CurCells]
    jb .scan0

    ; Fallback: any covered safe cell: (Board[si] & 7) == 0
    xor si, si
.scanSafe:
    test byte [Board+si], 7
    jz .found
    inc si
    cmp si, [CurCells]
    jb .scanSafe
    jmp .done

.found:
    dec byte [PotionOracle]
    mov al, 2
    call CountCells
    push ax                     ; opened before
    mov ax, si
    div byte [CurCols]          ; AL = row, AH = col
    mov bh, al
    mov bl, ah
    call RevealCell
    mov al, 2
    call CountCells
    pop bx
    sub ax, bx
    mov [EventNum], ax          ; tiles the oracle opened
    mov word [EventPtr], EvOracle
    mov byte [KitMsgN], 7       ; "SAFE TILE!"
    mov byte [KitMsgT], 36
    call CheckWin
    call Redraw
.done:
    popa
    ret

; -------------------------------------------------------------------
; Potion 2: Line Radar / Row Sweep (Cost: 10 Shrapnel)
; Arms the row sweep. Next click on a row executes ApplyRowSweep.
; -------------------------------------------------------------------
UsePotionRadar:
    pusha
    cmp byte [GameOver], 0
    jne .done
    cmp byte [PotionRadar], 0
    jne .haveRadar
    mov byte [KitMsgN], 10      ; "NO POTIONS!"
    mov byte [KitMsgT], 36
    mov word [EventPtr], EvNoPotion
    call Redraw
    jmp .done
.haveRadar:
    xor byte [RadarArmed], 1
    mov byte [BombArmed], 0
    mov byte [ScanArmed], 0
    mov word [EventPtr], EvRadarArm
    cmp byte [RadarArmed], 0
    jne .armLogged
    mov word [EventPtr], EvCancel
.armLogged:
    call Redraw
.done:
    popa
    ret

; ApplyRowSweep: Target a horizontal row (DH = row)
; Logic: Iterates through row * width to (row + 1) * width - 1.
; If cell is mine, set to TILE_FLAGGED; otherwise set to TILE_REVEALED.
ApplyRowSweep:
    pusha
    mov byte [RadarArmed], 0
    cmp byte [PotionRadar], 0
    je .done
    dec byte [PotionRadar]

    cmp byte [MinesPlaced], 0
    jne .minesOk
    mov [FirstRow], dh
    mov byte [FirstCol], 0
    call PlaceMinesLazy
    mov byte [Started], 1
    mov byte [TimerOn], 1
.minesOk:
    mov al, 4
    call CountCells
    mov [EventNum], ax          ; flags before the sweep
    mov al, dh
    mov dl, [CurCols]
    mul dl                      ; AX = row * width
    mov si, ax
    mov cx, ax
    add cl, [CurCols]
    adc ch, 0                   ; CX = (row + 1) * width

.sweepLp:
    cmp si, cx
    jae .sweepDone
    test byte [Board+si], 1     ; mine?
    jz .safeCell
    ; Mine -> set to TILE_FLAGGED
    and byte [Board+si], 0FDh
    or byte [Board+si], 4
    jmp .nextCell
.safeCell:
    ; Non-mine -> set to TILE_REVEALED
    and byte [Board+si], 0FBh
    mov ax, si
    div byte [CurCols]          ; AL = row, AH = col
    mov bh, al
    mov bl, ah
    call RevealCell
.nextCell:
    inc si
    jmp .sweepLp

.sweepDone:
    mov al, 4
    call CountCells
    sub ax, [EventNum]
    jnc .flagCountOk            ; (unflagged safe cells could make it < 0)
    xor ax, ax
.flagCountOk:
    mov [EventNum], ax          ; mines the sweep flagged
    mov word [EventPtr], EvRadar
    mov byte [KitMsgN], 8       ; "ROW SWEPT!"
    mov byte [KitMsgT], 36
    call CheckWin
    call Redraw
.done:
    popa
    ret

; -------------------------------------------------------------------
; Potion 3: Mine Detector / Auto-Flag (Cost: 10 Shrapnel)
; Finds and automatically flags the first unflagged mine on the board.
; Logic: Performs array scan for first instance of TILE_COVERED_MINE,
; converts state to TILE_FLAGGED, decrements remaining mine counter UI.
; -------------------------------------------------------------------
UsePotionDetector:
    pusha
    cmp byte [GameOver], 0
    jne .done
    cmp byte [PotionDetector], 0
    jne .haveDetector
    mov byte [KitMsgN], 10      ; "NO POTIONS!"
    mov byte [KitMsgT], 36
    mov word [EventPtr], EvNoPotion
    call Redraw
    jmp .done
.haveDetector:
    cmp byte [MinesPlaced], 0
    jne .minesOk
    mov al, [CurRows]
    shr al, 1
    mov [FirstRow], al
    mov al, [CurCols]
    shr al, 1
    mov [FirstCol], al
    call PlaceMinesLazy
    mov byte [Started], 1
    mov byte [TimerOn], 1
.minesOk:
    xor si, si
.scanMine:
    mov al, [Board+si]
    and al, 07h
    cmp al, 1                   ; covered mine?
    je .foundMine
    inc si
    cmp si, [CurCells]
    jb .scanMine
    jmp .done

.foundMine:
    dec byte [PotionDetector]
    or byte [Board+si], 4       ; set to TILE_FLAGGED
    mov word [EventPtr], EvDetector
    mov byte [KitMsgN], 9       ; "MINE FLAGGED!"
    mov byte [KitMsgT], 36
    call CheckWin
    call Redraw
.done:
    popa
    ret
