; syscalls.inc
; Linux x86-64 syscall helper macros for NASM

%macro SYSCALL0 1
    mov rax, %1
    syscall
%endmacro

%macro SYSCALL1 2
    mov rax, %1
    mov rdi, %2
    syscall
%endmacro

%macro SYSCALL2 3
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    syscall
%endmacro

%macro SYSCALL3 4
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    syscall
%endmacro

%macro SYSCALL4 5
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    mov r10, %5
    syscall
%endmacro

%macro SYSCALL5 6
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    mov r10, %5
    mov r8,  %6
    syscall
%endmacro

%macro SYSCALL6 7
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    mov r10, %5
    mov r8,  %6
    mov r9,  %7
    syscall
%endmacro
