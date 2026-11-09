# 02.asm – Stack Frame with Local Variables (64-bit)

## What the program does
`_start` calls a function called `work`. Inside `work`, a proper stack frame is built using RBP, 16 bytes of space are reserved for two local variables, the numbers 100 and 200 are stored there, and then read back into `rax` and `rbx`. The frame is then torn down and the function returns to `_start`, which exits.

## How to build and run
```bash
nasm -f elf64 -g -F dwarf 02.asm -o 02.o
ld 02.o -o 02
./02
echo $?        
```

## Stack flow, step by step
Let **S** be RSP at program start (it points at argc = 1).

| Step | Instruction | RSP | RBP | What happens |
|---|---|---|---|---|
| 0 | start | S | 0 | [RSP] = argc |
| 1 | `call work` | S − 8 | 0 | CPU pushes the return address (address of `mov rax, 60`) and jumps to `work` |
| 2 | `push rbp` | S − 16 | 0 | saves the caller's RBP (it was 0) on the stack |
| 3 | `mov rbp, rsp` | S − 16 | S − 16 | RBP now marks the base of this function's frame |
| 4 | `sub rsp, 16` | S − 32 | S − 16 | reserves 16 bytes for two 8-byte local variables |
| 5 | `mov qword [rbp-8], 100` | S − 32 | S − 16 | first local = 100 |
| 6 | `mov qword [rbp-16], 200` | S − 32 | S − 16 | second local = 200 |
| 7 | `mov rax, [rbp-8]` / `mov rbx, [rbp-16]` | S − 32 | S − 16 | locals read into registers (no RSP change) |
| 8 | `mov rsp, rbp` | S − 16 | S − 16 | throws away the local variable space in one go |
| 9 | `pop rbp` | S − 8 | 0 | restores the caller's old RBP |
| 10 | `ret` | S | 0 | pops the return address into RIP, back in `_start` |
| 11 | exit syscall | S | 0 | stack balanced |

The frame while inside `work` (at the `nop`):

```
S       -> 1           argc
S - 8   -> 0x401005    return address (pushed by call)
S - 16  -> 0           saved old RBP          <- RBP points here
S - 24  -> 100         local [rbp - 8]
S - 32  -> 200         local [rbp - 16]       <- RSP points here
```

## Key points
- `call` is really "push return address + jump", and `ret` is really "pop into RIP". That is how the CPU knows where to come back to.
- `push rbp` / `mov rbp, rsp` is the standard function prologue. RBP stays fixed for the whole function, so locals can be reached with fixed offsets like `[rbp - 8]` even if RSP moves.
- `sub rsp, 16` allocates local space without pushing anything – it just moves RSP down. The memory is then written with plain `mov`.
- `mov rsp, rbp` / `pop rbp` / `ret` is the epilogue. It undoes the prologue in reverse order. If RSP were not reset first, `pop rbp` would pop a local variable instead of the saved RBP and `ret` would jump to a wrong address and crash.
- Locals live *below* RBP (negative offsets); the return address lives *above* it.

## Observations from running it (GDB)
- At start `rsp = 0x7fffffffda30`.
- After `call work`: `rsp = 0x7fffffffda28` and `[rsp] = 0x401005`. Running `x/i 0x401005` printed `<_start+5>: mov $0x3c,%eax`, which is the `mov rax, 60` line right after the call.
- After `push rbp`: `rsp = 0x7fffffffda20` and `[rsp] = 0x0` (the old RBP).
- After `mov rbp, rsp`: `rbp = rsp = 0x7fffffffda20`.
- After `sub rsp, 16`: `rsp = 0x7fffffffda10` (exactly 16 lower). The new space showed zeros at first; then `0x64` appeared at `[rbp-8]` (`0x7fffffffda18`) and `0xc8` at `[rbp-16]` (`0x7fffffffda10`) one instruction at a time.
- `x/4gx $rsp` at the `nop` gave `0xc8  0x64  0x0  0x401005` = 200, 100, saved RBP, return address.
- `rax = 0x64` (100) and `rbx = 0xc8` (200) after the loads.
- After `mov rsp, rbp`: `rsp = rbp = 0x7fffffffda20`. After `pop rbp`: `rsp = 0x7fffffffda28`, `rbp = 0`, and `0x401005` was back on top, ready for `ret`.
- After `ret`, `rsp` was back at `0x7fffffffda30`, `rbp = 0`, and execution continued at `mov rax, 60`. Exit status 0.