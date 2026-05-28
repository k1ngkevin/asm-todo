strncmp: 
; args
; rdi = string1
; rsi = string2
; rdx = count
; output
; if equal rax = 1, not equal rax = 0

.compare_loop: 
  cmp rdx, 0
  je .equal

  mov rcx, rdx
  mov r10b, [rdi]
  mov r11b, [rsi]

  cmp r10b, r11b
  jne .not_equal 

  inc rdi
  inc rsi
  dec rdx
  jmp .compare_loop

.equal: 
  mov rax, 1
  ret

.not_equal:
  mov rax, 0
  ret

