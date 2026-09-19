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
    cmp word [Seconds],999
    jae .sec
    inc word [Seconds]
    mov bl,1
    jmp .sec
.chk:
    or bl,bl
    jz .done
    call DrawTimer
.done:
    popa
    ret
