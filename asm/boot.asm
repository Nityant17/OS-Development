; =============
;   REAL MODE
; =============
bits 16        ; Specify that this asm is based on 16 bit arch
org 0x7c00     ; Load the starting memory address for the bootloader

start:    
	; Just printing stuff
	mov ax, 0x03          ; BIOS function to clear the screen
        int 0x10              ; Call BIOS interrupt
	mov si, msg_1         ; Load address of the msg into si
        call print                
        mov esp, 0x9fc00      ; Set the stack segment register
        mov si, msg_2         ; Load the other msg into si
        call push_str       
        call pop_str          
	
	; Load Sectors
	mov bx, 0x0000        ; Set bx value for es
	mov es, bx            ; Set es value to bx to set up the offset
	mov bx, 0x7e00        ; Set bx value to specify the address where the sector will be loaded 
	mov ax, 0x0209        ; Set ah as 0x02 (BIOS function to read sectors) and al as 0x09 to load 1 sector
	mov cx, 0x0002        ; Set ch as 0x00 for cylinder and cl as sector number 0x02
	mov dx, 0x0080        ; Set dh as 0x00 for head and dl as 0x80 for C drive number
	int 0x13              ; Access the disk using the 0x13 BIOS interrupt
	mov si, 0x7e00        ; Load the data at the starting of loaded sector into si
	call print
	;mov ax, 0x03         ; BIOS function to clear the screen
        ;int 0x10             ; Call BIOS interrupt

	; Load Global Descriptor Table
	lgdt [gdt_descriptor] ; Load GDT
	
	; Load Interrupt Descriptor Table
	cli                   ; Clear Interrupts
	lidt [idt_descriptor] ; Load IDT
	sti                   ; Re enable the Interrupts
	
	; Enable A20 using fast gate
	in al, 0x92           ; Read value of port 0x92 i.e Fast A20 Gate
        or al, 0x02           ; Set bit to 1 to enable A20
        out 0x92, al          ; Write back to port 0x92

	; Enable Protected Mode
	mov eax, cr0          ; Load control register 0
        or eax, 1             ; Set PE (Protection Enable) bit to 1 to enable protected mode
        mov cr0, eax          ; Enable Protected Mode

	; Switch to Protected Mode
	jmp 0x08:p_mode       ; Far jump to protected mode (32 bit) 


; ==================
;   PROTECTED MODE
; ==================
bits 32      ; Now in Protected Mode


p_mode:
	; Load Data Segment registers
	mov eax, 0x10          
    	mov ds, eax
    	mov es, eax
    	mov fs, eax
    	mov gs, eax
    	mov ss, eax

    	; Set up stack
    	mov esp, 0x9fc00  
        
        ; VGA memory starts at 0xB8000
        mov edi, (0xb8000 + (80 * 2 * 3))    ; Start at row 4 (skipping 3 rows of 16-bit mode text)    
        mov esi, msg_3                       ; Load the address of the string
        call print_32
	
        jmp 0x08:0x7e10                      ; jump to kernel	
	
	cli                                  ; Clear Interrupts	
	hlt                                  ; Halt the code to prevent executing random memory


; Function to print str in 32 bit protected mode
print_32:
    	mov al, [esi]         ; Load character
        cmp al, 0             ; Check if we reached the null terminator
        je .done              
        mov ah, 0x0F          ; Attribute: White text on black background
        mov [edi], ax         ; Store character and attribute
        add edi, 2            ; Move to the next VGA memory location (2 bytes per char: char + color)
        add esi, 1            ; Move to next character of string (1 byte per char)
        jmp print_32          
.done:
	ret


msg_3: db "Hello, Protected Mode!", 0  ; Null-terminated string


; =============
;   REAL MODE
; =============
bits 16

; Function to print string
print:                        
        mov ah, 0x0e          ; Set the function code in ah register to print
.loop:
        mov al, [si]          ; Load byte from memory at si into al
        cmp al, 0             ; Check for null terminator
        je .done              ; If null, exit
        int 0x10              ; Print character
        inc si                ; Increment si to point to the next byte
        jmp .loop             ; Repeat for next character
.done:
        call newline
	ret                   ; When null terminator reached come out of the function


; Function to push onto stack
push_str:                     
        pop dx                ; Save return address so it doesnt get overwritten on pushing
        mov ah, 0x0e        
        mov cx, 0             ; Counter to track number of characters pushed
.loop:
        mov al, [si]         
        cmp al, 0            
        je .done            
        push ax               ; Push character onto stack
        inc cx                ; Increment counter
        inc si               
        jmp .loop           
.done:
        jmp dx                ; Return safely
          

; Function to pop from stack
pop_str:                      
        pop dx                ; Save return address
        mov ah, 0x0e           
.loop:
        pop ax                ; Pop a character from stack
        cmp cx, 0             ; Check if counter is 0 i.e all elements have been popped
        je .done           
        int 0x10              ; Print character
        dec cx                ; Decrease counter by 1 for each pop
        jmp .loop             
.done:
        call newline
	jmp dx                ; Return safely        


; Function to print newline (\n)
newline:                      
        mov ax, 0x0e0a        ; Set al value as line feed i.e 0aH or 0x0a 
        int 0x10              ; Print the line feed
        mov ax, 0x0e0d        ; Set al value as carriage return i.e 0dH or 0x0d
        int 0x10              ; Print the carriage return 
        ret


; Set up the GDT table and GDT descriptor
gdt_start:
        dq 0                  ; Null Segment (mandatory)
        dq 0x00CF9A000000FFFF ; Code Segment: base=0, limit=0xFFFFF, 32-bit, executable
        dq 0x00CF92000000FFFF ; Data Segment: base=0, limit=0xFFFFF, 32-bit, read/write
gdt_end:

gdt_descriptor:
        dw gdt_end - gdt_start - 1  ; Size (Limit)
        dd gdt_start                ; Base Address/offset


; Set up the IDT table and IDT descriptor (empty for now)
idt_start:
idt_end:

idt_descriptor:
	dw 0  ; Size
	dd 0  ; Base Address/offset


; Load up the strings	
msg_1: db "Welcome to the Bootloader!", 0    ; Define msg as the string followed by the null byte for terminating
msg_2: db "...ssergorP nI", 0                ; The msg here is in reverse as we are printing from stack that follows LIFO

; Padding and loading data into memory 
times 510-($-$$) db 0    ; Fill the empty bytes with zeros
dw 0xaa55                ; Magic bytes to tell the BIOS that this is a bootloader

db "Loaded Sectors!",0   ; Write msg into the loaded sector
;times 1024-($-$$) db 0  ; Pad the rest of the sector
