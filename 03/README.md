# 03.asm – CALL and RET (Return Address on the Stack)

## What the program does
`_start` puts 10 in `rax` and calls a tiny function `calculate`, which adds 5 to `rax` and returns. Back in `_start`, at the label `after_call`, `rax` should be 15. Then the program exits.

There are no `push` or `pop` instructions written in this program, but the stack is still used – by `call` and `ret` themselves.

## How to build and run
```bash
nasm -f elf64 -g -F dwarf 03.asm -o 03.o
ld 03.o -o 03
./03
echo $?       
```

## Stack flow, step by step
Let **S** be RSP at program start (it points at argc = 1).

| Step | Instruction | RSP | What happens |
|---|---|---|---|
| 0 | start | S | [RSP] = argc |
| 1 | `mov rax, 10` | S | register only |
| 2 | `call calculate` | S − 8 | CPU pushes the address of the next instruction (`after_call`) and jumps to `calculate` |
| 3 | `add rax, 5` | S − 8 | rax = 15, stack untouched |
| 4 | `ret` | S | CPU pops the top of stack (the `after_call` address) into RIP |
| 5 | `nop` at `after_call` | S | back in `_start` |
| 6 | exit syscall | S | stack balanced |

Stack inside `calculate`:

```
S       -> 1          argc
S - 8   -> 0x40100a   return address = after_call   <- RSP
```

## Key points
- `call X` = push the return address (8 bytes) + jump to X.
- `ret` = pop 8 bytes into RIP. It blindly trusts whatever is on top of the stack, which is why a function must leave RSP exactly where it found it.
- `calculate` doesn't build a stack frame (no RBP) because it has no local variables. That's fine for a tiny "leaf" function.
- The value is passed in and returned through `rax`, not through the stack.

## Observations from running it (GDB)
- Before the call: `rsp = 0x7fffffffda30`, `rax = 0xa` (10).
- Inside `calculate`: `rsp = 0x7fffffffda28` and `[rsp] = 0x40100a`. `info symbol 0x40100a` printed `after_call in section .text`, so the return address really is the label after the call.
- After `add rax, 5`: `rax = 0xf` (15) – the comment in the code is correct.
- After `ret`: `rsp` back to `0x7fffffffda30` and RIP at `after_call`.
- Exit status 0.