%include "constants.inc"
%include "syscalls.inc"
%include "utils.inc"

request_buffer_len equ 4096
TODO_CAP equ 100
TODO_SIZE equ 256

section .bss
request_buffer resb request_buffer_len
todo_buffer resb TODO_CAP * TODO_SIZE
index_buffer resb 20
db_byte resb 1

section .data

todo_index dq 0
todo_db_filename db "todo.db", 0

msg db "Server Running", 10     ; add port number as well
msg_len equ $ - msg
error_msg db "An unexpected error occured", 10
error_msg_len equ $ - error_msg

get db "GET "
get_len equ $ - get
post_add db "POST /add"
post_add_len equ $ - post_add
post_delete db "POST /delete"
post_delete_len equ $ - post_delete
post_quit db "POST /quit "
post_quit_len equ $ - post_quit

body_separator db 13, 10, 13, 10, 0

li_start db "<li>", 10
li_start_len equ $ - li_start

li_delete_before_index:
 db  '<form method="POST" action="/delete" style="display:inline">', 10
 db     '<input type="hidden" name="index" value="'

li_delete_before_index_len equ $ - li_delete_before_index

li_delete_after_index:
 db     '">', 10
 db     '<button type="submit">X</button>', 10
 db  '</form>', 10
 db '</li>', 10

li_delete_after_index_len equ $ - li_delete_after_index

response_header:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: text/html", 13, 10
    db "Connection: close", 13, 10
    db 13, 10

response_header_len equ $ - response_header

response_body_before_task_list:
    db '<html lang="en">', 10
    db '<head>', 10
    db '  <meta charset="UTF-8" />', 10
    db '  <meta name="viewport" content="width=device-width, initial-scale=1.0" />', 10
    db '  <title>Todo</title>', 10
    db '</head>', 10
    db '<body>', 10
    db '  <h1>TODO list in assembly</h1>', 10
    db '  <form method="POST" action="/add">', 10
    db '    <input type="text" name="task" />', 10
    db '    <button type="submit">Add</button>', 10
    db '  </form>', 10

response_body_before_task_list_len equ $ - response_body_before_task_list

response_task_list_start:
    db '  <ul>', 10

response_task_list_start_len equ $ - response_task_list_start

response_task_list_end:
    db '  </ul>', 10

response_task_list_end_len equ $ - response_task_list_end

response_body_after_task_list:
    db '  <form method="POST" action="/quit">', 10
    db '    <button type="submit">Quit Server</button>', 10
    db '  </form>', 10
    db '</body>', 10
    db '</html>', 10

response_body_after_task_list_len equ $ - response_body_after_task_list

reuseaddr_opt dd 1

servaddr:
  istruc sockaddr_in
    at sockaddr_in.sin_family, dw AF_INET
    at sockaddr_in.sin_port, dw 0xB80B    ; port 3000 in big endian format
    at sockaddr_in.sin_addr, dd INADDR_ANY
    at sockaddr_in.sin_zero, dq 0
  iend


section .text
global _start

_start:
  SYSCALL3 SYS_SOCKET, AF_INET, SOCK_STREAM, 0
  test rax, rax
  js error
  mov r12, rax

  SYSCALL5 SYS_SETSOCKOPT, r12, SOL_SOCKET, SO_REUSEADDR, reuseaddr_opt, 4

  SYSCALL3 SYS_BIND, r12, servaddr, sockaddr_in_size
  test rax, rax
  js error_and_close

  SYSCALL2 SYS_LISTEN, r12, 10
  test rax, rax
  js error_and_close

  SYSCALL3 SYS_WRITE, 1, msg, msg_len

  SYSCALL3 SYS_OPEN, todo_db_filename, O_RDONLY, 0
  test rax, rax
  js server_loop

  mov r14, rax

  mov qword [rel todo_index], 0

  .load_task_loop:
    mov rax, [rel todo_index]
    cmp rax, TODO_CAP
    jge .close_db

    shl rax, 8
    lea rbx, [todo_buffer + rax]
    xor r15, r15

  .load_char_loop:
    SYSCALL3 SYS_READ, r14, db_byte, 1
    test rax, rax
    js .close_db
    jz .load_eof

    mov al, [rel db_byte]
    cmp al, 13
    je .load_char_loop
    cmp al, 10
    je .load_line_done

    cmp r15, TODO_SIZE - 1
    jae .load_char_loop

    mov [rbx + r15], al
    inc r15
    jmp .load_char_loop

  .load_line_done:
    cmp r15, 0
    je .load_task_loop

    mov byte [rbx + r15], 0
    inc qword [rel todo_index]
    jmp .load_task_loop

  .load_eof:
    cmp r15, 0
    je .close_db

    mov byte [rbx + r15], 0
    inc qword [rel todo_index]

  .close_db:
    SYSCALL1 SYS_CLOSE, r14

  server_loop:
    SYSCALL3 SYS_ACCEPT, r12, 0, 0
    test rax, rax
    js error_and_close
    mov r13, rax

    SYSCALL3 SYS_READ, r13, request_buffer, request_buffer_len - 1
    test rax, rax
    js .rax_zero
    mov byte [request_buffer + rax], 0

    mov rdi, get
    mov rsi, request_buffer
    mov rdx, get_len
    call strncmp

    test rax, rax
    jnz .is_get

    mov rdi, post_add
    mov rsi, request_buffer
    mov rdx, post_add_len
    call strncmp

    test rax, rax
    jnz .is_post_add

    mov rdi, post_delete
    mov rsi, request_buffer
    mov rdx, post_delete_len
    call strncmp

    test rax, rax
    jnz .is_post_delete

    mov rdi, post_quit
    mov rsi, request_buffer
    mov rdx, post_quit_len
    call strncmp

    test rax, rax
    jnz .is_post_quit

    jmp .rax_zero

    .is_get:
      jmp .send_response

    .is_post_add:
      cmp qword [rel todo_index], TODO_CAP
      jge .rax_zero

      mov rdi, request_buffer
      mov rsi, body_separator
      call strstr

      cmp rax, -1
      je .rax_zero

      lea rsi, [request_buffer + rax + 9]   ; 9 because /r/n/r/ntask=

      mov rax, [rel todo_index]
      shl rax, 8
      lea rdi, [todo_buffer + rax]

      mov rcx, TODO_SIZE - 1


      .copy_loop:
        cmp rcx, 0
        je .copy_done

        mov al, [rsi]
        cmp al, 0
        je .copy_done

        cmp al, '&'
        je .copy_done

        cmp al, '+'
        jne .store_char

        mov al, ' '

      .store_char:
        mov [rdi], al

        inc rsi
        inc rdi
        dec rcx
        jmp .copy_loop

      .copy_done:
        mov byte [rdi], 0
        inc qword [rel todo_index]

      jmp .send_response
    

    .is_post_delete:
      mov rdi, request_buffer
      mov rsi, body_separator
      call strstr

      cmp rax, -1
      je .rax_zero

      lea rdi, [request_buffer + rax + 10]   ; 10 because /r/n/r/nindex=
      call atoi

      cmp rax, 0
      jl .rax_zero 
      cmp rax, TODO_CAP
      jae .rax_zero

      mov rcx, rax 

      .task_shift_loop:
        mov rdx, rcx
        inc rdx

        cmp rdx, [rel todo_index]
        jae .task_shift_done

        mov rax, rcx
        shl rax, 8
        lea rdi, [todo_buffer + rax]  ; tasks[i]

        mov rax, rdx
        shl rax, 8
        lea rsi, [todo_buffer + rax]  ; tasks[i+1]

        mov r8, TODO_SIZE

        .copy_task_loop:
          cmp r8, 0
          je .copy_task_done

          mov al, [rsi]
          mov [rdi], al

          inc rsi
          inc rdi
          dec r8
          jmp .copy_task_loop

        .copy_task_done:
          inc rcx
          jmp .task_shift_loop

      .task_shift_done:
        dec qword [rel todo_index]

      jmp .send_response


    .is_post_quit:
      SYSCALL1 SYS_CLOSE, r13
      jmp exit_server_loop

    .rax_zero:
      SYSCALL1 SYS_CLOSE, r13
      jmp server_loop

    .send_response:
      SYSCALL3 SYS_WRITE, r13, response_header, response_header_len
      SYSCALL3 SYS_WRITE, r13, response_body_before_task_list, response_body_before_task_list_len
      SYSCALL3 SYS_WRITE, r13, response_task_list_start, response_task_list_start_len

      mov rax, [rel todo_index]
      .task_loop:
        cmp rax, 0
        je .task_loop_exit

        dec rax
        push rax

        shl rax, 8
        lea r14, [todo_buffer + rax]

        mov rdi, r14 
        call strlen
        mov r15, rax

        SYSCALL3 SYS_WRITE, r13, li_start, li_start_len
        SYSCALL3 SYS_WRITE, r13, r14, r15
        SYSCALL3 SYS_WRITE, r13, li_delete_before_index, li_delete_before_index_len

        xor r8, r8
        mov rax, [rsp]
        cmp rax, 10
        jb .one_digit_index

        mov rbx, 10 
        xor rdx, rdx
        div rbx

        add al, '0'
        mov [rel index_buffer], al
        inc r8
        mov al, dl

        .one_digit_index:
          add al, '0'
          lea rbx, [rel index_buffer]
          mov [rbx + r8], al
          mov rdx, r8
          inc rdx
          SYSCALL3 SYS_WRITE, r13, index_buffer, rdx


        SYSCALL3 SYS_WRITE, r13, li_delete_after_index, li_delete_after_index_len

        pop rax
        jmp .task_loop

      .task_loop_exit:
        SYSCALL3 SYS_WRITE, r13, response_task_list_end, response_task_list_end_len
        SYSCALL3 SYS_WRITE, r13, response_body_after_task_list, response_body_after_task_list_len
        SYSCALL1 SYS_CLOSE, r13
        jmp server_loop

  exit_server_loop:
    SYSCALL3 SYS_OPEN, todo_db_filename, O_WRONLY | O_CREAT | O_TRUNC, 0o644
    test rax, rax
    js error_and_close

    mov r14, rax

    xor r15, r15
    .write_task_loop:
      cmp r15, [rel todo_index]
      jge .close_db

      mov rax, r15
      shl rax, 8
      lea rbx, [todo_buffer + rax]

      mov rdi, rbx
      call strlen
      mov r8, rax

      SYSCALL3 SYS_WRITE, r14, rbx, r8
      test rax, rax
      js .write_error

      mov byte [rel db_byte], 10
      SYSCALL3 SYS_WRITE, r14, db_byte, 1
      test rax, rax
      js .write_error

      inc r15
      jmp .write_task_loop

    .write_error:
      SYSCALL1 SYS_CLOSE, r14
      jmp error_and_close

    .close_db:
      SYSCALL1 SYS_CLOSE, r14
      SYSCALL1 SYS_CLOSE, r12

    SYSCALL1 SYS_EXIT, EXIT_SUCCESS

  SYSCALL1 SYS_EXIT, EXIT_SUCCESS

error_and_close:
  SYSCALL1 SYS_CLOSE, r12
  jmp error

error:
  SYSCALL3 SYS_WRITE, 1, error_msg, error_msg_len
  SYSCALL1 SYS_EXIT, EXIT_FAILURE
