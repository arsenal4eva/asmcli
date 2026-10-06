BITS 16
ORG 0x7E00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, banner
    call print_str
repl:
    mov si, prompt
    call print_str
    call read_line
    mov si, buf
    call skip_spaces
    cmp byte [si], 0
    je repl
    mov di, cmd_help
    call strcmp
    jc do_help
    mov si, buf
    call skip_spaces
    mov di, cmd_exit
    call strcmp
    jc do_exit
    mov si, buf
    call skip_spaces
    mov di, cmd_clear
    call strcmp
    jc do_clear
    mov si, buf
    call skip_spaces
    mov di, cmd_echo
    call starts_with
    jc do_echo
    mov si, unknown_msg
    call print_str
    jmp repl

do_help:
    mov si, help_msg
    call print_str
    jmp repl
do_clear:
    call bios_clear
    jmp repl
do_echo:
    cmp byte [si], 0
    je echo_nl_only
    cmp byte [si], ' '
    jne unknown_cmd
    call skip_spaces
echo_print:
    call print_str
echo_nl_only:
    mov si, nl
    call print_str
    jmp repl
unknown_cmd:
    mov si, unknown_msg
    call print_str
    jmp repl
do_exit:
    mov si, bye_msg
    call print_str
    mov dx, 0xf4
    xor al, al
    out dx, al
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    mov al, 0xFE
    out 0x64, al
    int 0x19
    cli
.hang:
    hlt
    jmp .hang


putc:                   
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    pop bx
    pop ax
    ret

getc:                   
    xor ah, ah
    int 0x16
    ret

bios_clear:
    push ax
    mov ax, 0x0003
    int 0x10
    pop ax
    ret

print_str:              
    push ax
    push bx
    push si
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret

read_line:
    push ax
    push bx
    push di
    mov di, buf
    xor bx, bx
.loop:
    call getc
    cmp al, 13
    je .done
    cmp al, 10
    je .done
    cmp al, 8
    je .bs
    cmp bx, 127
    jae .loop
    mov [di], al
    inc di
    inc bx
    call putc
    jmp .loop
.bs:
    test bx, bx
    jz .loop
    dec di
    dec bx
    push ax
    mov al, 8
    call putc
    mov al, ' '
    call putc
    mov al, 8
    call putc
    pop ax
    jmp .loop
.done:
    mov byte [di], 0
    mov si, nl
    call print_str
    mov si, buf
    pop di
    pop bx
    pop ax
    ret

skip_spaces:
.skip:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp .skip
.done:
    ret

strcmp:                 
    push si
    push di
    push ax
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .no
    test al, al
    jz .yes
    inc si
    inc di
    jmp .loop
.yes:
    stc
    jmp .out
.no:
    clc
.out:
    pop ax
    pop di
    pop si
    ret

starts_with:            
    push ax
.loop:
    mov al, [di]
    test al, al
    jz .yes
    cmp al, [si]
    jne .no
    inc si
    inc di
    jmp .loop
.yes:
    stc
    jmp .out
.no:
    clc
.out:
    pop ax
    ret

prompt      db 13,10,"> ",0
banner      db 13,10,"asm cli (bios)",13,10,"type 'help' for commands",13,10,0
help_msg    db 13,10,"commands: help | echo <txt> | clear | exit",13,10,0
unknown_msg db "?",13,10,0
bye_msg     db "bye",13,10,0
nl          db 13,10,0
cmd_help    db "help",0
cmd_echo    db "echo",0
cmd_clear   db "clear",0
cmd_exit    db "exit",0

buf: times 128 db 0
