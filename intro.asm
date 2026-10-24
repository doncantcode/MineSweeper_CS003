; intro.asm - MINESWEEPER DOS EDITION intro (80x25 text mode, blue scheme)
; build: nasm -f bin intro.asm -o intro.com      run: DOSBox -> intro.com
cpu 186
org 100h
 
start:
    cld
    mov ax,3                ; 80x25 text
    int 10h
    mov ah,1
    mov cx,2000h
    int 10h                 ; hide cursor
    push 0B800h
    pop es                  ; ES = text video memory
.fl:mov ah,1                ; flush keyboard buffer
    int 16h
    jz .fd
    xor ah,ah
    int 16h
    jmp .fl
.fd:
    mov ax,1720h            ; blue background
    xor di,di
    mov cx,2000
    rep stosw
 
    mov cx,150              ; scatter numbers and mines
.sc:
    push cx
    call rnd
    xor dx,dx
    mov bx,2000
    div bx
    mov di,dx
    shl di,1
    call rnd
    xor dx,dx
    mov bx,9
    div bx
    mov si,dx
    mov al,[digs+si]
    mov [tmpc],al
    call rnd
    xor dx,dx
    mov bx,6
    div bx
    mov si,dx
    mov ah,[cols+si]
    mov al,[tmpc]
    mov [es:di],ax
    pop cx
    loop .sc
 
    mov ax,0720h            ; black box interior
    mov dh,4
    mov dl,4
    mov ch,10
    mov cl,72
    call rect
    mov ax,03CDh            ; top / bottom border
    mov dh,3
    mov dl,4
    mov ch,1
    mov cl,72
    call rect
    mov dh,14
    call rect
    mov ax,03BAh            ; left / right border
    mov dh,4
    mov dl,3
    mov ch,10
    mov cl,1
    call rect
    mov dl,76
    call rect
    mov ax,03C9h
    mov dh,3
    mov dl,3
    call putch
    mov ax,03BBh
    mov dl,76
    call putch
    mov ax,03C8h
    mov dh,14
    mov dl,3
    call putch
    mov ax,03BCh
    mov dl,76
    call putch
 
    mov si,deco             ; -=<<< * >>>=-
    mov dh,11
    mov dl,33
    mov ah,03h
    call puts
    mov ax,0F2Ah
    mov dl,39
    call putch
    mov si,dos
    mov dh,12
    mov dl,29
    mov ah,0Bh
    call puts
 
    xor bx,bx               ; numbers 1..8
.nm:
    mov al,'1'
    add al,bl
    mov ah,[ncol+bx]
    mov dh,13
    mov dl,bl
    shl dl,1
    add dl,32
    call putch
    inc bl
    cmp bl,8
    jb .nm
 
    mov ax,7020h            ; status bar
    mov dh,24
    xor dl,dl
    mov ch,1
    mov cl,80
    call rect
    mov si,stl
    mov dh,24
    mov dl,1
    mov ah,70h
    call puts
    mov si,str_
    mov dl,75
    call puts
 
    mov ax,1720h            ; clear text area
    mov dh,18
    mov dl,24
    mov ch,6
    mov cl,32
    call rect
 
main:
    call vsync
    mov ah,1                ; any key -> exit
    int 16h
    jnz exit
 
    test byte [fr],3        ; scroll checker bars
    jnz .nc
    inc byte [ph]
    cmp byte [ph],6
    jb .ph
    mov byte [ph],0
.ph:
    mov dh,1
    mov bl,[ph]
    call checker
    mov dh,16
    mov bl,5
    sub bl,[ph]
    call checker
.nc:
    mov ax,[fr]             ; reveal one letter every 8 frames
    sub ax,30
    jb .nr
    test al,7
    jnz .nr
    shr ax,3
    cmp al,[nlet]
    jne .nr
    cmp al,11
    jae .nr
    call drawletter
    inc byte [nlet]
.nr:
    cmp byte [nlet],11      ; shimmer once fully revealed
    jb .ns
    test byte [fr],3
    jnz .ns
    inc byte [shim]
    xor cl,cl
.sh:mov al,cl
    call drawletter
    inc cl
    cmp cl,11
    jb .sh
.ns:
    cmp word [fr],140
    jne .t1
    mov si,s1
    mov dh,19
    mov dl,29
    mov ah,1Bh
    call puts
.t1:
    cmp word [fr],190
    jne .t2
    mov si,s2
    mov dh,20
    mov dl,31
    mov ah,1Fh
    call puts
.t2:
    cmp word [fr],240       ; blinking prompt
    jb .nb
    test byte [fr],31
    jnz .nb
    xor byte [bk],1
    mov ah,1Fh
    cmp byte [bk],0
    je .a
    mov ah,19h
.a: mov si,s3
    mov dh,22
    mov dl,27
    call puts
.nb:
    inc word [fr]
    jmp main
 
exit:
    xor ah,ah
    int 16h
    mov ax,3
    int 10h
    mov ax,4C00h
    int 21h
 
; putch: AL=char AH=attr DH=row DL=col (all registers preserved)
putch:
    push ax
    push bx
    push di
    mov bx,ax
    xor ax,ax
    mov al,dh
    mov di,ax
    shl di,4
    shl ax,6
    add di,ax
    xor ax,ax
    mov al,dl
    add di,ax
    shl di,1
    mov [es:di],bx
    pop di
    pop bx
    pop ax
    ret
 
; puts: DS:SI zero-terminated string, AH=attr DH=row DL=col
puts:
    push ax
    push dx
    push si
.n: mov al,[si]
    or al,al
    jz .d
    call putch
    inc si
    inc dl
    jmp .n
.d: pop si
    pop dx
    pop ax
    ret
 
; rect: AX=char/attr DH=row DL=col CH=height CL=width
rect:
    push bx
    push cx
    push dx
    mov bh,cl
.r: mov bl,bh
    push dx
.c: call putch
    inc dl
    dec bl
    jnz .c
    pop dx
    inc dh
    dec ch
    jnz .r
    pop dx
    pop cx
    pop bx
    ret
 
; checker: DH=row BL=phase  (grey/blue squares, 3 cells each)
checker:
    pusha
    xor dl,dl
.l: mov al,dl
    add al,bl
.m: cmp al,6
    jb .o
    sub al,6
    jmp .m
.o: cmp al,3
    mov ah,08h
    jb .p
    mov ah,09h
.p: mov al,0DBh
    call putch
    inc dl
    cmp dl,80
    jb .l
    popa
    ret
 
; drawletter: AL = letter 0..10 of MINESWEEPER (shadow pass, then gradient pass)
drawletter:
    pusha
    mov bl,al
    xor bh,bh
    mov al,[tidx+bx]
    mov ah,5
    mul ah
    add ax,glyphs
    mov si,ax
    mov al,bl
    mov ah,6
    mul ah
    add al,7
    mov [c0],al
    mov byte [pass],0
.pass:
    xor di,di
.row:
    mov bx,si
    add bx,di
    mov bl,[bx]
    mov ax,di
    add al,[shim]
    and ax,7
    push bx
    mov bx,ax
    mov al,[ring+bx]
    mov [rattr],al
    pop bx
    mov bh,0
.bit:
    test bl,10h
    jz .skip
    mov dl,[c0]
    add dl,bh
    mov ax,di
    add al,5
    mov dh,al
    cmp byte [pass],0
    jne .main
    inc dh
    inc dl
    mov ax,08B0h            ; shadow
    jmp .put
.main:
    mov ah,[rattr]
    mov al,0DBh
.put:
    call putch
.skip:
    shl bl,1
    inc bh
    cmp bh,5
    jb .bit
    inc di
    cmp di,5
    jb .row
    inc byte [pass]
    cmp byte [pass],2
    jb .pass
    popa
    ret
 
rnd:
    push dx
    mov ax,[seed]
    mov dx,25173
    mul dx
    add ax,13849
    mov [seed],ax
    pop dx
    ret
 
vsync:
    mov dx,3DAh
.a: in al,dx
    test al,8
    jnz .a
.b: in al,dx
    test al,8
    jz .b
    ret
 
fr    dw 0
seed  dw 1234h
ph    db 0
nlet  db 0
shim  db 0
bk    db 1
pass  db 0
c0    db 0
rattr db 0
tmpc  db 0
digs  db '12345678*'
cols  db 17h,17h,19h,1Bh,13h,1Fh
ncol  db 07h,07h,0Bh,0Fh,09h,09h,03h,0Fh
ring  db 0Fh,0Bh,03h,09h,01h,09h,03h,0Bh
tidx  db 0,1,2,3,4,5,3,3,6,3,7      ; M I N E S W E E P E R
glyphs:                             ; M I N E S W P R, 5 rows of 5 bits
    db 11h,1Bh,15h,11h,11h
    db 1Fh,04h,04h,04h,1Fh
    db 11h,19h,15h,13h,11h
    db 1Fh,10h,1Eh,10h,1Fh
    db 0Fh,10h,0Eh,01h,1Eh
    db 11h,11h,15h,1Bh,11h
    db 1Eh,11h,1Eh,10h,10h
    db 1Eh,11h,1Eh,12h,11h
deco  db '-=<<< * >>>=-',0
dos   db 'D O S   E D I T I O N',0
stl   db 'MINESWEEPER - DOS EDITION',0
str_  db 'V1.0',0
s1    db 'SCANNING GRID FIELD...',0
s2    db '10 MINES LOCATED!',0
s3    db 'PRESS ANY KEY TO CONTINUE',0
