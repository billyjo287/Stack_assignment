# 05.asm – Saving and Restoring Registers with PUSH/POP (64-bit)

## What the program does
It loads a full 64-bit value `0x1122334455667788` into `rax` and a small value `0x1234` into `rbx`, pushes both, then pops them back into the same registers in reverse order. The point is to show that the stack can save registers and give them back unchanged. Then it exits.

## How to build and run
```bash
nasm -f elf64 -g -F dwarf 05.asm -o 05.o
ld 05.o -o 05
./05
echo $?        
```

## Stack flow, step by step
Let **S** be RSP at program start (points at argc = 1).

| Step | Instruction | RSP | What happens |
|---|---|---|---|
| 0 | start | S | [RSP] = argc |
| 1 | `mov rax, 0x1122334455667788` | S | register only |
| 2 | `mov rbx, 0x1234` | S | register only |
| 3 | `push rax` | S − 8 | all 8 bytes of rax stored |
| 4 | `push rbx` | S − 16 | rbx stored (padded to 8 bytes) |
| 5 | `nop` | S − 16 | |
| 6 | `pop rbx` | S − 8 | top value (0x1234) back into rbx |
| 7 | `pop rax` | S | next value (0x1122334455667788) back into rax |
| 8 | exit | S | balanced |

```
S       -> 1                     argc
S - 8   -> 0x1122334455667788    from rax
S - 16  -> 0x0000000000001234    from rbx   <- RSP
```

## Key points
- Because pushes and pops are LIFO, the pops must be done in reverse order of the pushes (`push rax, push rbx` → `pop rbx, pop rax`) for each register to get its own value back. Compare with 01.asm, where the pops went into different registers and the values ended up swapped.
- This push-then-pop-in-reverse pattern is exactly how programs save registers before a function uses them and restore them afterwards.
- A 64-bit push always moves 8 bytes, even when the value is small – `0x1234` is stored as `0x0000000000001234`.
- **Little-endian**: in memory the lowest byte is stored first. So `0x1122334455667788` appears in memory as `88 77 66 55 44 33 22 11`.

## Observations from running it (GDB)
- `rsp` went `0x7fffffffda30 → 0x7fffffffda28 → 0x7fffffffda20` on the two pushes, then back up the same way on the pops (`0x7fffffffda28` after `pop rbx`, `0x7fffffffda30` after `pop rax`).
- `x/2gx $rsp` at the `nop` showed `0x0000000000001234  0x1122334455667788`.
- `x/16xb $rsp` showed the bytes: `34 12 00 00 00 00 00 00` then `88 77 66 55 44 33 22 11` – proof of little-endian storage and zero-padding.
- After the pops, `rax = 0x1122334455667788` and `rbx = 0x1234` – nothing was lost or changed.
- Exit status 0.