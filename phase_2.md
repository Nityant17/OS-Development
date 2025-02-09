# Phase 2

### Objective is to print a string on the bootloader and learn about makefile 

My code:
```asm
bits 16	       ; Specify that this asm is based on 16 bit arch
org 0x7c00     ; Load the starting memory address for the bootloader

start:	
        mov ax, 0x03    ; BIOS function to clear the screen
        int 0x10	; Call BIOS interrupt
        mov si, msg     ; Load address of the msg into SI
        call print	; Call the print function
        jmp $           ; Jump to itself to create an infinite loop and keep the bootloader running

print:	      		; Function to print the string
        mov ah,0x0e   	; Set the function code in ah register to print
.loop:
        mov al, [si]  	; Load byte from memory at si into al
    	cmp al, 0     	; Check for null terminator
    	je .done      	; If null, exit
    	int 0x10      	; Print character
    	inc si        	; Increment si to point to the next byte
    	jmp .loop     	; Repeat for next character
.done:
        ret	      	; When null terminator reached come out of the function

msg: db "Hello",0aH,0dH,"World!", 0  ; Define msg as the string followed by the null byte for terminating 

times 510-($-$$) db 0	  ; Fill the empty bytes with zeros
dw 0xaa55		  ; Magic bytes to tell the BIOS that this is a bootloader
```

Some other things to keep in mind:
- `si` register is source index and is used as a pointer for string operations
- On running `mov si, msg` since `msg` is a label referring to the memory location of the str, `si` now holds the address where the str begins
- `inc si` increments `si` by 1, moving to the next character in memory thus pointing to next character in the str
- `cmp` compares each character to check if it is the null character i.e 0 and if it is 0 `je` jumps to `.done` thus exiting out of `.loop`
- `ret` is return that returns from a function by restoring the instruction pointer (ip) to the address stored on the stack
- `ret` ensures the function returns to where it was called
- `OaH` and `0dH` represent line feed and carriage return respectively
- `print_f` is a Global Label	and can be used across the entire program	
- `.loop` and `.done` are Local Label and can be only used inside function `print_f`

Makefile:

```make
ASM_DIR := asm
OUT_DIR := out

NASM := nasm
QEMU := qemu-system-i386

NFLAGS := -f bin

BOOT_BIN := $(OUT_DIR)/boot.bin

ASM_SOURCES := $(ASM_DIR)/boot.asm

default: bootloader run

# Assemble bootloader
bootloader: $(BOOT_BIN)
$(BOOT_BIN): $(ASM_SOURCES)
	$(NASM) $(NFLAGS) -o $@ $<
.PHONY: bootloader

# Run in QEMU
run: $(BOOT_BIN)
	$(QEMU) -drive format=raw,file=$(BOOT_BIN)
.PHONY: run
```
