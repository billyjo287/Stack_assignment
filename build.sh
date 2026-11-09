for n in 01 02 03 04 05 06; do
  cd "$n" || continue
  if grep -q "BITS 32" "$n.asm"; then
    nasm -f elf32 -g -F dwarf "$n.asm" -o "$n.o" && ld -m elf_i386 "$n.o" -o "$n"
  else
    nasm -f elf64 -g -F dwarf "$n.asm" -o "$n.o" && ld "$n.o" -o "$n"
  fi
  ./"$n"
  echo "$n.asm -> exit status $?"
  cd ..
done
