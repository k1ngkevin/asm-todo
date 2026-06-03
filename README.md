# asm-todo

A todo web server built entirely in NASM x86-64 assembly for Linux.

The server listens on port `3000`, renders a basic HTML todo list, accepts tasks through an HTTP form, supports deleting tasks, and saves tasks to `todo.db` file when the server exits through the page's quit button.

## Requirements

- Linux x86-64
- NASM
- `ld`

## Build

```sh
nasm -f elf64 main.asm -o main.o
ld main.o -o server
```

## Run

```sh
./server
```

Then open:

```text
http://localhost:3000
```

## Data File

Tasks are stored in `todo.db` in the project directory.

The format is one task per line:

```text
blue
red
yellow
```

At startup, the server opens `todo.db` if it exists and loads each line into `todo_buffer`.

On quit, the server truncates `todo.db` and writes the current tasks back out, one task per line.

## Current Limits

- Maximum tasks: `100`
- Maximum task length: `255` bytes plus a null terminator
- The HTTP parser is minimal and only handles the expected form requests

## Source Layout

- `main.asm`: server, request handling, todo storage, file load/save
- `constants.inc`: Linux syscall numbers, flags, socket constants, and structs
- `syscalls.inc`: NASM syscall helper macros
- `utils.inc`: small string helpers such as `strncmp`, `strstr`, `strlen`, and `atoi`
