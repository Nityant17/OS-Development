# Getting Started

### Objective is to successfully boot

So how does it work:
- First the BIOS checks the boot signature i.e the last 2 bytes and expects them to be `0xaa55` this tells the BIOS that this is a bootloader
- Then the bootloader is loaded at 0x7c00 in memory
- And then it just does what you tell it to

My code:
```asm
bits 16                ; Specify that this asm is based on 16 bit arch
ORG 0x7c00             ; Load the starting memory address for the bootloader

start:
  mov ax, 0x03         ; BIOS function to clear the screen
	int 0x10             ; Call BIOS interrupt
        
  mov al, 'H'	         ; Load the char into al register
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
- ax = ah + al, ah contains the data of what you want to do and al contains the character that will have the thing done to it
- 
