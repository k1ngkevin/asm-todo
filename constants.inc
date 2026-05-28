; constants.inc
; Linux x86-64 constants

SYS_READ       equ 0
SYS_WRITE      equ 1
SYS_OPEN       equ 2
SYS_CLOSE      equ 3
SYS_FSTAT      equ 5
SYS_SOCKET     equ 41
SYS_ACCEPT     equ 43
SYS_BIND       equ 49
SYS_LISTEN     equ 50
SYS_SETSOCKOPT equ 54
SYS_EXIT       equ 60

O_RDONLY equ 0
O_WRONLY equ 1
O_CREAT  equ 64
O_TRUNC  equ 512

AF_INET     equ 2
SOCK_STREAM equ 1
INADDR_ANY  equ 0

SOL_SOCKET   equ 1
SO_REUSEADDR equ 2
SO_REUSEPORT equ 15

SOL_TCP     equ 6
TCP_NODELAY equ 1

STDIN  equ 0
STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

struc sockaddr_in
  .sin_family: resw 1
  .sin_port: resw 1
  .sin_addr: resd 1
  .sin_zero: resq 1
endstruc


