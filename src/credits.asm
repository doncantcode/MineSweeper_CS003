; -------------------------------------------------------------------
; Credits screen: show_credits clears nothing itself (caller clears),
; prints the team layout, waits for a silent keypress, returns.
; -------------------------------------------------------------------

show_credits:
    pusha
    mov bl,0Fh
    mov si,msg_credits_title
    call PrintAttr
    call Crlf
    call Crlf
    mov si,msg_credits_layout
    call PrintStr
    mov bl,07h
    mov si,msg_credits_key
    call PrintAttr
    call WaitKey
    popa
    ret

msg_credits_title: db 'C R E D I T S',0

msg_credits_layout:
    db 13,10
    db ' ==========================================',13,10
    db '    M I N E S W E E P E R  -  DOS EDITION',13,10
    db ' ==========================================',13,10
    db 13,10
    db '   LEAD DEVELOPER ...... DON DUCYOGEN',13,10
    db 13,10
    db '   UI DESIGNER ......... <ADD YOUR NAME>',13,10
    db 13,10
    db '   ASSEMBLY PROGRAMMER . FRANCIS FERNANDEZ',13,10
    db 13,10
    db ' ==========================================',13,10
    db '$'

msg_credits_key: db 'PRESS ANY KEY TO RETURN',0
