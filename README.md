# Stack Assignment – 07_stack

Billy John Igiraneza – BICS 4C, Assembly Language Programming

Each folder holds one program from `07_stack` and a README explaining how the stack behaves in it, with observations from stepping through it in GDB.

| Folder | Mode | Topic |
|---|---|---|
| [01](01/README.md) | 64-bit | Basic push/pop, LIFO order |
| [02](02/README.md) | 64-bit | Stack frame (RBP), local variables, call/ret |
| [03](03/README.md) | 64-bit | call/ret and the return address |
| [04](04/README.md) | 32-bit | Stack frame with ESP/EBP |
| [05](05/README.md) | 64-bit | Saving/restoring registers, little-endian |
| [06](06/README.md) | 32-bit | Saving/restoring registers in 32-bit |

## Build and run everything
```bash
chmod +x build.sh
./build.sh
```
Tools: NASM, GNU ld, GDB on Ubuntu (WSL2).
None of the programs print anything – they all exit with status 0, so the stack behaviour was checked in GDB with `starti`, `stepi`, `info registers rsp` and `x/4gx $rsp`.
