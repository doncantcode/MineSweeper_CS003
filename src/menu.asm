; -------------------------------------------------------------------
; Text-mode front end (80x25) - v3 menu UI
;   * big block-letter MINESWEEPER logo, ice-white to steel-blue + shadow
;   * dimmed minefield backdrop so menu details stand out
;   * steel-blue pinstripes framing the black masthead / stage
;   * one data-driven menu engine (RunMenu) used by main/mode/shop
;   * arrow keys / W,S + Enter, number hotkeys, Esc = back
;   * highlight bar, per-item description line, locked-item styling
;   * everything drawn straight into video RAM (B800h): no flicker
; [CurrentMode] values unchanged (0 vanilla, 1 endless, 2 rapid).
; Only background colours 0-7 are used, so the BIOS blink bit is
; never an issue.
; -------------------------------------------------------------------

PC          equ 15              ; panel left column (panel is 50 wide, centred)
RBN         equ 12              ; entries in the rainbow palette

; --- low-level helpers ----------------------------------------------

; ClearScr: fresh 80x25 mode, cleared to blue/white chrome
ClearScr:
    pusha
    mov ax,0003h
    int 10h
    mov ax,0600h
    mov bh,1Fh
    mov cx,0000h
    mov dx,184Fh
    int 10h
    mov ah,02h
    mov bh,0
    xor dx,dx
    int 10h
    popa
    ret

; ClearFast: clear to blue/white WITHOUT a mode reset (no flicker)
ClearFast:
    pusha
    mov ax,0600h
    mov bh,1Fh
    xor cx,cx
    mov dx,184Fh
    int 10h
    popa
    ret

; Band: fill rows CH..DH with attribute BH
Band:
    pusha
    mov ax,0600h
    mov cl,0
    mov dl,79
    int 10h
    popa
    ret

; PaintBG: minefield backdrop on rows CH..DH.  Six pattern rows repeat;
; BgCell turns pattern characters into coloured screen cells.
PaintBG:
    pusha
    push es
    mov ax,0B800h
    mov es,ax
    cld
    mov bl,dh                   ; last row
.row:
    mov al,ch                   ; pattern = bg_rows[row mod 6]
    xor ah,ah
    mov dl,6
    div dl
    mov al,ah
    xor ah,ah
    shl ax,1
    mov si,ax
    mov si,[bg_rows+si]
    mov al,80                   ; DI = row * 160
    mul ch
    shl ax,1
    mov di,ax
    mov dh,80
.cell:
    lodsb
    or al,al
    jz .fill
    call BgCell
    stosw
    dec dh
    jnz .cell
    jmp .next
.fill:
    mov ax,1120h                ; pattern ended early: plain blue
.f:
    stosw
    dec dh
    jnz .f
.next:
    inc ch
    cmp ch,bl
    jbe .row
    pop es
    popa
    ret

; BgCell: AL = pattern char -> AL = screen char, AH = attribute
;   '.' dot   '*' mine   '^' flag   '1'..'8' classic number colours
BgCell:
    cmp al,'.'
    jne .n1
    mov ax,10FAh                ; black-on-blue dot (dim)
    ret
.n1:
    cmp al,'*'
    jne .n2
    mov ax,180Fh                ; dim grey mine
    ret
.n2:
    cmp al,'^'
    jne .n3
    mov ax,191Eh                ; dim blue flag
    ret
.n3:
    cmp al,'1'
    jb .sp
    cmp al,'8'
    ja .sp
    push bx
    mov bl,al
    sub bl,'1'
    xor bh,bh
    mov ah,[nr_bg+bx]
    pop bx
    ret
.sp:
    mov ax,1120h
    ret

; Rainbow: row DH, AL = char; 80 cells cycling through rb_tab (bg black)
Rainbow:
    pusha
    push es
    mov bx,0B800h
    mov es,bx
    mov bl,al                   ; char
    mov al,80
    mul dh
    shl ax,1
    mov di,ax
    mov cx,80
    xor si,si
    cld
.lp:
    mov al,bl
    mov ah,[rb_tab+si]
    stosw
    inc si
    cmp si,RBN
    jb .n
    xor si,si
.n:
    loop .lp
    pop es
    popa
    ret

; NumRow: row DH, centred "1 2 3 4 5 6 7 8" in minesweeper rainbow
NumRow:
    pusha
    mov dl,32
    xor si,si
    mov cx,8
.n:
    mov ax,si
    add al,'1'
    mov [nbuf],al
    mov bl,[nr_stage+si]
    push si
    mov si,nbuf
    call PrintA
    pop si
    inc si
    add dl,2
    loop .n
    popa
    ret

; WaitKey: AL = keypress, no echo
WaitKey:
    mov ah,07h
    int 21h
    ret

; GetKey: AL = key code, AH = 0 normal / 1 extended (arrows etc, AL=scan)
GetKey:
    mov ah,07h
    int 21h
    or al,al
    jnz .norm
    mov ah,07h
    int 21h
    mov ah,1
    ret
.norm:
    xor ah,ah
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
; (legacy BIOS version, kept for other modules)
PrintAttr:
    pusha
.ch:
    lodsb
    or al,al
    jz .done
    mov ah,09h
    mov bh,0
    mov cx,1
    int 10h
    push ax
    mov ah,03h
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

; PrintA: DH=row DL=col BL=attr SI->0-terminated string
; Writes directly to video RAM, clipped at column 80. Cursor untouched.
PrintA:
    pusha
    push es
    mov ax,0B800h
    mov es,ax
    mov cl,dl
    cmp cl,80
    jae .done
    mov al,80
    mul dh                      ; AX = row*80
    mov dh,80
    sub dh,cl                   ; DH = cells left on this row
    xor ch,ch
    add ax,cx
    shl ax,1
    mov di,ax
    mov ah,bl                   ; attribute
    cld
.lp:
    or dh,dh
    jz .done
    lodsb
    or al,al
    jz .done
    stosw
    dec dh
    jmp .lp
.done:
    pop es
    popa
    ret

; PrintG: like PrintA, for block graphics.  ' ' is transparent,
;   '#' -> [g_full] (default DBh)   '^' -> upper half   '_' -> lower half
PrintG:
    pusha
    push es
    mov ax,0B800h
    mov es,ax
    mov cl,dl
    cmp cl,80
    jae .done
    mov al,80
    mul dh
    mov dh,80
    sub dh,cl
    xor ch,ch
    add ax,cx
    shl ax,1
    mov di,ax
    mov ah,bl
    cld
.lp:
    or dh,dh
    jz .done
    lodsb
    or al,al
    jz .done
    cmp al,' '
    je .skip
    cmp al,'#'
    jne .n1
    mov al,[g_full]
    jmp .put
.n1:
    cmp al,'^'
    jne .n2
    mov al,0DFh
    jmp .put
.n2:
    cmp al,'_'
    jne .put
    mov al,0DCh
.put:
    stosw
    dec dh
    jmp .lp
.skip:
    add di,2
    dec dh
    jmp .lp
.done:
    pop es
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

; PrintCRow: centred on row DH, BL = attr, SI -> string
PrintCRow:
    pusha
    call StrLen
    mov ax,80
    sub ax,cx
    shr ax,1
    mov dl,al
    call PrintA
    popa
    ret

; TypeStr: centred typewriter line on row DH (intro status)
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
    mov ah,03h
    mov bh,0
    int 10h
    inc dl
    mov ah,02h
    int 10h
    pop ax
    push cx
    mov cx,0
    mov dx,9C40h
    mov ah,86h
    int 15h
    pop cx
    jmp .ch
.done:
    popa
    ret

; Delay350: ~0.35 s pause
Delay350:
    pusha
    mov cx,5
    mov dx,5730h
    mov ah,86h
    int 15h
    popa
    ret

; DrawBar: reverse-video status bar on the bottom row. SI -> left text
DrawBar:
    pusha
    push si
    mov bl,70h
    mov si,bar_fill
    mov dh,24
    xor dl,dl
    call PrintA
    pop si
    xor dl,dl
    call PrintA
    mov si,bar_ver
    mov dl,75
    call PrintA
    popa
    ret

; FormatWallet: update the five decimal digits in wallet_line.
FormatWallet:
    pusha
    mov ax,[Shrapnels]
    mov bx,10000
    xor dx,dx
    div bx
    add al,'0'
    mov [wallet_line+11],al
    mov ax,dx
    mov bx,1000
    xor dx,dx
    div bx
    add al,'0'
    mov [wallet_line+12],al
    mov ax,dx
    mov bx,100
    xor dx,dx
    div bx
    add al,'0'
    mov [wallet_line+13],al
    mov ax,dx
    mov bx,10
    xor dx,dx
    div bx
    add al,'0'
    mov [wallet_line+14],al
    add dl,'0'
    mov [wallet_line+15],dl
    popa
    ret

; --- menu engine ----------------------------------------------------
;
; Descriptor:   dw title, crumb, hint
;               db count
;               count * ( dw name, desc ; db flags )     flags bit0 = locked
;
; RunMenu: SI -> descriptor, AL = initial selection
;          returns AL = chosen index, or 0FFh for Esc

RunMenu:
    push bx
    push cx
    push dx
    push si
    push di
    mov [m_desc],si
    mov [m_sel],al
    mov al,[si+6]
    mov [m_cnt],al
    mov ah,16                   ; panel row = (24 - (count+8)) / 2
    sub ah,al
    shr ah,1
    mov [m_row],ah
    call MenuDraw

.key:
    call GetKey
    or ah,ah
    jnz .ext
    cmp al,0Dh
    je .enter
    cmp al,1Bh
    je .esc
    cmp al,'w'
    je .up
    cmp al,'W'
    je .up
    cmp al,'s'
    je .down
    cmp al,'S'
    je .down
    cmp al,'1'                  ; number hotkey: highlight + activate
    jb .key
    sub al,'1'
    cmp al,[m_cnt]
    jae .key
    call MoveTo
    jmp .enter
.ext:
    cmp al,48h                  ; up
    je .up
    cmp al,50h                  ; down
    je .down
    cmp al,47h                  ; home
    je .home
    cmp al,4Fh                  ; end
    je .end
    jmp .key
.up:
    mov al,[m_sel]
    or al,al
    jnz .u1
    mov al,[m_cnt]
.u1:
    dec al
    call MoveTo
    jmp .key
.down:
    mov al,[m_sel]
    inc al
    cmp al,[m_cnt]
    jb .d1
    xor al,al
.d1:
    call MoveTo
    jmp .key
.home:
    xor al,al
    call MoveTo
    jmp .key
.end:
    mov al,[m_cnt]
    dec al
    call MoveTo
    jmp .key
.enter:
    mov al,[m_sel]
    call ItemPtr
    test byte [di+4],1          ; locked? beep and stay
    jz .accept
    mov ah,02h
    mov dl,07h
    int 21h
    jmp .key
.accept:
    mov al,[m_sel]
    jmp .out
.esc:
    mov al,0FFh
.out:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; ItemPtr: AL = index -> DI = item record (AX, BX preserved)
ItemPtr:
    push ax
    push bx
    mov bl,5
    mul bl
    mov di,[m_desc]
    add di,7
    add di,ax
    pop bx
    pop ax
    ret

; MoveTo: AL = new selection; redraws only the two rows that changed
MoveTo:
    pusha
    cmp al,[m_sel]
    je .same
    mov bl,[m_sel]
    mov [m_sel],al
    mov al,bl
    call DrawItem
    mov al,[m_sel]
    call DrawItem
    call DrawDesc
.same:
    popa
    ret

; MenuDraw: backdrop, masthead, shadowed panel, all items, description
MenuDraw:
    pusha
    call ClearFast
    mov ch,0
    mov dh,23
    call PaintBG                ; minefield

    mov ch,1                    ; black masthead band
    mov dh,4
    mov bh,00h
    call Band
    mov dh,0                    ; rainbow stripe above ...
    mov al,0DCh
    call Rainbow
    mov dh,5                    ; ... and below it
    mov al,0DFh
    call Rainbow

    mov byte [g_full],0DBh      ; compact 2-row logo, ice over steel blue
    mov bl,0Fh
    mov dh,2
    mov dl,17
    mov si,mt_r0
    call PrintG
    mov bl,0Bh
    inc dh
    mov si,mt_r1
    call PrintG
    mov si,str_mine             ; a mine on each flank
    mov bl,07h
    mov dh,2
    mov dl,13
    call PrintA
    mov dl,65
    call PrintA
    mov bl,08h
    mov dh,3
    call PrintA
    mov dl,13
    call PrintA
    mov dh,4
    mov bl,0Bh
    mov si,msg_dosEd
    call PrintCRow

    mov di,[m_desc]             ; breadcrumb + key hints
    mov dh,21
    mov bl,17h
    mov si,[di+2]
    call PrintCRow
    mov si,[di+4]
    call DrawBar

    mov al,[m_cnt]              ; panel height = count + 8
    add al,8
    mov [m_h],al

    mov cl,al                   ; drop shadow (offset +2,+1)
    mov dh,[m_row]
    inc dh
    mov dl,PC+2
    mov bl,00h
    mov si,sp50
.sh:
    call PrintA
    inc dh
    dec cl
    jnz .sh

    mov dh,[m_row]              ; panel frame
    mov dl,PC
    mov bl,0Bh
    mov si,box_top50
    call PrintA
    mov cl,[m_h]
    sub cl,2
.mid:
    inc dh
    mov si,box_mid
    call PrintA
    dec cl
    jnz .mid
    inc dh
    mov si,box_bot50
    call PrintA

    mov dh,[m_row]              ; separators under title / above help
    add dh,2
    mov si,box_sep
    call PrintA
    mov dh,[m_row]
    add dh,[m_cnt]
    add dh,5
    call PrintA

    mov dh,[m_row]              ; panel title
    inc dh
    mov bl,0Fh
    mov di,[m_desc]
    mov si,[di]
    call PrintCRow

    xor al,al                   ; items + help line
.it:
    call DrawItem
    inc al
    cmp al,[m_cnt]
    jb .it
    call DrawDesc
    cmp word [m_desc],menu_shop
    jne .noWallet
    call FormatWallet
    mov dh,19
    mov bl,0Eh
    mov si,wallet_line
    call PrintCRow
.noWallet:
    cmp byte [ProgressError],0
    je .done
    mov dh,19
    cmp word [m_desc],menu_shop
    jne .errorRow
    mov dh,20
.errorRow:
    mov bl,0Ch
    mov si,shop_saveError
    call PrintCRow
.done:
    popa
    ret

; DrawItem: AL = index; style depends on [m_sel] and the locked flag
DrawItem:
    pusha
    mov cl,al
    call ItemPtr
    mov bh,[di+4]               ; flags
    mov dh,[m_row]
    add dh,4
    add dh,cl

    mov byte [a_name],0Fh       ; normal
    mov byte [a_key],0Bh
    cmp cl,[m_sel]
    jne .unsel
    mov byte [a_name],70h       ; selected: black on grey bar
    mov byte [a_key],71h
    test bh,1
    jz .draw
    mov byte [a_name],4Fh       ; selected + locked: white on red
    mov byte [a_key],4Fh
    jmp .draw
.unsel:
    test bh,1
    jz .draw
    mov byte [a_name],08h       ; locked: dark grey
    mov byte [a_key],08h
.draw:
    mov bl,[a_name]             ; bar fill
    mov si,sp48
    mov dl,PC+1
    call PrintA
    cmp cl,[m_sel]              ; pointer
    jne .nomark
    mov bl,[a_key]
    mov si,str_marker
    mov dl,PC+3
    call PrintA
.nomark:
    mov al,cl                   ; [n]
    add al,'1'
    mov [keybuf+1],al
    mov bl,[a_key]
    mov si,keybuf
    mov dl,PC+5
    call PrintA
    mov bl,[a_name]             ; label
    mov si,[di]
    mov dl,PC+9
    call PrintA
    test bh,1
    jz .done
    mov bl,[a_name]
    mov si,str_locked
    mov dl,PC+38
    call PrintA
.done:
    popa
    ret

; DrawDesc: help line for the highlighted item
DrawDesc:
    pusha
    mov al,[m_sel]
    call ItemPtr
    mov dh,[m_row]
    add dh,[m_cnt]
    add dh,6
    mov bl,0Bh
    test byte [di+4],1
    jz .a
    mov bl,0Ch
.a:
    mov si,sp48
    mov dl,PC+1
    call PrintA
    mov si,[di+2]
    mov dl,PC+3
    call PrintA
    popa
    ret

; --- intro ----------------------------------------------------------

ShowIntro:
    pusha
    call ClearScr

    mov ch,0                    ; minefield everywhere ...
    mov dh,23
    call PaintBG
    mov ch,2                    ; ... then a black stage
    mov dh,15
    mov bh,00h
    call Band
    mov dh,1                    ; rainbow stripes hugging the stage
    mov al,0DCh
    call Rainbow
    mov dh,16
    mov al,0DFh
    call Rainbow

    mov bl,03h                  ; cyan frame
    mov si,box_top
    mov dh,2
    mov dl,1
    call PrintA
    mov si,box_bot
    mov dh,15
    mov dl,1
    call PrintA
    mov si,box_side
    mov ch,3
.sides:
    mov dh,ch
    mov dl,1
    call PrintA
    mov dl,78
    call PrintA
    inc ch
    cmp ch,15
    jb .sides

    mov byte [g_full],0B1h      ; logo shadow: dim shaded blocks, +1/+1
    mov bl,08h
    mov dh,5
    mov dl,8
    mov si,ttl_r0
    call PrintG
    inc dh
    mov si,ttl_r1
    call PrintG
    inc dh
    mov si,ttl_r2
    call PrintG
    inc dh
    mov si,ttl_r3
    call PrintG
    inc dh
    mov si,ttl_r4
    call PrintG

    mov byte [g_full],0DBh      ; logo: ice white down to steel blue
    mov dl,7
    mov dh,4
    mov bl,0Fh
    mov si,ttl_r0
    call PrintG
    inc dh
    mov bl,0Bh
    mov si,ttl_r1
    call PrintG
    inc dh
    mov si,ttl_r2
    call PrintG
    inc dh
    mov bl,03h
    mov si,ttl_r3
    call PrintG
    inc dh
    mov bl,09h
    mov si,ttl_r4
    call PrintG

    mov dh,11                   ; fuse ornament with a mine in the middle
    mov bl,07h
    mov si,orn_fuse
    call PrintCRow
    mov bl,0Bh
    mov si,str_mine
    mov dl,39
    call PrintA

    mov dh,12
    mov bl,0Bh
    mov si,msg_dosEd
    call PrintCRow
    mov dh,13
    call NumRow

    mov dh,19                   ; tactical status, typed out
    mov bl,1Bh
    mov si,msg_scan
    call TypeStr
    call Delay350

    mov dh,20
    mov bl,1Bh
    mov si,msg_mines
    call PrintCRow
    call Delay350

    mov dh,22
    mov bl,1Fh
    mov si,msg_anykey
    call PrintCRow

    mov si,bar_left
    call DrawBar
    call WaitKey
    mov byte [IntroShown],1
    popa
    ret

; --- main menu ------------------------------------------------------

MainMenu:
    cmp byte [IntroShown],0
    jne .loop
    call ShowIntro
.loop:
    mov si,menu_main
    xor al,al
    call RunMenu
    cmp al,0FFh                 ; Esc on the main menu: ignore
    je .loop
    cmp al,0
    je .play
    cmp al,1
    je .shop
    cmp al,2
    je .credits
    cmp al,3
    je .exit
.play:
    call ModeMenu               ; AL=0 -> Back to main menu
    or al,al
    jz .loop
    ret                         ; launch with the equipped class
.shop:
    call ShopMenu
    jmp .loop
.credits:
    call ClearScr
    call show_credits
    jmp .loop
.exit:
    call ExitToDos

; ShopMenu: buy classes with permanent Shrapnels or equip owned classes.
ShopMenu:
    mov al,[SelectedClass]
    or al,al
    jz .loop
    dec al
.loop:
    call UpdateShopItems
    mov si,menu_shop
    call RunMenu
    cmp al,3
    jae .back
    cmp al,0
    je .tank
    cmp al,1
    je .mage
    jmp .artificer
.tank:
    test byte [OwnedClasses],1
    jnz .equipTank
    sub word [Shrapnels],TANK_PRICE
    or byte [OwnedClasses],1
.equipTank:
    mov byte [SelectedClass],1
    jmp .save
.mage:
    test byte [OwnedClasses],2
    jnz .equipMage
    sub word [Shrapnels],MAGE_PRICE
    or byte [OwnedClasses],2
.equipMage:
    mov byte [SelectedClass],2
    jmp .save
.artificer:
    test byte [OwnedClasses],4
    jnz .equipArtificer
    sub word [Shrapnels],ART_PRICE
    or byte [OwnedClasses],4
.equipArtificer:
    mov byte [SelectedClass],3
.save:
    call SaveProgress
    mov al,[SelectedClass]
    dec al
    jmp .loop
.back:
    ret

; Update a shop entry. Inputs: DI=item, BL=ownership bit, DL=class ID,
; CX=price, SI=buy description, BP=equipped description.
UpdateShopItem:
    push ax
    test byte [OwnedClasses],bl
    jz .unowned
    cmp byte [SelectedClass],dl
    jne .owned
    mov word [di+2],bp
    mov byte [di+4],0
    jmp .done
.owned:
    mov word [di+2],ds_shopOwned
    mov byte [di+4],0
    jmp .done
.unowned:
    cmp word [Shrapnels],cx
    jb .insufficient
    mov word [di+2],si
    mov byte [di+4],0
    jmp .done
.insufficient:
    mov word [di+2],ds_shopNeed
    mov byte [di+4],1
.done:
    pop ax
    ret

UpdateShopItems:
    mov di,shop_tank_entry
    mov bl,1
    mov dl,1
    mov cx,TANK_PRICE
    mov si,ds_shopTankBuy
    mov bp,ds_shopTankEquipped
    call UpdateShopItem
    mov di,shop_mage_entry
    mov bl,2
    mov dl,2
    mov cx,MAGE_PRICE
    mov si,ds_shopMageBuy
    mov bp,ds_shopMageEquipped
    call UpdateShopItem
    mov di,shop_artificer_entry
    mov bl,4
    mov dl,3
    mov cx,ART_PRICE
    mov si,ds_shopArtBuy
    mov bp,ds_shopArtEquipped
    call UpdateShopItem
    ret

; ModeMenu: AL=1 with [CurrentMode] set, or AL=0 for Back
ModeMenu:
    mov al,[CurrentMode]        ; cursor starts on the last choice
    cmp al,3
    jb .go
    xor al,al
.go:
    mov si,menu_mode
    call RunMenu
    cmp al,3                    ; item 4 (BACK) or Esc (0FFh)
    jae .back
    mov [CurrentMode],al        ; indices match 0/1/2
    mov al,1
    ret
.back:
    xor al,al
    ret

; --- exit -----------------------------------------------------------

ExitToDos:
    call ClearScr
    mov ch,0
    mov dh,23
    call PaintBG
    mov ch,10
    mov dh,14
    mov bh,00h
    call Band
    mov dh,9
    mov al,0DCh
    call Rainbow
    mov dh,15
    mov al,0DFh
    call Rainbow
    mov dh,11
    mov bl,0Fh
    mov si,msg_exit0
    call PrintCRow
    mov dh,12
    mov bl,1Bh
    mov si,msg_exit1
    call PrintCRow
    mov dh,13
    mov bl,17h
    mov si,msg_exit2
    call PrintCRow
    mov dh,22                   ; park the cursor below the scene
    xor dl,dl
    mov bh,0
    mov ah,02h
    int 10h
    mov ax,4C00h
    int 21h

; --- menu data ------------------------------------------------------

menu_main:
    dw ttl_main, crm_main, hint_main
    db 4
    dw it_play,    ds_play
    db 0
    dw it_shop,    ds_shop
    db 0
    dw it_credits, ds_credits
    db 0
    dw it_exit,    ds_exit
    db 0

menu_mode:
    dw ttl_mode, crm_mode, hint_sub
    db 4
    dw it_vanilla, ds_vanilla
    db 0
    dw it_endless, ds_endless
    db 0
    dw it_rapid,   ds_rapid
    db 0
    dw it_back,    ds_modeBack
    db 0

menu_shop:
    dw ttl_shop, crm_shop, hint_sub
    db 4
shop_tank_entry:
    dw it_tank,      ds_shopTankBuy
    db 0
shop_mage_entry:
    dw it_mage,      ds_shopMageBuy
    db 0
shop_artificer_entry:
    dw it_artificer, ds_shopArtBuy
    db 0
    dw it_shopBack,  ds_shopBack
    db 0

; engine state
m_desc:     dw 0
m_sel:      db 0
m_cnt:      db 0
m_row:      db 0
m_h:        db 0
a_name:     db 0
a_key:      db 0
g_full:     db 0DBh
nbuf:       db '1',0

; palettes
rb_tab:     db 08h,08h,01h,01h,09h,09h,01h,01h,08h,08h,01h,01h
nr_bg:      db 19h,18h,19h,18h,19h,18h,19h,18h      ; dim digits 1-8 on blue
nr_stage:   db 08h,07h,03h,0Bh,09h,03h,0Bh,0Fh      ; digits 1-8 on black

; --- generated art: block logo (5 rows), compact logo (2 rows),
;     minefield backdrop patterns (6 rows) ------------------------------

ttl_r0:   db '#   # ##### #   # #####  #### #   # ##### ##### ####  ##### #### ',0
ttl_r1:   db '## ##   #   ##  # #     #     #   # #     #     #   # #     #   #',0
ttl_r2:   db '# # #   #   # # # ####   ###  # # # ####  ####  ####  ####  #### ',0
ttl_r3:   db '#   #   #   #  ## #         # ## ## #     #     #     #     #  # ',0
ttl_r4:   db '#   # ##### #   # ##### ####  #   # ##### ##### #     ##### #   #',0
mt_r0:    db '#^_^# # #_ # #^^ #^ # # # #^^ #^^ #^# #^^ #^#',0
mt_r1:    db '# ^ # # # ^# ##_ _# ^_^_^ ##_ ##_ #^^ ##_ #^_',0
bgp0:     db '. . . . . . . . . . . . . . . . . 6 . . . . . . . . . . . . . . . . . . . . . 2 ',0
bgp1:     db '. . . . . . 4 . * . . . . . . . . . 2 . . . . . . . . . . . . . . . 2 . . . . . ',0
bgp2:     db '. . . . 1 . . . . . . . * . . . . . . . . . . . . . . . 6 . . . 5 . . . . . . . ',0
bgp3:     db '. . . . . . . . 6 . . 7 . . . . * . . . . . . . . . 7 . . 5 . . . 5 . . . . . . ',0
bgp4:     db '. . * 2 . . . . . . . . . . 7 . 2 7 . . . . . . 1 . . . . . 2 . . . . . 8 . . 1 ',0
bgp5:     db '. . . 1 . . . 1 . . . 8 . . 3 * . 1 . . . . . . . 2 6 . . . 1 . . . . . . . . . ',0
bg_rows:    dw bgp0,bgp1,bgp2,bgp3,bgp4,bgp5

; --- strings --------------------------------------------------------

box_top:    db 0C9h, 76 dup(0CDh), 0BBh, 0
box_bot:    db 0C8h, 76 dup(0CDh), 0BCh, 0
box_side:   db 0BAh, 0

box_top50:  db 0C9h, 48 dup(0CDh), 0BBh, 0
box_bot50:  db 0C8h, 48 dup(0CDh), 0BCh, 0
box_sep:    db 0C7h, 48 dup(0C4h), 0B6h, 0
box_mid:    db 0BAh
            times 48 db ' '
            db 0BAh, 0

sp48:       times 48 db ' '
            db 0
sp50:       times 50 db ' '
            db 0
bar_fill:   times 80 db ' '
            db 0
bar_left:   db ' MINESWEEPER - DOS EDITION',0
bar_ver:    db 'V1.0 ',0

hint_main:  db ' ',18h,19h,' MOVE   ENTER SELECT   1-4 QUICK PICK',0
hint_sub:   db ' ',18h,19h,' MOVE   ENTER SELECT   ESC BACK   1-4 QUICK PICK',0

str_marker: db 10h,0
str_mine:   db 0Fh,0
str_locked: db '[LOCKED]',0
keybuf:     db '[1]',0
orn_fuse:   db '-=<<< ',0Fh,' >>>=-',0

msg_dosEd:  db 'D O S   E D I T I O N',0
msg_mTitle: db 'M I N E S W E E P E R',0
msg_scan:   db 'SCANNING GRID FIELD...',0
msg_mines:  db '10 MINES LOCATED!',0
msg_anykey: db 'PRESS ANY KEY TO CONTINUE',0

ttl_main:   db 'MAIN MENU',0
ttl_mode:   db 'SELECT GAMEMODE',0
ttl_shop:   db 'SHRAPNEL SHOP',0
crm_main:   db ' MAIN MENU ',0
crm_mode:   db ' MAIN MENU > PLAY > GAMEMODE ',0
crm_shop:   db ' MAIN MENU > SHOP ',0

it_play:    db 'PLAY',0
it_shop:    db 'SHOP',0
it_credits: db 'CREDITS',0
it_exit:    db 'EXIT TO DOS',0
ds_play:    db 'Start with the selected mode and equipped class.',0
ds_shop:    db 'Buy and equip classes with Shrapnels.',0
ds_credits: db 'See who built this game.',0
ds_exit:    db 'Quit and return to the DOS prompt.',0

it_vanilla: db 'VANILLA',0
it_endless: db 'ENDLESS',0
it_rapid:   db 'RAPID',0
it_back:    db 'BACK',0
ds_vanilla: db 'Classic sweep. Timer counts up.',0
ds_endless: db 'Relaxed sweep. No time limit.',0
ds_rapid:   db 'Beat the 60 second countdown!',0
ds_modeBack: db 'Return to the main menu.',0

it_tank:      db 'TANK',0
it_mage:      db 'MAGE',0
it_artificer: db 'ARTIFICER',0
it_shopBack:  db 'BACK',0
ds_shopTankBuy: db 'Buy: 10 Shrapnels. One blast shield per board.',0
ds_shopMageBuy: db 'Buy: 15 Shrapnels. Press S to scan a 3x3 area.',0
ds_shopArtBuy: db 'Buy: 20 Shrapnels. More item tiles per board.',0
ds_shopTankEquipped: db 'Equipped: absorbs one blast per board.',0
ds_shopMageEquipped: db 'Equipped: press S for one 3x3 scan per game.',0
ds_shopArtEquipped: db 'Equipped: more likely to find a third item.',0
ds_shopOwned: db 'Owned. Select to equip this class.',0
ds_shopNeed: db 'Not enough Shrapnels. Clear boards for +5.',0
ds_shopBack: db 'Return to the main menu.',0
shop_saveError: db 'PROGRESS FILE ERROR',0
wallet_line: db 'SHRAPNELS: 00000',0

msg_exit0:  db 'M I N E S W E E P E R',0
msg_exit1:  db 'MINEFIELD SECURED. THANK YOU FOR SWEEPING.',0
msg_exit2:  db 'GRID TERMINATED - RETURNING TO DOS...',0