# asmcli

Tiny CLI written in x86 16-bit real-mode assembly, running bare-metal in QEMU.

Two frontends exist, both BIOS-based bare-metal (no OS):
- **Kernel** (`boot.asm` + `kernel.asm`, default, linked into `asmcli.img`): BIOS `int 10h`/`int 16h` teletype + keyboard I/O on the VGA console.
- **Legacy CLI** (`cli.asm`): same BIOS REPL variant, not linked into image (build with `make cli`).

![demo](demo.png)

## Requirements

- `nasm`
- `qemu-system-x86_64`

## How to run

```sh
make run
```

This builds `asmcli.img` (if needed) and boots it in QEMU. Use the VGA/keyboard frontend (`make run-curses` or plain QEMU SDL/VGA), since the kernel uses BIOS video/keyboard services, not serial. You should see:

```
asm cli (bios)
type 'help' for commands
>
```

Available commands (both CLIs):

| Command      | Effect                                              |
|--------------|-----------------------------------------------------|
| `help`       | List commands                                       |
| `echo <txt>` | Print `<txt>` back (bare `echo` prints blank line)  |
| `clear`      | Clear screen (`int 10h AX=0003h`, 80x25 text mode) |
| `exit`       | Print `bye`, try `isa-debug-exit` / ACPI / 8042 shutdown, fallback `int 19h` reboot |
| `<other>`    | Print `?`                                           |

Input editing:
- Line-buffered, 127 chars max, Enter = CR (`0x0D`) or LF (`0x0A`) terminates.
- Echo + Backspace support (`0x08`).
- Leading spaces skipped; empty line re-prompts.

Notes:

- The kernel uses only BIOS services (`int 10h AH=0Eh` output, `int 16h AH=00h` input, `int 10h AX=0003h` clear, `int 13h` disk load in `boot.asm`, `int 19h` reboot fallback) — no OS, no serial port I/O. Direct `out` port writes remain only for the QEMU shutdown chain (`0xF4`, `0x604`, `0x64`).
- Typing `exit` tries shutdown in order: `isa-debug-exit` port `0xF4`, ACPI `0x604 <- 0x2000`, 8042 reset (`0x64 <- 0xFE`), fallback `int 19h` reboot. The `isa-debug-exit` device (`-device isa-debug-exit,iobase=0xf4,iosize=0x04`) makes QEMU quit so control returns to your terminal automatically.
- Non-interactive smoke test: `make test` (pipes a scripted session: `help`, `echo hello qemu`, `bogus`, `exit` into QEMU with `timeout 20`).
- Alternative display frontend: `make run-curses` (`-curses -serial mon:stdio`).
- Legacy BIOS target (not linked into image): `make cli` assembles `cli.asm` → `cli.bin`.

## Files

| File        | Summary |
|-------------|---------|
| `boot.asm`  | 512-byte boot sector (`ORG 0x7C00`, `0xAA55`). Zeroes `DS/ES/SS`, stack at `0x7C00`, saves boot drive, inits COM1 to 115200 8N1 (DLAB `0x80`, divisor `1`, `LCR=0x03`), loads 63 sectors from LBA 1 (CHS `C=0 H=0 S=2`) via BIOS `int 13h AH=02h` to `0x0000:0x7E00`. Prints `!` on serial + halts on disk error, else far-jumps to kernel. |
| `kernel.asm`| 16-bit BIOS bare-metal CLI kernel (`ORG 0x7E00`). I/O via `int 10h AH=0Eh` teletype, `int 16h AH=00h` keyboard, `int 10h AX=0003h` clear. REPL with `> ` prompt, `read_line`, `skip_spaces` / `strcmp` / `starts_with` dispatch for `help` / `echo` / `clear` / `exit`, `?` on unknown. 128-byte input buffer. |
| `cli.asm`   | Legacy BIOS/VGA variant of the same CLI (`ORG 0x7E00`, not part of `asmcli.img`). Same REPL/dispatch/128-byte buffer, but I/O via `int 10h AH=0Eh` teletype output, `int 16h AH=00h` keyboard input, `int 10h AX=0003h` screen clear, `int 19h` reboot on `exit`. Banner is `asm cli` (no `(qemu serial)` suffix). |
| `Makefile`  | `boot.bin` + `kernel.bin` via `nasm -f bin`, concatenated + `truncate -s 1474560` (1.44 MB floppy) into `asmcli.img`. Targets: `run` (`-nographic` + `isa-debug-exit`), `run-curses`, `test` (scripted pipe + `timeout 20`), legacy `cli` (`cli.asm` → `cli.bin`), `clean`. |
| `demo.png`  | Screenshot of serial session. |
| `boot.bin` / `kernel.bin` / `asmcli.img` | Build artifacts (git-ignored/generated). |
