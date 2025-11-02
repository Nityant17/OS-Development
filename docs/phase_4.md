# Phase 4

### Objective is to print something by popping from a stack

- To first use a stack we need to initialize it
- To print from a stack we first `push` the character onto the stack and then print it by `pop`ping it from the stack

My code:

```asm
bits 16        ; Specify that this asm is based on 16 bit arch
org 0x7c00     ; Load the starting memory address for the bootloader

start:    
        mov ax, 0x03         ; BIOS function to clear the screen
        int 0x10             ; Call BIOS interrupt
	      mov si, mes          ; Load address of the msg into si
        call print        
        call newline        
        mov esp, 0x9fc00     ; Set the stack segment register
        mov si, msg          ; Load the other msg into si
        call push_str       
        call pop_str          
        jmp $                ; Jump to itself to create an infinite loop and keep the bootloader running


print:                       ; Function to print the string
        mov ah, 0x0e         ; Set the function code in ah register to print
.loop:
        mov al, [si]         ; Load byte from memory at si into al
        cmp al, 0            ; Check for null terminator
        je .done             ; If null, exit
        int 0x10             ; Print character
        inc si               ; Increment si to point to the next byte
        jmp .loop            ; Repeat for next character
.done:
        ret                  ; When null terminator reached come out of the function


push_str:                    ; Function to push string onto the stack
        pop dx               ; Save return address so it doesnt get overwritten on pushing
        mov ah, 0x0e        
        mov cx, 0            ; Counter to track number of characters pushed
.loop:
        mov al, [si]         
        cmp al, 0            
        je .done            
        push ax              ; Push character onto stack
        inc cx               ; Increment counter
        inc si               
        jmp .loop           
.done:
        jmp dx               ; Return safely
          

pop_str:                     ; Function to print by popping from stack
        pop dx               ; Save return address
        mov ah, 0x0e           
.loop:
        pop ax               ; Pop a character from stack
        cmp cx, 0            ; Check if counter is 0 i.e all elements have been popped
        je .done           
        int 0x10             ; Print character
        dec cx               ; Decrease counter by 1 for each pop
        jmp .loop             
.done:
        jmp dx               ; Return safely        


newline:                     ; Function to print newline (\n)
        mov ah, 0x0e
        mov al, 0x0a         ; Set al value as line feed i.e 0aH or 0x0a 
        int 0x10             ; Print the line feed
        mov ah, 0x0e
        mov al, 0x0d         ; Set al value as carriage return i.e 0dH or 0x0d
        int 0x10             ; Print the carriage return 
        ret


mes: db "Welcome to the Bootloader!", 0    ; Define msg as the string followed by the null byte for terminating
msg: db "...ssergorP nI", 0                ; The msg here is in reverse as we are printing from stack that follows LIFO

times 510-($-$$) db 0    ; Fill the empty bytes with zeros
dw 0xaa55                ; Magic bytes to tell the BIOS that this is a bootloader
```

Some other things to keep in mind:
- First we set the stack by using `mov esp, 0x9fc00`, the address where it is loaded is `0x9fc00` because it is far away from the rest of the code thus it will not collide
- The msg we want to print is given in reverse as stack follows Last In First Out (LIFO) structure
- Now to `push` the characters onto the stack I created the `push_str` function but when we call a fuction the return address is also pushed onto the stack so if we dont preserve it other things we `push` will be pushed on top of that thus burrying the return address and so when the function reaches `ret` it will return to a random address thus messing up the whole code. So to avoid this I `pop` the return address and store it in `dx` and then later just jump to `dx` thus the fucntion exits normally
- Simillary for `pop_str` too if we just start popping it will also `pop` the return address that was pushed upon calling of the function so I again store the return address first into `dx` to preserve it and at the end just jump to `dx` to safely exit the function
- I use `cx` as a counter to keep track of how many characters need to be popped from the stack
- To print the characters i first use `push_str` to `push` the characters onto the stack and then print it by popping them using `pop_str`

Makefile:

```make
# Directories
ASM_DIR := asm
OUT_DIR := out

# Tools
NASM := nasm
QEMU := qemu-system-i386
MKDIR := mkdir -p
RM := rm -rf

# Flags
NFLAGS := -f bin

# Output files
BOOT_BIN := $(OUT_DIR)/boot.bin

# Sources
ASM_SOURCES := $(ASM_DIR)/boot.asm

# Default target
default: pre-config bootloader run

# Ensure output directory exists
pre-config:
	@$(MKDIR) $(OUT_DIR)
.PHONY: pre-config

# Assemble bootloader
bootloader: $(BOOT_BIN)
$(BOOT_BIN): $(ASM_SOURCES)
	$(NASM) $(NFLAGS) -o $@ $<
.PHONY: bootloader

# Run in QEMU
run: $(BOOT_BIN)
	$(QEMU) -drive format=raw,file=$(BOOT_BIN)
.PHONY: run

# Clean build files
clean:
	$(RM) $(OUT_DIR)
.PHONY: clean
```
