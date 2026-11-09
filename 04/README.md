# 04.asm – Stack Frame in 32-bit Mode (ESP / EBP)

## What the program does
This is the 32-bit version of program 02. `_start` calls `work`, which builds a stack frame with EBP, reserves 8 bytes for two 4-byte local variables, stores 100 and 200, reads them into `eax` and `ebx`, tears the frame down and returns. `_start` then exits using the old 32-bit Linux method (`int 0x80` with `eax = 1`).

## How to build and run
It must be assembled as 32-bit and linked for i386:
```bash
nasm -f elf32 -g -F dwarf 04.asm -o 04.o
ld -m elf_i386 04.o -o 04
./04
echo $?        
```

## Stack flow, step by step
Let **S** be ESP at program start (points at argc = 1).

| Step | Instruction | ESP | EBP | What happens |
|---|---|---|---|---|
| 0 | start | S | 0 | [ESP] = argc |
| 1 | `call work` | S − 4 | 0 | pushes 4-byte return address, jumps to `work` |
| 2 | `push ebp` | S − 8 | 0 | saves caller's EBP |
| 3 | `mov ebp, esp` | S − 8 | S − 8 | sets the frame base |
| 4 | `sub esp, 8` | S − 16 | S − 8 | reserves two 4-byte locals |
| 5 | `mov dword [ebp-4], 100` | S − 16 | S − 8 | first local = 100 |
| 6 | `mov dword [ebp-8], 200` | S − 16 | S − 8 | second local = 200 |
| 7 | loads into eax / ebx | S − 16 | S − 8 | eax = 100, ebx = 200 |
| 8 | `mov esp, ebp` | S − 8 | S − 8 | frees locals |
| 9 | `pop ebp` | S − 4 | 0 | restores old EBP |
| 10 | `ret` | S | 0 | pops return address into EIP |
| 11 | `int 0x80` exit | S | 0 | stack balanced |

Frame at the `nop`:

```
S       -> 1           argc
S - 4   -> 0x8049005   return address
S - 8   -> 0           saved EBP        <- EBP
S - 12  -> 100         [ebp - 4]
S - 16  -> 200         [ebp - 8]        <- ESP
```

## Key points / comparison with 02.asm
- The logic is identical to 02, but every stack slot is 4 bytes instead of 8. So `call` and `push` move ESP by 4, and the two locals only need `sub esp, 8` instead of `sub rsp, 16`.
- The registers are the 32-bit ones: ESP (stack pointer), EBP (base pointer), EIP (instruction pointer).
- Offsets are `[ebp - 4]` and `[ebp - 8]` because each local is a `dword` (4 bytes).
- Prologue (`push ebp; mov ebp, esp; sub esp, 8`) and epilogue (`mov esp, ebp; pop ebp; ret`) follow the same pattern as 64-bit.
- The exit is done with `int 0x80` and `eax = 1` (32-bit syscall convention) instead of `syscall` with `rax = 60`.

## Observations from running it (GDB)
- Start: `esp = 0xffffcb90`. Addresses are in the 32-bit range now.
- After `call work`: `esp = 0xffffcb8c` (−4) and `[esp] = 0x8049005`, the address of `mov eax, 1`.
- After `push ebp`: `esp = 0xffffcb88`; after `mov ebp, esp`: `ebp = 0xffffcb88`.
- After `sub esp, 8`: `esp = 0xffffcb80`.
- The locals appeared one at a time: `0x64` at `[ebp-4]` (`0xffffcb84`), then `0xc8` at `[ebp-8]` (`0xffffcb80`). `x/4wx $esp` at the `nop` showed `0xc8  0x64  0x0  0x8049005`.
- `eax = 0x64` (100), `ebx = 0xc8` (200) after the loads.
- After `pop ebp`: `esp = 0xffffcb8c` with `0x8049005` on top again.
- After `ret`: `esp` back to `0xffffcb90`, `ebp = 0`. Exit status 0.