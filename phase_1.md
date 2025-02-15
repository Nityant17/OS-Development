# Getting Started

### Objective is to successfully boot

So how does it work:
- First the BIOS checks the boot signature i.e the last 2 bytes and expects them to be `0xaa55` this tells the BIOS that this is a bootloader
- Then the bootloader is loaded at `0x7c00` in memory
- And then it just does what you tell it to...

My code:
```asm
bits 16                ; Specify that this asm is based on 16 bit arch
ORG 0x7c00             ; Load the starting memory address for the bootloader

start:
  	mov ax, 0x03         ; BIOS function to clear the screen
	int 0x10             ; Call BIOS interrupt
        
  	mov al, 'H'	     ; Load the char into al register
	mov ah, 0x0e         ; Set the function code in ah register to print i.e 0x0e
	int 0x10             ; Call BIOS interrupt
	mov al, 'I'
	mov ah, 0x0e 
	int 0x10
	mov al, '!'
	mov ah, 0x0e 
	int 0x10
	jmp $                ; Jump to itself to create an infinite loop and keep the bootloader running

times 510-($-$$) db 0  ; Fill the empty bytes with zeros
dw 0xaa55              ; Magic bytes to tell the BIOS that this is a bootloader
```

Some other things to keep in mind:
- `ORG` is short for origin and is used to tell the assembler where to start placing the machine code in memory
- `ax` = `ah` + `al`, `ax` is 16 bit register and `ah`,`al` are 8 bit, `ah` is called high byte of `ax` and `al` is called low byte of `ax`
- `ah` contains the data of what you want to do (the function) and `al` contains the character that will have the thing done to it
- `ah` needs to be given its value repeatedly because it gets cleared after a BIOS interrupt call, so we need to set it again
- BIOS interrupt call is basically to refresh/update the screen and to let us interact with it so that we can make changes to it
- We need to create an infinite loop to keep the bootloader ruuning and preventing it from crashing or executing something random
- `times` is used to repeat the command `db 0` (define byte as 0) till the total file size is '510' bytes, `$` refers to the current address in the code, and `$$` is the starting address, this expression calculates how many bytes are left until the 510th byte
- The last 2 bytes are filled with the magic bytes `0xaa55` using `dw` (define word) to specify this is a bootloader

How to run the code:

```bash
~$nasm -f bin asm.s -o asm.bin
~$qemu-system-i386 -drive format=raw,file=asm.bin
```
