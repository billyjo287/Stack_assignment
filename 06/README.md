# 06.asm – Saving and Restoring Registers in 32-bit Mode

## What the program does
The 32-bit version of 05.asm. It puts `0x11223344` in `eax` and `0x1234` in `ebx`, pushes both, pops them back in reverse order into the same registers, and exits with `int 0x80`.

## How to build and run
```bash
nasm -f elf32 -g -F dwarf 06.asm -o 06.o
ld -m elf_i386 06.o -o 06
./06
echo $?        
```

## Stack flow, step by step
Let **S** be ESP at program start (points at argc = 1).

| Step | Instruction | ESP | What happens |
|---|---|---|---|
| 0 | start | S | [ESP] = argc |
| 1 | `mov eax, 0x11223344` | S | register only |
| 2 | `mov ebx, 0x1234` | S | register only |
| 3 | `push eax` | S − 4 | 4 bytes stored |
| 4 | `push ebx` | S − 8 | 4 bytes stored |
| 5 | `nop` | S − 8 | |
| 6 | `pop ebx` | S − 4 | 0x1234 back into ebx |
| 7 | `pop eax` | S | 0x11223344 back into eax |
| 8 | `int 0x80` exit (eax = 1) | S | balanced |

```
S      -> 1            argc
S - 4  -> 0x11223344   from eax
S - 8  -> 0x00001234   from ebx    <- ESP
```

## Key points / comparison with 05.asm
- Same idea as 05, but each push/pop moves ESP by 4 bytes instead of 8, because the registers are 32 bits wide.
- Reverse-order popping restores each register to its original value (LIFO).
- Values are still little-endian: `0x11223344` is stored as `44 33 22 11`.
- Exit uses the 32-bit convention: `eax = 1` (exit), `ebx = 0` (status), `int 0x80`.

## Observations from running it (GDB)
- `esp` went `0xffffcb90 → 0xffffcb8c → 0xffffcb88` on the pushes (steps of 4), then back up on the pops (`0xffffcb8c`, then `0xffffcb90`).
- `x/2wx $esp` at the `nop` showed `0x00001234  0x11223344`.
- `x/8xb $esp` showed `34 12 00 00 44 33 22 11`.
- After the pops: `eax = 0x11223344`, `ebx = 0x1234`.
- Exit status 0.