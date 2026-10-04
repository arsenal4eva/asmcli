BITS 16
ORG 0x7C00

KERNEL_LOAD_SEG EQU 0x0000
KERNEL_LOAD_OFF EQU 0x7E00
KERNEL_START_LBA EQU 1          
KERNEL_SECTORS  EQU 63

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [boot_drive], dl

    mov dx, 0x3F8+3
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8
    mov al, 0x01            
    out dx, al
    mov dx, 0x3F8+1
    xor al, al
    out dx, al
    mov dx, 0x3F8+3
    mov al, 0x03            
    out dx, al

    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFF
    mov dl, [boot_drive]
    xor dh, dh              
    xor ch, ch              
    mov cl, 2              
    mov al, KERNEL_SECTORS
    mov ah, 0x02
    int 0x13
    jnc .loaded
    mov dx, 0x3F8
.wait: push dx
    add dx, 5
    in al, dx
    pop dx
    test al, 0x20
    jz .wait
    mov al, '!'
    out dx, al
    hlt
    jmp $
.loaded:
    jmp KERNEL_LOAD_SEG:KERNEL_LOAD_OFF

boot_drive: db 0

    times 510-($-$$) db 0
    dw 0xAA55
