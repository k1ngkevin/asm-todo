%include "constants.inc"
%include "syscalls.inc"
%include "utils.inc"

request_buffer_len equ 4096
TODO_CAP equ 100
TODO_SIZE equ 256

section .bss
request_buffer resb request_buffer_len
todo_buffer resb TODO_CAP * TODO_SIZE

section .data

msg db "Server Running", 10     ; add port number as well
msg_len equ $ - msg
error_msg db "An unexpected error occured", 10
error_msg_len equ $ - error_msg

get db "GET "
get_len equ $ - get
post db "POST "
post_len equ $ - post

response:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: text/html", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
    db '<!DOCTYPE html>', 10
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
    db '  <ul>', 10
    db '  </ul>', 10
    db '  <form method="POST" action="/quit">', 10
    db '    <button type="submit">Quit Server</button>', 10
    db '  </form>', 10
    db '</body>', 10
    db '</html>', 10

response_len equ $ - response

servaddr:
  istruc sockaddr_in
    at sockaddr_in.sin_family, dw AF_INET
    at sockaddr_in.sin_port, dw 0xB80B    ; port 3000 in big endian format
    at sockaddr_in.sin_addr, dw INADDR_ANY
    at sockaddr_in.sin_zero, dq 0
  iend


section .text
global _start

_start:
  SYSCALL3 SYS_SOCKET, AF_INET, SOCK_STREAM, 0
  test rax, rax
  js error
  mov r12, rax

  SYSCALL3 SYS_BIND, r12, servaddr, sockaddr_in_size
  test rax, rax
  js error_and_close

  SYSCALL2 SYS_LISTEN, r12, 10
  test rax, rax
  js error_and_close

  SYSCALL3 SYS_WRITE, 1, msg, msg_len

  server_loop:
    SYSCALL3 SYS_ACCEPT, r12, 0, 0
    test rax, rax
    js error_and_close
    mov r13, rax

    SYSCALL3 SYS_READ, r13, request_buffer, request_buffer_len

    mov rdi, get
    mov rsi, request_buffer
    mov rdx, get_len
    call strncmp

    test rax, rax
    jnz .is_get

    mov rdi, post
    mov rsi, request_buffer
    mov rdx, post_len
    call strncmp

    test rax, rax
    jnz .is_post

    jmp .rax_zero

    .is_get:
      SYSCALL3 SYS_WRITE, 1, get, get_len
      jmp .send_response

    .is_post:
      SYSCALL3 SYS_WRITE, 1, post, post_len
      jmp .send_response

    .rax_zero:
      SYSCALL1 SYS_CLOSE, r13
      jmp server_loop

    .send_response:
      SYSCALL3 SYS_WRITE, r13, response, response_len
      SYSCALL1 SYS_CLOSE, r13
      jmp server_loop

  SYSCALL1 SYS_EXIT, EXIT_SUCCESS

error_and_close:
  SYSCALL3 SYS_WRITE, 1, error_msg, error_msg_len
  SYSCALL1 SYS_CLOSE, r12
  jmp error

error:
  SYSCALL3 SYS_WRITE, 1, error_msg, error_msg_len
  SYSCALL1 SYS_EXIT, EXIT_FAILURE
