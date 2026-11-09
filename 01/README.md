# 01.asm – Basic PUSH and POP (64-bit)

## What the program does
It loads two numbers into registers (`rax = 100`, `rbx = 200`), pushes both onto the stack, then pops them back off into two *different* registers (`rcx` and `rdx`). Finally it exits with code 0. It prints nothing, so everything below was observed with GDB.

## How to build and run
```bash
nasm -f elf64 -g -F dwarf 01.asm -o 01.o
ld 01.o -o 01
./01
echo $?     
```

## Stack flow, step by step

Before anything runs, Linux has already set up the stack. RSP points at a value of `1`, which is `argc` (the program was run with one argument: its own name). I'll call the starting address **S**.

| Step | Instruction | RSP | What happens on the stack |
|---|---|---|---|
| 0 | (program start) | S | top of stack holds argc = 1 |
| 1 | `mov rax, 100` | S | no stack change, just a register |
| 2 | `mov rbx, 200` | S | no stack change |
| 3 | `push rax` | S − 8 | RSP drops by 8, then 100 is written at [RSP] |
| 4 | `push rbx` | S − 16 | RSP drops by 8 again, 200 is written at [RSP] |
| 5 | `nop` | S − 16 | stack now holds 200 (top) and 100 below it |
| 6 | `pop rcx` | S − 8 | value at [RSP] (200) is copied into rcx, RSP goes up by 8 |
| 7 | `pop rdx` | S | value at [RSP] (100) is copied into rdx, RSP goes up by 8 |
| 8 | exit syscall | S | stack is back where it started |

Picture of the stack at the first `nop` (higher addresses at the top):

```
S       -> 1      (argc, put there by Linux)
S - 8   -> 100    (pushed from rax)
S - 16  -> 200    (pushed from rbx)   <- RSP points here
```

## Key points
- On x86-64 the stack **grows downward**. `push` first subtracts 8 from RSP and then stores the value; `pop` reads the value and then adds 8.
- Every push/pop is 8 bytes here because we are using 64-bit registers.
- The stack is **Last In, First Out**. `rbx` was pushed last, so its value (200) comes out first. That is why `rcx` ends up with 200 and `rdx` with 100 – the values are effectively swapped compared to the order they went in.
- `pop` does not erase memory. After popping, the old values are still sitting below RSP; they are just treated as free space now.
- Two pushes and two pops means RSP finishes exactly where it started, so the stack is balanced.

## Observations from running it (GDB)
- At start: `rsp = 0x7fffffffda30`, `[rsp] = 0x1` (argc).
- After `push rax`: `rsp = 0x7fffffffda28`, `[rsp] = 0x64` (100).
- After `push rbx`: `rsp = 0x7fffffffda20`, `[rsp] = 0xc8` (200).
- `x/3gx $rsp` at the `nop` showed `0xc8  0x64  0x1` – exactly the picture above.
- During the pops the display showed RSP climbing back `0x7fffffffda20 → 0x7fffffffda28 → 0x7fffffffda30`, with `0x64` on top after the first pop.
- After both pops: `rcx = 0xc8` (200), `rdx = 0x64` (100), and `rsp` was back to `0x7fffffffda30`.
- Program exits with status 0.