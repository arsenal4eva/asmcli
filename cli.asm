section .data
	prompt		db "> ", 0
	prompt_len	equ $ - prompt - 1

	banner		db 13,10,"asm cli",13,10
				db "type 'help' for commands",13,10,0
	banner_len	equ $ - banner - 1

	help_msg	db 13,10,"commands: help | echo <txt> | clear | exit",13,10,0
	help_len	equ $ - help_msg - 1

	unknown_msg db "?",13,10,0
	unknown_len	equ $ - unknown_msg - 1

	bye_msg		db "bye",13,10,0
	bye_len		equ $ - bye_msg - 1

	cls_seq		db 27,"[2J",27,"[H",0
	cls_len		equ $ - cls_seq - 1

	nl			db 13,10,0
	nl_len		equ $ - nl - 1

	cmd_help	db "help",0
	cmd_echo	db "echo",0
	cmd_clear	db "clear",0
	cmd_exit	db "exit",0

section .bss
	buf resb 128

section .text
	global _start

print:
	mov rax, 1
	mov rdi, 1
	syscall
	ret

strlen:
	xor rax, rax
.strlen_loop:
	cmp byte [rsi+rax], 0
	je .strlen_done
	inc rax
	jmp .strlen_loop
.strlen_done:
	ret

strcmp:
	xor rax, rax
.cmp_loop:
	mov al, [rsi]
	mov cl, [rdi]
	cmp al, cl
	jne .not_equal
	test al, al
	jz .equal
	inc rsi
	inc rdi
	jmp .cmp_loop
.equal:
	xor eax, eax
	ret
.not_equal:
	mov eax, 1
	ret

starts_with:
	push rbx
	mov rdx, rsi
.sw_loop:
	mov al, [rdi]
	test al, al
	jz .sw_yes
	mov bl, [rsi]
	cmp al, bl
	jne .sw_no
	inc rsi
	inc rdi
	jmp .sw_loop
.sw_yes:
	mov rdx, rsi
	xor eax, eax
	pop rbx
	ret
.sw_no:
	mov eax, 1
	pop rbx
	ret

_start:
	mov rsi, banner
	mov rdx, banner_len
	call print

.repl:
	mov rsi, prompt
	mov rdx, prompt_len
	call print

	mov rax, 0
	mov rdi, 0
	mov rsi, buf
	mov rdx, 128
	syscall
	cmp rax, 0
	jle .do_exit
	mov r12, rax

	lea rdi, [buf]
	mov rcx, 12
.trunc:
	test rcx, rcx
	jz.terminated
	mov al, [rdi]
	cmp al, 10
	je .cut
	cmp al, 13
	je .cut
	inc rdi
	dec rcx
	jmp .trunc
.cut:
	mov byte [rdi], 0
.terminated:
	mov byte [buf+r12], 0
	lea rsi, [buf]
.skip_sp:
	mov al, [rsi]
	cmp al, ' '
	jne .dispatch
	inc rsi
	jmp .skip_sp

.dispatch:
	cmp byte [rsi], 0
	je .repl

	push rsi
	lea rdi, [cmd_help]
	call strcmp
	pop rsi
	test eax, eax
	jz .do_help

	push rsi
	lea rdi, [cmd_exit]
	call strcmp
	pop rsi
	test eax, eax
	jz .do_exit

	push rsi
	lea rdi, [cmd_clear]
	call strcmp
	pop rsi
	test eax, eax
	jz .do_clear

	lea rdi, [cmd_echo]
	call starts_with
	test eax, eax
	jz .do_echo

	mov rsi, unknown_msg
	mov rdx, unknown_len
	call print
	jmp .repl

.do_help:
	mov rsi, help_msg
	mov rdx, help_len
	call print
	jmp .repl

.do_clear:
	mov rsi, cls_seq
	mov rdx, cls_len
	call print
	jmp .repl

.do_echo:
	mov rsi, rdx
	cmp byte [rsi], ' '
	jne .echo_print
	inc rsi
.echo_print:
	call strlen
	mov rdx, rax
	call print
	mov rsi, nl
	mov rdx, nl_len
	call print
	jmp .repl

.do_exit:
	mov rsi, bye_msg
	mov rdx, bye_len
	call print
	mov rax, 60
	xor rdi, rdi
	syscall
