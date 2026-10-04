; -------------------------------------------------------------------
; Permanent progression stored in MINESW.SAV in the DOS working folder.
; Save layout: "MSH1", Shrapnels (word), owned-class bits, equipped class.
; -------------------------------------------------------------------
LoadProgress:
    pusha
    mov word [Shrapnels],0
    mov byte [OwnedClasses],0
    mov byte [SelectedClass],0
    mov byte [ProgressError],0
    mov byte [LoadValid],0

    mov ax,3D00h                ; open existing save read-only
    mov dx,SaveFile
    int 21h
    jnc .opened
    cmp ax,2                    ; file not found is a first-time player
    je .done
    mov byte [ProgressError],1
    jmp .done

.opened:
    mov [SaveHandle],ax
    mov bx,ax
    mov cx,SAVE_SIZE
    mov dx,SaveBuffer
    mov ah,3Fh
    int 21h
    jc .readFailed
    cmp ax,SAVE_SIZE
    jne .readFailed
    mov byte [LoadValid],1
    jmp .close
.readFailed:
    mov byte [ProgressError],1
.close:
    mov bx,[SaveHandle]
    mov ah,3Eh
    int 21h
    jnc .closed
    mov byte [ProgressError],1
    mov byte [LoadValid],0
.closed:
    cmp byte [LoadValid],1
    jne .done

    cmp byte [SaveBuffer],'M'
    jne .invalid
    cmp byte [SaveBuffer+1],'S'
    jne .invalid
    cmp byte [SaveBuffer+2],'H'
    jne .invalid
    cmp byte [SaveBuffer+3],'1'
    jne .invalid
    mov al,[SaveBuffer+6]
    test al,0F8h
    jnz .invalid
    mov cl,[SaveBuffer+7]
    cmp cl,3
    ja .invalid
    or cl,cl
    jz .valid
    dec cl
    mov al,1
    shl al,cl
    test [SaveBuffer+6],al
    jz .invalid                ; equipped classes must be owned
.valid:
    mov ax,[SaveBuffer+4]
    mov [Shrapnels],ax
    mov al,[SaveBuffer+6]
    mov [OwnedClasses],al
    mov al,[SaveBuffer+7]
    mov [SelectedClass],al
    jmp .done
.invalid:
    mov byte [ProgressError],1
.done:
    popa
    ret

SaveProgress:
    pusha
    mov byte [ProgressError],0
    mov byte [SaveBuffer],'M'
    mov byte [SaveBuffer+1],'S'
    mov byte [SaveBuffer+2],'H'
    mov byte [SaveBuffer+3],'1'
    mov ax,[Shrapnels]
    mov [SaveBuffer+4],ax
    mov al,[OwnedClasses]
    mov [SaveBuffer+6],al
    mov al,[SelectedClass]
    mov [SaveBuffer+7],al

    mov dx,SaveFile
    xor cx,cx
    mov ah,3Ch                  ; create/truncate the save file
    int 21h
    jc .failed
    mov [SaveHandle],ax
    mov bx,ax
    mov cx,SAVE_SIZE
    mov dx,SaveBuffer
    mov ah,40h
    int 21h
    jc .writeFailed
    cmp ax,SAVE_SIZE
    jne .writeFailed
    jmp .close
.writeFailed:
    mov byte [ProgressError],1
.close:
    mov bx,[SaveHandle]
    mov ah,3Eh
    int 21h
    jc .failed
    jmp .done
.failed:
    mov byte [ProgressError],1
.done:
    popa
    ret
