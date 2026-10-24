; -------------------------------------------------------------------
; Mouse click handling.  MouseX/MouseY = pixel, PrevMouse = buttons
; -------------------------------------------------------------------
HandleClick:
    pusha

    ; --- Check Endless State menus first ---
    cmp byte [EndlessState],4   ; Level Select
    jne .chkVictory
    test byte [PrevMouse],1
    jz .out
    call LevelSelectClick
    jmp .out

.chkVictory:
    cmp byte [EndlessState],1   ; Level Victory Menu
    jne .chkShopState
    test byte [PrevMouse],1     ; left click?
    jz .out
    ; Victory Menu click (dialog spans x 40..279)
    mov ax,[MouseX]
    cmp ax,40
    jb .out
    cmp ax,280
    jae .out
    mov ax,[MouseY]
    cmp ax,116
    jb .out
    cmp ax,132
    jae .chkShopBtn
    ; Continue button (Option A, text row 15)
    inc byte [CurrentLevel]
    mov byte [EndlessState],0
    call NewGame
    call DrawStatic
    call Redraw
    jmp .out
.chkShopBtn:
    cmp ax,148
    jae .chkLevelsBtn
    ; Item Shop button (Option B, text row 17)
    mov byte [EndlessState],2
    mov byte [ShopMsg],0
    call Redraw
    jmp .out
.chkLevelsBtn:
    cmp ax,164
    jae .out
    ; Level Select button (Option C, text row 19)
    call GoLevelSelect
    jmp .out

.chkShopState:
    cmp byte [EndlessState],2   ; Item Shop
    jne .chkGameOverState
    test byte [PrevMouse],1
    jz .out
    ; Shop Menu click (dialog spans x 8..311)
    mov ax,[MouseX]
    cmp ax,8
    jb .out
    cmp ax,312
    jae .out
    mov ax,[MouseY]
    cmp ax,44
    jl .out
    cmp ax,68
    jg .chkItem2
    call ShopBuyOracle
    jmp .out
.chkItem2:
    cmp ax,69
    jl .out
    cmp ax,92
    jg .chkItem3
    call ShopBuyRadar
    jmp .out
.chkItem3:
    cmp ax,93
    jl .out
    cmp ax,116
    jg .chkItem4
    call ShopBuyDetector
    jmp .out
.chkItem4:
    cmp ax,117
    jl .out
    cmp ax,145
    jg .out
    ; Option 4: Next Level
    inc byte [CurrentLevel]
    mov byte [EndlessState],0
    call NewGame
    call DrawStatic
    call Redraw
    jmp .out

.chkGameOverState:
    cmp byte [EndlessState],3   ; Game Over screen
    jne .playingState
    test byte [PrevMouse],1
    jz .out
    ; Back to the level select
    call GoLevelSelect
    jmp .out

.playingState:
    ; --- face button (new game) ---
    mov ax,[MouseX]
    cmp ax,149
    jl .board
    cmp ax,171
    jge .board
    mov ax,[MouseY]
    mov bx,[HeaderY]
    inc bx
    inc bx
    cmp ax,bx
    jl .board
    add bx,22
    cmp ax,bx
    jge .board
    test byte [PrevMouse],1
    jz .out
    call DoRestart
    jmp .out

    ; --- board ---
.board:
    cmp byte [GameOver],0
    jne .out

    ; Convert MouseX -> col dl
    mov ax,[MouseX]
    sub ax,[StartX]
    jl .out
    cmp byte [TileSize],16
    jne .div8x
    shr ax,4
    jmp .chkCol
.div8x:
    shr ax,3
.chkCol:
    cmp al,[CurCols]
    jae .out
    mov dl,al                   ; column dl

    ; Convert MouseY -> row dh
    mov ax,[MouseY]
    sub ax,[StartY]
    jl .out
    cmp byte [TileSize],16
    jne .div8y
    shr ax,4
    jmp .chkRow
.div8y:
    shr ax,3
.chkRow:
    cmp al,[CurRows]
    jae .out
    mov dh,al                   ; row dh

    ; Compute SI = cell index
    mov bh,dh
    mov bl,dl
    call CellIndex

    test byte [PrevMouse],1
    jnz .left
    test byte [PrevMouse],2
    jnz .right
    jmp .out

.left:
    ; Check if Line Radar is armed
    cmp byte [RadarArmed],0
    je .chkScanArmed
    call ApplyRowSweep          ; sweeps row in DH!
    jmp .out

.chkScanArmed:
    cmp byte [ScanArmed],0      ; mage scanner armed?
    je .plainLeft
    mov byte [ScanArmed],0
    cmp byte [MageScans],0
    je .plainLeft
    dec byte [MageScans]
    mov byte [KitMsgN],2        ; "SCANNED!"
    mov byte [KitMsgT],36
    mov al,4
    call CountCells
    push ax                     ; flags before the scan
    call ScanArea               ; DH:DL target cell
    mov al,4
    call CountCells
    pop bx
    sub ax,bx
    mov [EventNum],ax           ; mines the scan flagged
    mov word [EventPtr],EvScan
    call Redraw
    jmp .out

.plainLeft:
    cmp byte [BombArmed],0
    jne .useBomb
    test byte [Board+si],6      ; flagged or already open
    jnz .out

    ; Check first click: guarantee safe opening cascade!
    cmp byte [Started],0
    jne .go
    mov byte [Started],1
    mov byte [TimerOn],1
    mov word [TickAcc],0
    mov [FirstRow],dh
    mov [FirstCol],dl
    call PlaceMinesLazy         ; 0 adjacent mines guaranteed!

.go:
    test byte [Board+si],1
    jnz .boom
    call RevealCell
    call CheckWin
    call Redraw
    jmp .out

.useBomb:
    cmp byte [Started],0
    jne .dropBomb
    mov byte [Started],1
    mov byte [TimerOn],1
    mov word [TickAcc],0
    mov [FirstRow],dh
    mov [FirstCol],dl
    call PlaceMinesLazy
.dropBomb:
    mov byte [BombArmed],0
    dec byte [BombCount]
    mov al,2
    call CountCells
    push ax                     ; opened before the bomb
    call BombArea
    mov al,2
    call CountCells
    pop bx
    sub ax,bx
    mov [EventNum],ax           ; tiles the bomb opened
    mov word [EventPtr],EvBombUsed
    mov byte [KitMsgN],5
    mov byte [KitMsgT],36
    call CheckWin
    call Redraw
    jmp .out

.boom:
    cmp byte [SelectedClass],1  ; tank with shield?
    jne .realBoom
    cmp byte [TankShield],0
    je .realBoom
    dec byte [TankShield]
    or byte [Board+si],4        ; flag stays down
    mov word [EventPtr],EvShield
    mov byte [KitMsgN],1        ; "SHIELD!"
    mov byte [KitMsgT],36
    call Redraw
    jmp .out

.realBoom:
    mov byte [GameOver],1
    mov byte [TimerOn],0
    mov [HitCell],si
    call RevealMines
    mov si,SfxBoom
    call StartSfx

    cmp byte [CurrentMode],1   ; Endless Mode?
    jne .normalBoom
    mov byte [EndlessState],3  ; Game Over Screen!
.normalBoom:
    call Redraw
    jmp .out

.right:
    test byte [Board+si],2      ; can't flag open tile
    jnz .out
    xor byte [Board+si],4       ; toggle flag
    call Redraw

.out:
    popa
    ret

; -------------------------------------------------------------------
; Endless level select
;   Boxes: 2 rows x 5, each 44x40, x = 34 + col*52, y = 56 + row*48
; -------------------------------------------------------------------

; GoLevelSelect: show the level picker (EndlessState 4), cursor on the
; highest unlocked level
GoLevelSelect:
    pusha
    mov byte [EndlessState],4
    mov byte [TimerOn],0
    mov byte [BombArmed],0
    mov byte [ScanArmed],0
    mov byte [RadarArmed],0
    mov byte [KitMsgT],0
    mov byte [KitMsgN],0
    mov al,[UnlockedLevel]
    dec al
    cmp al,MAX_LEVEL-1
    jbe .selOk
    mov al,MAX_LEVEL-1
.selOk:
    mov [LevelSel],al
    HIDEM
    call DrawLevelFrame
    SHOWM
    call Redraw
    popa
    ret

; TryStartLevel: start [LevelSel]+1 if it is unlocked, else flag it
TryStartLevel:
    pusha
    mov al,[LevelSel]
    inc al
    cmp al,[UnlockedLevel]
    jbe .open
    mov byte [KitMsgN],11       ; "still locked" notice on the picker
    mov byte [KitMsgT],36
    call Beep
    call Redraw
    jmp .done
.open:
    mov [CurrentLevel],al
    mov byte [EndlessState],0
    call NewGame
    call DrawStatic
    call Redraw
.done:
    popa
    ret

; LevelSelectKey: AX = key from INT 16h (AL = 0 / E0h -> AH = scan code)
LevelSelectKey:
    pusha
    cmp al,27
    jne .notEsc
    popa
    jmp ExitGame                ; ESC: back to the main menu
.notEsc:
    cmp al,13
    je .play
    cmp al,' '
    je .play
    or al,al
    jz .ext
    cmp al,0E0h
    je .ext
    cmp al,'m'
    je .music
    cmp al,'M'
    je .music
    cmp al,'0'                  ; 1..9, 0 = level 10: pick and play
    je .ten
    cmp al,'1'
    jb .done
    cmp al,'9'
    ja .done
    sub al,'1'
    jmp .pick
.ten:
    mov al,9
.pick:
    mov [LevelSel],al
    jmp .play
.ext:
    mov al,[LevelSel]
    cmp ah,4Bh                  ; left
    jne .right
    add al,MAX_LEVEL-1
    jmp .wrap
.right:
    cmp ah,4Dh                  ; right
    jne .upDown
    inc al
    jmp .wrap
.upDown:
    cmp ah,48h                  ; up / down: other row
    je .row
    cmp ah,50h
    jne .done
.row:
    add al,5
.wrap:
    cmp al,MAX_LEVEL
    jb .set
    sub al,MAX_LEVEL
.set:
    mov [LevelSel],al
    mov byte [KitMsgT],0
    call Redraw
    jmp .done
.play:
    call TryStartLevel
    jmp .done
.music:
    call ToggleMusic
.done:
    popa
    ret

; LevelSelectClick: left click at [MouseX],[MouseY] on the picker
LevelSelectClick:
    pusha
    mov ax,[MouseX]
    sub ax,34
    jb .out
    cmp ax,5*52
    jae .out
    mov bl,52
    div bl                      ; AL = column, AH = x inside the cell
    cmp ah,44
    jae .out                    ; in the gap between boxes
    mov cl,al
    mov ax,[MouseY]
    sub ax,56
    jb .out
    cmp ax,2*48
    jae .out
    mov bl,48
    div bl                      ; AL = row, AH = y inside the cell
    cmp ah,40
    jae .out
    mov bl,5
    mul bl
    add al,cl
    mov [LevelSel],al
    mov byte [KitMsgT],0
    call TryStartLevel
.out:
    popa
    ret

; Beep: PC speaker bell (silent during the self-test)
Beep:
    pusha
    cmp byte [TestMode],0
    jne .quiet
    mov ah,02h
    mov dl,07h
    int 21h
.quiet:
    popa
    ret

; -------------------------------------------------------------------
; Item Shop purchase helpers
; -------------------------------------------------------------------
ShopBuyOracle:
    pusha
    mov bx,PotionOracle
    mov dl,2
    jmp ShopBuyPotion

ShopBuyRadar:
    pusha
    mov bx,PotionRadar
    mov dl,3
    jmp ShopBuyPotion

ShopBuyDetector:
    pusha
    mov bx,PotionDetector
    mov dl,4
    ; fall through

; BX -> potion counter, DL = success message id.  Entered with PUSHA done.
ShopBuyPotion:
    cmp byte [bx],POTION_MAX
    jb .chkFunds
    mov byte [ShopMsg],5        ; "carrying the maximum"
    jmp .beep
.chkFunds:
    cmp word [Shrapnels],POTION_PRICE
    jb .noFunds
    sub word [Shrapnels],POTION_PRICE
    inc byte [bx]
    mov [ShopMsg],dl
    call SaveProgress
    call Redraw
    jmp .done
.noFunds:
    mov byte [ShopMsg],1
.beep:
    cmp byte [TestMode],0       ; no BEL on the console during the tests
    jne .quiet
    mov ah,02h
    mov dl,07h
    int 21h
.quiet:
    call Redraw
.done:
    popa
    ret
