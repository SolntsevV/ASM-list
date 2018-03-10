section .rodata
msg_noword: db "Not found key",0
msg_nofile: db "Not found file",0

section .data

file: db "words.txt", 0
a_key: dq 0, 0
a_word: dq 0, 0
lw: dq 0
input: dq "empty", 0

    
section .text
global _start

_start:
  mov r15, 0
	lea rbx, [rsp + 16] ; получили второй аргумент командной строки (название файла)
	mov rdi, [rbx]
	test rdi, rdi ; если файла название файла нет, то выходим
	jz .not_file
	call open_file ; открыть файл и сделать mmap в rax

	;-------------------------
	lea rbx, [rax]
	mov r10, 0
.main_loop:
	xor rdx, rdx ;
	lea rcx, [a_key]
.loop:
	cmp byte [rbx], 0
	jz .list_fine
	cmp byte [rbx], ":" ; если дошли до конца ключа
	jz .key_fine
	cmp byte [rbx], 0xA ; если дошли до конца значения
	jz .word_fine
	mov rdx, [rbx]
	mov [rcx], rdx
	inc rcx
	inc rbx
	jmp .loop
.key_fine:
	mov byte [rcx], 0; добавление окончания строки
	lea rcx, [a_word]
	inc rbx
	xor rdx, rdx
	jmp .loop
.word_fine:
	mov byte [rcx], 0; добавление окончания строки
	inc rbx
	;---------------------------
	push r10
	mov r10, rsp
	push qword[a_key]
	push qword[a_word]
	;----------------------------
	jmp .main_loop
.list_fine:
	mov byte [rcx], 0
	push r10
	mov r10, rsp
	push qword[a_key]
	push qword[a_word]
.end:
	mov rdi, input
	call read_word
	mov rdi, input
	mov rsi, r10
	call find_word

	test rax, rax
	jz .bad
	sub rax, 16
	mov rdi, rax
	call print_string
	call print_newline
	mov rdi, 0
	call exit	
	
.bad:
	mov rdi, msg_noword
	call print_error
	call print_newline

	mov rdi, 0
	call exit	
	
.not_file:
	call exit
	
;###########################

find_word: 
	xor eax, eax
.loop:
	push rsi
	push rdi
	sub rsi, 8
	call string_equals
	pop rdi
	pop rsi
	test rax, rax
	jnz .is_found
	mov r11, [rsi]
	test r11, r11
	jz .end
	mov rsi, [rsi]
  

  jmp .loop
.is_found:

	mov rax, rsi
.end: 
	ret
	
	
;################################################################
	
string_length:
    xor rax, rax
  .loop:
    cmp byte [rdi], 0
    jz .exit
    inc rax
    inc rdi
    jmp .loop
  .exit:
    ret


print_string:
    mov rsi, rdi
    call string_length
    mov rdx, rax
    mov rdi, 1
    mov rax, 1
    syscall
    ret
	
print_char:
    push rdi
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    mov rdx, 1
    syscall
    pop rax
    ret


print_newline:
    mov rdi, 0xA
    call print_char
    ret

print_error:
  push rdi
  call string_length
  pop rsi
  mov rdx, rax 
  mov rax, 1
  mov rdi, 2 
  syscall
  ret
	
read_char: 
	push 0 
	xor rax, rax 
	xor rdi, rdi 
	mov rsi, rsp 
	mov rdx, 1 
	syscall 
	pop rax 
	ret


read_word:  
    xor r9, r9

  .first_char_test: 
    push rdi 
    call read_char 
    pop rdi 

    cmp al, ' '
    jz .first_char_test 
    cmp al, 10  
    je .first_char_test 
    cmp al, 13 
    je .first_char_test 
    cmp al, 9 
    je .first_char_test 
    
  .loop: 
    mov byte [rdi + r9], al 
    inc r9 

    push rdi 
    call read_char 
    pop rdi 
    cmp al, ' ' 
    je .end_char 
    cmp al, 10 
    je .end_char 
    cmp al, 13 
    je .end_char 
    cmp al, 9
    je .end_char
    test al, al 
    jz .end_char 
    
    jmp .loop 

  .end_char: 
    mov byte [rdi + r9], 0 
    mov rax, rdi 
    
    ret
  
 string_equals: 
	mov al, byte [rdi] 
	cmp al, byte [rsi]  
	jne .no 
	inc rdi 
	inc rsi 
	cmp al, 0 
	jnz	string_equals 
	mov rax, 1
	ret 
.no: 
	xor rax, rax 
	ret
  
exit:
    mov rax, 60
    syscall
	
open_file:
	mov rax, 2 ; открыть файл
	;mov rdi, fname ; название файла
	mov rsi, 0 ; только на чтение
	mov rdx, 0 ; int mode = 0
	syscall
	
; mmap
	mov r8, rax           ; rax содержит открый файловый дескриптор
	mov rax, 9            ; номер системного вызова
	mov rdi, 0            ; операционная система выберет назначение отображения
	mov rsi, 4096         ; размер страницы 
	mov rdx, 0x1    	; новая область памяти будет отмечена только для чтения 
	mov r10, 0x2	  	; страницы не будут доступны
	
	mov r9, 0             ; Смещение внутри файла 
	syscall               ; rax указывает на первый элемент в файле
	ret



	
	
