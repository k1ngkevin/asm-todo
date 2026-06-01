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


strstr:
; args
; rdi = haystack
; rsi = needle
; output
; rax = index of first occurance of needle in haystack, -1 if not found

  xor rax, rax

.outer_loop:
  cmp byte [rdi + rax], 0
  je .not_found
  
  lea rdx, [rdi + rax]
  xor rcx, rcx

.inner_loop:
  mov r8b, [rsi + rcx]
  cmp r8b, 0
  je .found

  mov r9b, [rdx + rcx]
  cmp r9b, 0
  je .not_found

  cmp r9b, r8b
  jne .next_outer

  inc rcx
  jmp .inner_loop

.next_outer:
  inc rax
  jmp .outer_loop

.found:
  ret

.not_found:
  mov rax, -1
  ret


strlen:
; args
; rdi = string
; output
; rax = length

xor rax, rax

.strlen_loop:
  cmp byte [rdi + rax], 0
  je .strlen_done
  inc rax
  jmp .strlen_loop

.strlen_done:
  ret
