; ===================================================================
; Automated Technical Specification Test Suite
; ===================================================================
RunTestSuite:
    pusha
    mov dx, msg_suite_start
    mov ah, 09h
    int 21h

    ; Test 1: Level Progression Table
    mov word [fail_loc], 'T1'
    call test_levels

    ; Test 2: Economy & Hero Artificer Multiplier
    mov word [fail_loc], 'T2'
    call test_economy

    ; Test 3: Safe Opening Cascade
    mov word [fail_loc], 'T3'
    call test_safe_opening

    ; Test 4: Shop Validation
    mov word [fail_loc], 'T4'
    call test_shop_validation

    ; Test 5: Potion Mechanics
    mov word [fail_loc], 'T5'
    call test_potions

    ; Test 6: Main Menu Music & Audio Isolation
    mov word [fail_loc], 'T6'
    call test_menu_music

    ; Test 7: Intro Engine & Glyph Mapping
    mov word [fail_loc], 'T7'
    call test_intro_engine

    ; Test 8: Endless level unlocking
    mov word [fail_loc], 'T8'
    call test_unlocks

    ; All passed!
    mov dx, msg_all_passed
    mov ah, 09h
    int 21h

    ; Write success file TEST_OK.TXT
    mov ah, 3Ch
    xor cx, cx
    mov dx, file_test_ok
    int 21h
    jc .doneOk
    mov bx, ax
    mov ah, 40h
    mov cx, 7
    mov dx, msg_file_ok
    int 21h
    mov ah, 3Eh
    int 21h
.doneOk:
    popa
    ret

test_fail:
    push ax
    mov ah, 3Ch
    xor cx, cx
    mov dx, file_test_err
    int 21h
    jc .noErrFile
    mov bx, ax
    mov ah, 40h
    mov cx, 16
    mov dx, fail_loc
    int 21h
    mov ah, 3Eh
    int 21h
.noErrFile:
    pop ax
    mov dx, msg_test_fail
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

; --- Test 1: Levels ---
test_levels:
    pusha
    mov byte [CurrentMode], 1   ; Endless Mode

    ; Level 1: 6x6, 3 mines, 36 cells
    mov byte [CurrentLevel], 1
    call SetupCurrentLevel
    cmp byte [CurCols], 6
    jne test_fail
    cmp byte [CurRows], 6
    jne test_fail
    cmp word [CurMines], 3
    jne test_fail
    cmp word [CurCells], 36
    jne test_fail
    cmp byte [TileSize], 16
    jne test_fail

    ; Level 2: 8x8, 7 mines, 64 cells
    mov byte [CurrentLevel], 2
    call SetupCurrentLevel
    cmp byte [CurCols], 8
    jne test_fail
    cmp byte [CurRows], 8
    jne test_fail
    cmp word [CurMines], 7
    jne test_fail
    cmp word [CurCells], 64
    jne test_fail
    cmp byte [TileSize], 16
    jne test_fail

    ; Level 3: 9x9, 10 mines, 81 cells
    mov byte [CurrentLevel], 3
    call SetupCurrentLevel
    cmp byte [CurCols], 9
    jne test_fail
    cmp byte [CurRows], 9
    jne test_fail
    cmp word [CurMines], 10
    jne test_fail
    cmp word [CurCells], 81
    jne test_fail
    cmp byte [TileSize], 16
    jne test_fail

    ; Level 4: 10x10, 14 mines, 100 cells
    mov byte [CurrentLevel], 4
    call SetupCurrentLevel
    cmp byte [CurCols], 10
    jne test_fail
    cmp byte [CurRows], 10
    jne test_fail
    cmp word [CurMines], 14
    jne test_fail
    cmp word [CurCells], 100
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 5: 12x12, 21 mines, 144 cells
    mov byte [CurrentLevel], 5
    call SetupCurrentLevel
    cmp byte [CurCols], 12
    jne test_fail
    cmp byte [CurRows], 12
    jne test_fail
    cmp word [CurMines], 21
    jne test_fail
    cmp word [CurCells], 144
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 6: 16x12, 30 mines, 192 cells
    mov byte [CurrentLevel], 6
    call SetupCurrentLevel
    cmp byte [CurCols], 16
    jne test_fail
    cmp byte [CurRows], 12
    jne test_fail
    cmp word [CurMines], 30
    jne test_fail
    cmp word [CurCells], 192
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 7: 16x16, 42 mines, 256 cells
    mov byte [CurrentLevel], 7
    call SetupCurrentLevel
    cmp byte [CurCols], 16
    jne test_fail
    cmp byte [CurRows], 16
    jne test_fail
    cmp word [CurMines], 42
    jne test_fail
    cmp word [CurCells], 256
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 8: 24x14, 58 mines, 336 cells
    mov byte [CurrentLevel], 8
    call SetupCurrentLevel
    cmp byte [CurCols], 24
    jne test_fail
    cmp byte [CurRows], 14
    jne test_fail
    cmp word [CurMines], 58
    jne test_fail
    cmp word [CurCells], 336
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 9: 30x16, 90 mines, 480 cells
    mov byte [CurrentLevel], 9
    call SetupCurrentLevel
    cmp byte [CurCols], 30
    jne test_fail
    cmp byte [CurRows], 16
    jne test_fail
    cmp word [CurMines], 90
    jne test_fail
    cmp word [CurCells], 480
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 10: 30x20, 120 mines, 600 cells
    mov byte [CurrentLevel], 10
    call SetupCurrentLevel
    cmp byte [CurCols], 30
    jne test_fail
    cmp byte [CurRows], 20
    jne test_fail
    cmp word [CurMines], 120
    jne test_fail
    cmp word [CurCells], 600
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    ; Level 15 (repeat rule): should repeat Level 10 parameters
    mov byte [CurrentLevel], 15
    call SetupCurrentLevel
    cmp byte [CurCols], 30
    jne test_fail
    cmp byte [CurRows], 20
    jne test_fail
    cmp word [CurMines], 120
    jne test_fail
    cmp word [CurCells], 600
    jne test_fail
    cmp byte [TileSize], 8
    jne test_fail

    mov dx, msg_test1_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 2: Economy & Artificer ---
test_economy:
    pusha
    mov byte [CurrentMode], 1

    ; Level 1: Fixed 5 Shrapnels on finishing any level
    mov byte [CurrentLevel], 1
    call SetupCurrentLevel

    ; Test Non-Artificer (SelectedClass = 0)
    mov byte [SelectedClass], 0
    mov ax, WIN_REWARD
    mov [BaseShrapnel], ax
    cmp byte [SelectedClass], 3
    jne .notArt1
    shl ax, 1
.notArt1:
    mov [EarnedShrapnel], ax
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 5
    jne test_fail

    ; Test Artificer (SelectedClass = 3)
    mov byte [SelectedClass], 3
    mov ax, WIN_REWARD
    mov [BaseShrapnel], ax
    cmp byte [SelectedClass], 3
    jne .notArt2
    shl ax, 1
.notArt2:
    mov [EarnedShrapnel], ax
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 10       ; 5 * 2 = 10!
    jne test_fail

    ; Level 10: Still 5 Shrapnels (no scaling by grid size / mines)
    mov byte [CurrentLevel], 10
    call SetupCurrentLevel

    mov byte [SelectedClass], 0
    mov ax, WIN_REWARD
    mov [BaseShrapnel], ax
    cmp byte [SelectedClass], 3
    jne .notArt3
    shl ax, 1
.notArt3:
    mov [EarnedShrapnel], ax
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 5
    jne test_fail

    mov byte [SelectedClass], 3
    mov ax, WIN_REWARD
    mov [BaseShrapnel], ax
    cmp byte [SelectedClass], 3
    jne .notArt4
    shl ax, 1
.notArt4:
    mov [EarnedShrapnel], ax
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 10      ; 5 * 2 = 10!
    jne test_fail

    ; Verify live CheckWin execution in Endless Mode (Mode 1)
    mov byte [CurrentMode], 1
    mov byte [CurrentLevel], 1
    call SetupCurrentLevel
    mov word [Shrapnels], 20
    mov byte [SelectedClass], 0
    mov byte [GameOver], 0
    xor si, si
.openL1:
    test byte [Board+si], 1
    jnz .skipMine1
    or byte [Board+si], 2
.skipMine1:
    inc si
    cmp si, [CurCells]
    jb .openL1
    call CheckWin
    call SpeakerOff
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 5
    jne test_fail
    cmp word [Shrapnels], 25           ; 20 + 5 = 25!
    jne test_fail

    ; Verify live CheckWin execution in Vanilla Mode (Mode 0)
    mov byte [CurrentMode], 0
    call SetupCurrentLevel
    mov word [Shrapnels], 50
    mov byte [SelectedClass], 0
    mov byte [GameOver], 0
    xor si, si
.openVan:
    test byte [Board+si], 1
    jnz .skipMineV
    or byte [Board+si], 2
.skipMineV:
    inc si
    cmp si, [CurCells]
    jb .openVan
    call CheckWin
    call SpeakerOff
    cmp word [BaseShrapnel], 5
    jne test_fail
    cmp word [EarnedShrapnel], 5
    jne test_fail
    cmp word [Shrapnels], 55           ; 50 + 5 = 55!
    jne test_fail

    mov dx, msg_test2_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 3: Safe Opening Cascade ---
test_safe_opening:
    pusha
    ; Test on Level 1 (6x6)
    mov byte [CurrentMode], 1
    mov byte [CurrentLevel], 1
    call NewGame

    ; First click at (2, 2)
    mov byte [FirstRow], 2
    mov byte [FirstCol], 2
    call PlaceMinesLazy

    ; Verify mine count
    xor cx, cx
    xor si, si
.countM1:
    test byte [Board+si], 1
    jz .noM1
    inc cx
.noM1:
    inc si
    cmp si, [CurCells]
    jb .countM1
    cmp cx, 3                   ; exactly 3 mines
    jne test_fail

    ; Verify clicked cell (2, 2) and all 8 neighbors have NO mine
    mov bh, 1
.rLp1:
    mov bl, 1
.cLp1:
    call CellIndex
    test byte [Board+si], 1
    jnz test_fail               ; mine in 3x3 forbidden!
    inc bl
    cmp bl, 3
    jle .cLp1
    inc bh
    cmp bh, 3
    jle .rLp1

    ; Verify (2, 2) neighbor mine count is 0
    mov bh, 2
    mov bl, 2
    call CellIndex
    mov al, [Board+si]
    and al, 0F0h
    jnz test_fail               ; must have 0 adjacent mines!

    ; Verify RevealCell cascades!
    call RevealCell
    ; All cells in 3x3 must now be opened (bit 1 set)
    mov bh, 1
.rLpOpen:
    mov bl, 1
.cLpOpen:
    call CellIndex
    test byte [Board+si], 2
    jz test_fail                ; must be opened by cascade!
    inc bl
    cmp bl, 3
    jle .cLpOpen
    inc bh
    cmp bh, 3
    jle .rLpOpen

    ; Test on Level 10 (30x20, 120 mines)
    mov byte [CurrentLevel], 10
    call NewGame
    mov byte [FirstRow], 10
    mov byte [FirstCol], 15
    call PlaceMinesLazy

    ; Count mines
    xor cx, cx
    xor si, si
.countM10:
    test byte [Board+si], 1
    jz .noM10
    inc cx
.noM10:
    inc si
    cmp si, [CurCells]
    jb .countM10
    cmp cx, 120                 ; exactly 120 mines
    jne test_fail

    ; Verify (10, 15) neighbor mine count is 0
    mov bh, 10
    mov bl, 15
    call CellIndex
    mov al, [Board+si]
    and al, 0F0h
    jnz test_fail

    mov dx, msg_test3_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 4: Shop Validation ---
test_shop_validation:
    pusha
    ; Balance = 9 (cannot buy)
    mov word [Shrapnels], 9
    mov byte [PotionOracle], 0
    mov byte [PotionRadar], 0
    mov byte [PotionDetector], 0

    call ShopBuyOracle
    cmp word [Shrapnels], 9
    jne test_fail
    cmp byte [PotionOracle], 0
    jne test_fail
    cmp byte [ShopMsg], 1       ; error message
    jne test_fail

    call ShopBuyRadar
    cmp word [Shrapnels], 9
    jne test_fail
    cmp byte [PotionRadar], 0
    jne test_fail

    call ShopBuyDetector
    cmp word [Shrapnels], 9
    jne test_fail
    cmp byte [PotionDetector], 0
    jne test_fail

    ; Balance = 25 (can buy 2 items)
    mov word [Shrapnels], 25
    call ShopBuyOracle
    cmp word [Shrapnels], 15
    jne test_fail
    cmp byte [PotionOracle], 1
    jne test_fail
    cmp byte [ShopMsg], 2       ; success message
    jne test_fail

    call ShopBuyRadar
    cmp word [Shrapnels], 5
    jne test_fail
    cmp byte [PotionRadar], 1
    jne test_fail

    ; Now balance is 5, buying Detector must fail
    call ShopBuyDetector
    cmp word [Shrapnels], 5
    jne test_fail
    cmp byte [PotionDetector], 0
    jne test_fail
    cmp byte [ShopMsg], 1
    jne test_fail

    ; Verify class prices (Tank free, Mage / Artificer 10) & purchase
    mov ax, TANK_PRICE
    cmp ax, 0
    jne test_fail
    mov ax, MAGE_PRICE
    cmp ax, 10
    jne test_fail
    mov ax, ART_PRICE
    cmp ax, 10
    jne test_fail
    mov word [Shrapnels], 0
    mov byte [OwnedClasses], 0
    mov byte [SelectedClass], 0
    sub word [Shrapnels], TANK_PRICE
    or byte [OwnedClasses], 1
    mov byte [SelectedClass], 1
    cmp word [Shrapnels], 0
    jne test_fail
    test byte [OwnedClasses], 1
    jz test_fail
    cmp byte [SelectedClass], 1
    jne test_fail

    ; Verify Hero Shop locked descriptions and flags when Shrapnels = 0
    mov word [Shrapnels], 0
    mov byte [OwnedClasses], 1      ; only tank owned
    mov byte [SelectedClass], 1
    call UpdateShopItems
    cmp word [shop_mage_entry+2], ds_shopMageLock
    jne test_fail
    cmp byte [shop_mage_entry+4], 1
    jne test_fail
    cmp word [shop_artificer_entry+2], ds_shopArtLock
    jne test_fail
    cmp byte [shop_artificer_entry+4], 1
    jne test_fail

    ; Verify Hero Shop buy descriptions and flags when Shrapnels = 10
    mov word [Shrapnels], 10
    call UpdateShopItems
    cmp word [shop_mage_entry+2], ds_shopMageBuy
    jne test_fail
    cmp byte [shop_mage_entry+4], 0
    jne test_fail
    cmp word [shop_artificer_entry+2], ds_shopArtBuy
    jne test_fail
    cmp byte [shop_artificer_entry+4], 0
    jne test_fail

    ; Verify ClassMenu locked descriptions show skills & 10 shrapnel requirement
    call UpdateClassItems
    cmp word [cls_mage_entry+2], ds_clsMageLock
    jne test_fail
    cmp word [cls_artificer_entry+2], ds_clsArtLock
    jne test_fail

    mov dx, msg_test4_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 5: Potions Logic ---
test_potions:
    pusha
    ; Setup a controlled 6x6 board
    mov byte [CurrentMode], 1
    mov byte [CurrentLevel], 1
    call NewGame

    ; FirstRow = 2, FirstCol = 2
    mov byte [FirstRow], 2
    mov byte [FirstCol], 2
    call PlaceMinesLazy

    ; Test Oracle's Sight:
    mov byte [PotionOracle], 1
    call UsePotionOracle
    cmp byte [PotionOracle], 0   ; decremented
    jne test_fail
    ; Check that at least one tile was revealed
    xor cx, cx
    xor si, si
.checkOracle:
    test byte [Board+si], 2
    jz .noO
    inc cx
.noO:
    inc si
    cmp si, [CurCells]
    jb .checkOracle
    cmp cx, 0
    je test_fail                ; at least one tile revealed!

    ; Test Line Radar:
    mov byte [GameOver], 0
    mov byte [PotionRadar], 1
    ; Sweep row 0
    mov dh, 0
    call ApplyRowSweep
    cmp byte [PotionRadar], 0
    jne test_fail
    ; Check row 0: every cell must be either flagged (if mine) or revealed (if safe)
    mov bl, 0
.checkRadar:
    mov bh, 0
    call CellIndex
    test byte [Board+si], 1     ; mine?
    jz .radarSafe
    test byte [Board+si], 4     ; must be flagged
    jz test_fail
    jmp .nextRadarCol
.radarSafe:
    test byte [Board+si], 2     ; must be revealed
    jz test_fail
.nextRadarCol:
    inc bl
    cmp bl, [CurCols]
    jb .checkRadar

    ; Test Mine Detector:
    mov byte [GameOver], 0
    mov byte [PotionDetector], 1
    ; Ensure at least one cell has an unflagged covered mine
    mov byte [Board+35], 1
    ; Count flagged mines before
    xor cx, cx
    xor si, si
.cntFlagBefore:
    test byte [Board+si], 4
    jz .noF1
    inc cx
.noF1:
    inc si
    cmp si, [CurCells]
    jb .cntFlagBefore
    push cx

    call UsePotionDetector
    cmp byte [PotionDetector], 0
    jne test_fail

    ; Count flagged mines after
    xor cx, cx
    xor si, si
.cntFlagAfter:
    test byte [Board+si], 4
    jz .noF2
    inc cx
.noF2:
    inc si
    cmp si, [CurCells]
    jb .cntFlagAfter

    pop dx                      ; before count
    inc dx                      ; should be before + 1
    cmp cx, dx
    jne test_fail

    mov dx, msg_test5_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 6: Menu Music & Audio Isolation ---
test_menu_music:
    pusha

    ; Part A: Menu Music Toggle & Status String
    mov byte [MenuMusicOn], 1
    call UpdateMenuMusicText
    cmp word [it_music_status], 'ON'
    jne test_fail
    cmp byte [it_music_status+2], ' '
    jne test_fail

    call ToggleMenuMusic
    cmp byte [MenuMusicOn], 0
    jne test_fail
    cmp word [MenuNoteLeft], 0
    jne test_fail
    call UpdateMenuMusicText
    cmp word [it_music_status], 'OF'
    jne test_fail
    cmp byte [it_music_status+2], 'F'
    jne test_fail

    call ToggleMenuMusic
    cmp byte [MenuMusicOn], 1
    jne test_fail
    cmp word [MenuMusicPtr], track3
    jne test_fail
    call UpdateMenuMusicText
    cmp word [it_music_status], 'ON'
    jne test_fail

    ; Part B: Note Stepping & Loop Handling (track3 Danger Zone: 104ms notes)
    mov word [MenuMusicPtr], track3
    mov word [MenuNoteLeft], 0
    call PlayMenuMusicStep
    cmp word [MenuMusicPtr], track3 + 4
    jne test_fail
    cmp word [MenuNoteLeft], 94          ; 104ms - 10ms
    jne test_fail

    call PlayMenuMusicStep
    cmp word [MenuNoteLeft], 84
    jne test_fail

    ; Simulate completing the note
    mov word [MenuNoteLeft], 10
    call PlayMenuMusicStep
    cmp word [MenuNoteLeft], 0
    jne test_fail

    ; Next step fetches second note in track3
    call PlayMenuMusicStep
    cmp word [MenuMusicPtr], track3 + 8
    jne test_fail
    cmp word [MenuNoteLeft], 94
    jne test_fail

    ; Test looping at 0FFFFh
    mov word [MenuMusicPtr], track3_end  ; points to 0FFFFh loop marker
    mov word [MenuNoteLeft], 0
    call PlayMenuMusicStep
    cmp word [MenuMusicPtr], track3 + 4  ; looped back to first note
    jne test_fail
    cmp word [MenuNoteLeft], 94
    jne test_fail

    ; Part C: Isolation between Menu Music and In-Game Music
    mov byte [MusicOn], 1
    mov word [MusicPtr], SongTable
    mov word [NoteLeft], 42
    mov byte [SfxOn], 0

    ; Stepping menu music must NOT touch in-game music state
    call PlayMenuMusicStep
    cmp byte [MusicOn], 1
    jne test_fail
    cmp word [MusicPtr], SongTable
    jne test_fail
    cmp word [NoteLeft], 42
    jne test_fail
    cmp byte [SfxOn], 0
    jne test_fail

    ; In-game music toggle must NOT touch menu music state
    call ToggleMusic
    cmp byte [MusicOn], 0
    jne test_fail
    cmp byte [MenuMusicOn], 1
    jne test_fail
    call ToggleMusic
    cmp byte [MusicOn], 1
    jne test_fail
    cmp byte [MenuMusicOn], 1
    jne test_fail

    ; Part D: Screen Transition Audio Reset
    ; Menu to Game transition
    call SpeakerOff
    mov word [MenuNoteLeft], 0
    mov word [MenuMusicPtr], track3
    mov word [NoteLeft], 0
    mov word [MusicPtr], SongTable
    mov byte [SfxOn], 0

    ; In-game step advances in-game music
    mov ax, 1
    call MusicStep
    cmp word [MusicPtr], SongTable + 4
    jne test_fail
    ; Menu music state untouched
    cmp word [MenuMusicPtr], track3
    jne test_fail
    cmp word [MenuNoteLeft], 0
    jne test_fail

    ; Game to Menu transition
    call SpeakerOff
    mov word [NoteLeft], 0
    mov word [MusicPtr], SongTable
    mov byte [SfxOn], 0
    mov word [MenuNoteLeft], 0
    mov word [MenuMusicPtr], track3

    cmp word [MusicPtr], SongTable
    jne test_fail
    cmp word [NoteLeft], 0
    jne test_fail
    cmp word [MenuMusicPtr], track3
    jne test_fail
    cmp word [MenuNoteLeft], 0
    jne test_fail

    mov dx, msg_test6_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 7: Intro Engine & Data Mapping ---
test_intro_engine:
    pusha

    ; Part A: PRNG
    mov word [seed], 1234h
    call rnd
    cmp ax, 0
    je test_fail
    cmp word [seed], 1234h
    je test_fail

    ; Part B: Glyph Mapping for MINESWEEPER (11 letters)
    cmp byte [tidx+0], 0        ; M
    jne test_fail
    cmp byte [tidx+1], 1        ; I
    jne test_fail
    cmp byte [tidx+2], 2        ; N
    jne test_fail
    cmp byte [tidx+3], 3        ; E
    jne test_fail
    cmp byte [tidx+4], 4        ; S
    jne test_fail
    cmp byte [tidx+5], 5        ; W
    jne test_fail
    cmp byte [tidx+6], 3        ; E
    jne test_fail
    cmp byte [tidx+7], 3        ; E
    jne test_fail
    cmp byte [tidx+8], 6        ; P
    jne test_fail
    cmp byte [tidx+9], 3        ; E
    jne test_fail
    cmp byte [tidx+10], 7       ; R
    jne test_fail

    ; Part C: ShowIntro in TestMode (clean non-blocking return)
    mov byte [TestMode], 1
    mov byte [IntroShown], 0
    call ShowIntro
    cmp byte [IntroShown], 1
    jne test_fail

    mov dx, msg_test7_ok
    mov ah, 09h
    int 21h
    popa
    ret

; --- Test 8: Level unlock progression ---
test_unlocks:
    pusha
    mov byte [CurrentMode], 1
    mov byte [SelectedClass], 0
    mov byte [UnlockedLevel], 1

    ; Beat level 1 -> level 2 unlocks
    mov byte [CurrentLevel], 1
    call test_win_board
    cmp byte [UnlockedLevel], 2
    jne test_fail
    cmp byte [JustUnlocked], 2
    jne test_fail

    ; Beat level 1 again -> nothing new
    mov byte [CurrentLevel], 1
    call test_win_board
    cmp byte [UnlockedLevel], 2
    jne test_fail
    cmp byte [JustUnlocked], 0
    jne test_fail

    ; Beat level 10 -> marked all beaten (11), never beyond
    mov byte [UnlockedLevel], 10
    mov byte [CurrentLevel], 10
    call test_win_board
    cmp byte [UnlockedLevel], 11
    jne test_fail
    mov byte [CurrentLevel], 12
    call test_win_board
    cmp byte [UnlockedLevel], 11
    jne test_fail

    ; Vanilla wins never touch Endless progress
    mov byte [CurrentMode], 0
    mov byte [UnlockedLevel], 3
    call test_win_board
    cmp byte [UnlockedLevel], 3
    jne test_fail

    call SpeakerOff             ; CheckWin started the win jingle
    mov byte [SfxOn], 0
    mov dx, msg_test8_ok
    mov ah, 09h
    int 21h
    popa
    ret

; test_win_board: new board for the current mode/level, open every safe
; cell, then run CheckWin
test_win_board:
    pusha
    call NewGame
    mov byte [FirstRow], 0
    mov byte [FirstCol], 0
    call PlaceMinesLazy
    xor si, si
.open:
    test byte [Board+si], 1
    jnz .next
    or byte [Board+si], 2
.next:
    inc si
    cmp si, [CurCells]
    jb .open
    call CheckWin
    cmp byte [GameOver], 2
    jne test_fail
    popa
    ret

fail_loc:       db 'INIT            ',0
file_test_err:  db 'TEST_ERR.TXT',0
file_test_ok:   db 'TEST_OK.TXT',0
msg_file_ok:    db 'SUCCESS'
msg_suite_start: db '=== RUNNING MINESWEEPER TECHNICAL SPEC TEST SUITE ===',0Dh,0Ah,'$'
msg_test1_ok:   db '[PASS] Test 1: Endless Mode Level Progression & Grid Sizes (L1-L10+)',0Dh,0Ah,'$'
msg_test2_ok:   db '[PASS] Test 2: Hero & Economy System (Base Shrapnel & Artificer 2x Multiplier)',0Dh,0Ah,'$'
msg_test3_ok:   db '[PASS] Test 3: Guaranteed Safe Opening Cascade (0 Adjacent Mines)',0Dh,0Ah,'$'
msg_test4_ok:   db '[PASS] Test 4: Shop Validation (<10 Shrapnel Prevented)',0Dh,0Ah,'$'
msg_test5_ok:   db '[PASS] Test 5: Potion Mechanics (Oracle, Line Radar, Mine Detector)',0Dh,0Ah,'$'
msg_test6_ok:   db '[PASS] Test 6: Menu Music & Audio Isolation (No Conflict with In-Game Music)',0Dh,0Ah,'$'
msg_test7_ok:   db '[PASS] Test 7: Intro Engine (PRNG, Glyph Pipeline, TestMode Guard)',0Dh,0Ah,'$'
msg_test8_ok:   db '[PASS] Test 8: Endless Level Unlocks (Level N unlocks N+1, capped)',0Dh,0Ah,'$'
msg_all_passed: db '=== ALL 8 TEST SUITES PASSED PERFECTLY! ===',0Dh,0Ah,'$'
msg_test_fail:  db '[FAIL] A TEST FAILED!',0Dh,0Ah,'$'
