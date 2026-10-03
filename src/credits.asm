; -------------------------------------------------------------------
; Credits screen: show_credits prints the team layout on the blue
; chrome (caller clears), waits for a silent keypress, returns.
; -------------------------------------------------------------------

show_credits:
    pusha
    mov ch,2                    ; black stage for the whole roster
    mov dh,14
    mov bh,00h
    call Band
    mov dh,1
    mov bl,1Eh
    mov si,msg_credits_title
    call PrintCRow

    mov bl,1Fh                  ; framed block, column 18
    mov si,msg_credits_frame
    mov dh,3
    mov dl,18
    call PrintA
    mov si,msg_credits_head
    mov dh,4
    call PrintA
    mov si,msg_credits_course
    mov dh,5
    call PrintA
    mov si,msg_credits_div
    mov dh,6
    call PrintA

    mov si,msg_credits_mem1
    mov dh,7
    mov dl,18
    call PrintA
    mov si,msg_credits_mem2
    mov dh,8
    call PrintA
    mov si,msg_credits_mem3
    mov dh,9
    call PrintA
    mov si,msg_credits_mem4
    mov dh,10
    call PrintA
    mov si,msg_credits_mem5
    mov dh,11
    call PrintA
    mov si,msg_credits_mem6
    mov dh,12
    call PrintA

    mov si,msg_credits_frame
    mov dh,13
    mov dl,18
    call PrintA

    mov dh,16
    mov bl,17h
    mov si,msg_credits_key
    call PrintCRow
    call WaitKey
    popa
    ret

msg_credits_title:  db 'C R E D I T S',0
msg_credits_frame:  db '============================================',0
msg_credits_head:   db '  M I N E S W E E P E R  -  DOS EDITION   ',0
msg_credits_course: db '  CS 003: COMPUTER ARCH & ORGANIZATION    ',0
msg_credits_div:    db '--------------------------------------------',0
msg_credits_mem1:   db '  - BEJENO, JOSEPH FILBERT R.             ',0
msg_credits_mem2:   db '  - CABUNOT, RHIANA DENISE D.             ',0
msg_credits_mem3:   db '  - DUCYOGEN, DON L.                      ',0
msg_credits_mem4:   db '  - SEPICO, PATRICK MARCO C.              ',0
msg_credits_mem5:   db '  - VILLAFLOR, MARK JIRHO S.              ',0
msg_credits_mem6:   db '  - YBANEZ, JAMES ALDRED V.               ',0
msg_credits_key:    db 'PRESS ANY KEY TO RETURN',0
