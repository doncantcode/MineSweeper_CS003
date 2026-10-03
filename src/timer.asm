; -------------------------------------------------------------------
; Timer (BIOS ticks: 18.2/s -> 5 units per tick, 91 units per second)
; -------------------------------------------------------------------
UpdateTimer:
    pusha
    mov ah,00h
    int 1Ah
    mov ax,dx
    sub ax,[LastTick]
    jz .done
    mov [LastTick],dx
    cmp byte [KitMsgT],0        ; transient kit message timing
    je .noKitTick
    dec byte [KitMsgT]
    jnz .noKitTick
    call Redraw                 ; expired: restore the normal status
.noKitTick:
    push ax
    call MusicStep              ; AX = ticks elapsed
    pop ax
    cmp byte [TimerOn],0
    je .done
    mov bx,5
    mul bx
    add [TickAcc],ax
    xor bl,bl
.sec:
    cmp word [TickAcc],91
    jb .chk
    sub word [TickAcc],91
    ; Rapid mode counts down instead of up
    cmp byte [CurrentMode],2
    je .rapid

    ; Normal timer for Vanilla / other modes
    cmp word [Seconds],999
    jae .sec
    inc word [Seconds]
    mov bl,1
    jmp .sec

.rapid:
    cmp word [Seconds],0
    je .rapidTimeout

    dec word [Seconds]
    mov bl,1

    cmp word [Seconds],0
    je .rapidTimeout

    jmp .sec

.rapidTimeout:
    mov byte [GameOver],1
    mov byte [TimerOn],0
    mov word [HitCell],0FFFFh

    call RevealMines
    call Redraw

    mov si,SfxBoom
    call StartSfx

    jmp .done

.chk:
    or bl,bl
    jz .done
    call DrawTimer
.done:
    popa
    ret
