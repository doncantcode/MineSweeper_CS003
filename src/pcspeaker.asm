; -------------------------------------------------------------------
; PC speaker hardware driver: PIT channel 2 (ports 42h/43h) plus the
; port 61h gate.  SpeakerOn takes the frequency in Hz in BX.
;
; This is the only module that touches the speaker hardware; the
; sequencing logic in audio.asm is written against these two calls.
; -------------------------------------------------------------------
SpeakerOn:
    mov dx,0012h
    mov ax,34DEh                ; DX:AX = 1193182 (PIT clock)
    div bx                      ; AX = PIT divisor
    mov bx,ax
    mov al,0B6h                 ; channel 2, lo/hi, square wave
    out 43h,al
    mov al,bl
    out 42h,al
    mov al,bh
    out 42h,al
    in al,61h
    or al,3                     ; gate + speaker on
    out 61h,al
    ret

SpeakerOff:
    in al,61h
    and al,0FCh
    out 61h,al
    ret
