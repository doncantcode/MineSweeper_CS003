; -------------------------------------------------------------------
; Sound engine: one-shot effects (SfxBoom / SfxWin) on the PC speaker
; (PIT channel 2, port 61h gate).  An effect takes the speaker over,
; stopping the music, and the tune picks up again from Riff 1 when the
; effect has finished.  Song and effect entries share one format:
; (frequency Hz, ticks); 0 Hz = rest; 0FFFFh = loop back / stop.
; -------------------------------------------------------------------
MusicStep:                      ; AX = BIOS ticks since last call
    pusha
    cmp byte [SfxOn],0
    je .music
    mov bx,[SfxLeft]            ; --- effect playing ---
    cmp ax,bx
    jb .sfxhold
    call SfxAdvance             ; effect note finished -> next one
    jmp .done
.sfxhold:
    sub bx,ax
    mov [SfxLeft],bx
    cmp bx,1
    ja .done
    call SpeakerOff             ; last tick of an effect note
    jmp .done

.music:
    cmp byte [MusicOn],0
    je .done
    mov bx,[NoteLeft]
    cmp ax,bx
    jae .next                   ; current note finished
    sub bx,ax
    mov [NoteLeft],bx
    cmp bx,1
    ja .done
    call SpeakerOff             ; last tick of a note = short gap
    jmp .done
.next:
    mov si,[MusicPtr]
    mov bx,[si]
    cmp bx,0FFFFh
    jne .play
    mov si,SongTable            ; end of tune -> loop
    mov bx,[si]
.play:
    mov ax,[si+2]
    mov [NoteLeft],ax
    add si,4
    mov [MusicPtr],si
    or bx,bx
    jz .rest
    call SpeakerOn
    jmp .done
.rest:
    call SpeakerOff
.done:
    popa
    ret

; Pull the next entry of the running effect.  When the table ends the
; effect is over and the tune restarts from Riff 1 (unless muted).
SfxAdvance:
    pusha
    mov si,[SfxPtr]
    mov bx,[si]
    cmp bx,0FFFFh
    je .end
    mov ax,[si+2]
    mov [SfxLeft],ax
    add si,4
    mov [SfxPtr],si
    or bx,bx
    jz .rest
    call SpeakerOn
    popa
    ret
.rest:
    call SpeakerOff
    popa
    ret
.end:
    mov byte [SfxOn],0
    mov word [NoteLeft],0
    mov si,SongTable
    mov [MusicPtr],si
    popa
    ret

; Start effect whose table address is in SI (music is silenced first)
StartSfx:
    push bx
    push si
    call SpeakerOff
    mov [SfxPtr],si
    mov byte [SfxOn],1
    call SfxAdvance
    pop si
    pop bx
    ret

ToggleMusic:
    xor byte [MusicOn],1
    mov word [NoteLeft],0
    cmp byte [MusicOn],0
    jne .r
    mov byte [SfxOn],0
    call SpeakerOff
.r:
    ret
