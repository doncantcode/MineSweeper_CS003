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

; -------------------------------------------------------------------
; Main Menu Music Player (PC speaker PIT channel 2, ports 42h/43h/61h)
; Uses track1 format: pairs of (PIT channel 2 divisor, duration in ms)
; 0 = rest, 0FFFFh = loop back to start.
; Steps in 10ms increments via INT 15h, AH=86h so the menu input loop
; remains completely responsive while playing.
; -------------------------------------------------------------------
PlayMenuMusicStep:
    pusha
    cmp byte [MenuMusicOn], 1
    jne .silence

    cmp word [MenuNoteLeft], 0
    jne .step_delay

.fetch_note:
    mov si, [MenuMusicPtr]
    mov bx, [si]
    cmp bx, 0FFFFh
    jne .valid_note
    mov si, track3
    mov bx, [si]
.valid_note:
    mov bp, [si+2]              ; duration ms
    add si, 4
    mov [MenuMusicPtr], si
    mov [MenuNoteLeft], bp

    test bx, bx
    jz .rest
    mov al, 0B6h
    out 43h, al
    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    jmp .step_delay

.rest:
    in al, 61h
    and al, 0FCh
    out 61h, al

.step_delay:
    cmp byte [TestMode], 1
    je .no_delay
    mov ah, 86h
    xor cx, cx
    mov dx, 10000               ; 10,000 us = 10 ms
    int 15h
.no_delay:
    cmp word [MenuNoteLeft], 10
    jbe .note_end
    sub word [MenuNoteLeft], 10
    jmp .done

.note_end:
    mov word [MenuNoteLeft], 0
    jmp .done

.silence:
    call SpeakerOff
    mov word [MenuNoteLeft], 0

.done:
    popa
    ret

; ToggleMenuMusic: toggles menu music on/off, silences speaker if off
ToggleMenuMusic:
    push ax
    xor byte [MenuMusicOn], 1
    cmp byte [MenuMusicOn], 1
    je .turned_on
    call SpeakerOff
    mov word [MenuNoteLeft], 0
    jmp .done
.turned_on:
    mov word [MenuMusicPtr], track3
    mov word [MenuNoteLeft], 0
.done:
    pop ax
    ret
