# Phase 5

### Objective is to load in sectors and read data from the hard disk

- Without loading sectors we can access only 512 bytes of the memory for our code so to gain access to more memory we have to load in sectors from the hard drive
- Each sector gives access to 512 more bytes
- The addresses of sectors on a disk are stored as LBAs which we convert to CHS format to access them
- `CHS` is short for Cyllinder Head Sector and their values varies as follows Cylinder = 0 to 1023 or 4095, Head = 0 to 15 or 254 or 255, Sector = 1 to 63
- The only way to access disks is through the set of disk access routines that BIOS provides using the `INT 0x13` family of BIOS functions
- To load sectors we have to follow certain steps:
1. Set AH = 2
2. AL = total sector count that needs to loaded (< 128 and != 0)
3. CH = cylinder
4. CL = Sector
5. DH = Head
6. ES:BX -> buffer
7. Set DL = "drive number" -- typically 0x80, for the "C" drive
8. Issue an INT 0x13.

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
        call newline
	mov bx, 0x0000       ; Set bx value for es
	mov es, bx           ; Set es value to bx
	mov bx, 0x7e00       ; Set bx value to specify the address where the sector will be loaded 
	mov ax, 0x0201       ; Set ah as 0x02 (BIOS function to read sectors) and al as 0x01 to load 1 sector
	mov cx, 0x0002       ; Set ch as 0x00 for cylinder and cl as sector number 0x02
	mov dx, 0x0080       ; Set dh as 0x00 for head and dl as 0x80 for C drive number
	int 0x13             ; Access the disk using the 0x13 BIOS interrupt
	mov si, 0x7e00       ; Load the data at the starting of loaded sector into si
	call print
	call newline
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

db "Hello World!",0      ; Write msg into the loaded sector
times 1024-($-$$) db 0   ; Pad the rest of the sector
```

Some other things to keep in mind:
- In real mode, memory addressing is done with segment:offset pairs, which point to a physical memory address
- The physical memory address = (Segment × 16) + Offset, the segment is multiplied by 16 and then added to the offset to get the actual memory address
- `es` and `bx` form one of these segment:offset pairs
- `es` holds the value of the segment in this case 0x0000
- `bx` is for the offset and we choose 0x7e00 because it is just 512 bytes after 0x7c00 and thus doesn't interfere with anything and provides maximum space
- The final address using this `es:bx` pair will be (0x000 x 16) + 0x7e00 = 0x7e00, the sector will be loaded here
- We first set value of `es` using `bx` because `es` can't be given the address directly since it is a segment register
- Instead of setting `ah` and `al` seperately i just directly set value of `ax` since `ax` = `ah` + `al`, similarly for `cx` and `dx`
- `ax` = 0x0201, `ah` = 0x02 (BIOS function to read sectors) and `al` = 0x01 to load 1 sector
- `cx` = 0x0002, `ch` = 0x00 for cylinder value and `cl` = 0x02 i.e sector number (sector 1 is already loaded, its the MBR (Master Boot Record))
- `dx` = 0x0080, `dh` = 0x00 for head value and `dl` = 0x80 for "C" drive number
- `int 0x13` is to access the disk using the `0x13` BIOS interrupt and thus loading the sectors
- We then write our message into the loaded sector and fill the rest with padding, then just print the msg by setting `si` value to the data stored at the starting of the sector and then just using the `print` function

Makefile:

- Added a way to debug using `gdb`

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

# Debug the code
debug: $(BOOT_BIN)
	$(QEMU) -s -S -drive format=raw,file=$(BOOT_BIN)
# use (gdb -ex "target remote localhost:1234") on seperate terminal to connect gdb and qemu
.PHONY: debug
```
