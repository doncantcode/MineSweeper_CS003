; -------------------------------------------------------------------
; Permanent progression stored in MINESW.SAV in the DOS working folder.
; Save layout: "MSH1", Shrapnels (word), owned-class bits, equipped class,
;              PotionOracle, PotionRadar, PotionDetector, CurrentLevel,
;              UnlockedLevel (13th byte; older 12-byte saves still load)
; The Tank is free, so it is always marked as owned.
; -------------------------------------------------------------------
LoadProgress:
    pusha
    mov word [Shrapnels],0
    mov byte [OwnedClasses],0
    mov byte [SelectedClass],0
    mov byte [PotionOracle],0
    mov byte [PotionRadar],0
    mov byte [PotionDetector],0
    mov byte [CurrentLevel],1
    mov byte [UnlockedLevel],1
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
    cmp ax,8                    ; at least 8 bytes required
    jb .readFailed
    mov [LoadValid],al          ; number of bytes read
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
    cmp byte [LoadValid],0
    je .done

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
    jnz .valid
    mov byte [SaveBuffer+7],0   ; equipped but not owned: just unequip it
.valid:
    mov ax,[SaveBuffer+4]
    mov [Shrapnels],ax
    mov al,[SaveBuffer+6]
    mov [OwnedClasses],al
    mov al,[SaveBuffer+7]
    mov [SelectedClass],al
    cmp byte [LoadValid],12
    jb .defaults
    mov si,SaveBuffer+8         ; potions, clamped to the carry limit
    mov di,PotionOracle
    call .loadPotion
    mov di,PotionRadar
    call .loadPotion
    mov di,PotionDetector
    call .loadPotion
    cmp byte [LoadValid],SAVE_SIZE
    jb .noUnlockByte
    mov al,[SaveBuffer+12]      ; unlocked Endless level, 1..MAX_LEVEL+1
    or al,al
    jz .noUnlockByte
    cmp al,MAX_LEVEL+1
    jbe .unlockOk
    mov al,MAX_LEVEL+1
.unlockOk:
    mov [UnlockedLevel],al
.noUnlockByte:
    mov al,[SaveBuffer+11]
    or al,al
    jz .defaults
    mov [CurrentLevel],al
    jmp .done
.defaults:
    mov byte [PotionOracle],0
    mov byte [PotionRadar],0
    mov byte [PotionDetector],0
    mov byte [CurrentLevel],1
    jmp .done
.invalid:
    mov byte [ProgressError],1
.done:
    or byte [OwnedClasses],1    ; Tank: free for everyone
    popa
    ret

.loadPotion:                    ; [SI] -> [DI], max POTION_MAX; SI++
    lodsb
    cmp al,POTION_MAX
    jbe .potOk
    mov al,POTION_MAX
.potOk:
    mov [di],al
    ret

SaveProgress:
    pusha
    cmp byte [TestMode],0       ; the self-test must never touch the
    jne .done                   ; player's real save file
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
    mov al,[PotionOracle]
    mov [SaveBuffer+8],al
    mov al,[PotionRadar]
    mov [SaveBuffer+9],al
    mov al,[PotionDetector]
    mov [SaveBuffer+10],al
    mov al,[CurrentLevel]
    mov [SaveBuffer+11],al
    mov al,[UnlockedLevel]
    mov [SaveBuffer+12],al

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
