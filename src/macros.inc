; -------------------------------------------------------------------
; Macros
; -------------------------------------------------------------------
%macro HIDEM 0
    mov ax,2
    int 33h
%endmacro

%macro SHOWM 0
    mov ax,1
    int 33h
%endmacro

; BEVEL raised(1)/sunken(0), x, y, w, h, faceColour
%macro BEVEL 6
    mov byte [BevFace],%6
  %if %1
    mov byte [BevTL],15
    mov byte [BevBR],8
  %else
    mov byte [BevTL],8
    mov byte [BevBR],15
  %endif
    mov ax,%2
    mov bx,%3
    mov cx,%4
    mov dx,%5
    call DrawBevel
%endmacro

; TXT row, col, colour, 'string'
%macro TXT 4
    jmp short %%skip
%%str: db %4,0
%%skip:
    mov dh,%1
    mov dl,%2
    mov bl,%3
    mov si,%%str
    call PrintAt
%endmacro
