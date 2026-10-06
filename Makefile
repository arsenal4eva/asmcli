all: asmcli.img

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

kernel.bin: kernel.asm
	nasm -f bin kernel.asm -o kernel.bin

asmcli.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > asmcli.img
	truncate -s 1474560 asmcli.img

run: asmcli.img
	qemu-system-x86_64 -drive format=raw,file=asmcli.img -nographic -device isa-debug-exit,iobase=0xf4,iosize=0x04

run-curses: asmcli.img
	qemu-system-x86_64 -drive format=raw,file=asmcli.img -curses -serial mon:stdio

test: asmcli.img
	(sleep 5; printf 'help\r'; sleep 1; printf 'echo hello qemu\r'; sleep 1; printf 'bogus\r'; sleep 1; printf 'exit\r'; sleep 2) | timeout 20 qemu-system-x86_64 -drive format=raw,file=asmcli.img -nographic -display none -device isa-debug-exit,iobase=0xf4,iosize=0x04 | cat -v; echo "qemu exit code: $$?"

cli: cli.asm
	nasm -f bin cli.asm -o cli.bin

clean:
	rm -rf cli cli.o cli.bin boot.bin kernel.bin asmcli.img
