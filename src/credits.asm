; -------------------------------------------------------------------
; Credits screen: show_credits prints the team layout on the blue
; chrome (caller clears), waits for a silent keypress, returns.
; -------------------------------------------------------------------

show_credits:
    pusha
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
    mov si,msg_credits_frame
    mov dh,5
    call PrintA

    mov si,msg_credits_lead
    mov dh,7
    mov dl,18
    call PrintA
    mov si,msg_credits_ui
    mov dh,8
    call PrintA
    mov si,msg_credits_asm
    mov dh,9
    call PrintA

    mov si,msg_credits_frame
    mov dh,11
    mov dl,18
    call PrintA

    mov dh,13
    mov bl,17h
    mov si,msg_credits_key
    call PrintCRow
    call WaitKey
    popa
    ret

msg_credits_title: db 'C R E D I T S',0
msg_credits_frame: db '============================================',0
msg_credits_head:  db '  M I N E S W E E P E R  -  DOS EDITION   ',0
msg_credits_lead:  db ' LEAD DEVELOPER ...... DON DUCYOGEN        ',0
msg_credits_ui:    db ' UI DESIGNER ......... <ADD YOUR NAME>     ',0
msg_credits_asm:   db ' ASSEMBLY PROGRAMMER . FRANCIS FERNANDEZ   ',0
msg_credits_key:   db 'PRESS ANY KEY TO RETURN',0
