bits 16		; Specify that this asm is based on 16 bit arch
org 0x7c00	; Load the starting memory address for the bootloader

start:	
	mov ax, 0x03 		; BIOS function to clear the screen
	int 0x10		; Call BIOS interrupt
	mov si, mesg    	; Load address of the msg into si
	call print		
	call newline		
	mov esp, 0x9fc00	; Set the stack segment register
	mov si, msg		; Load the other msg into si
	call push_str   	
	call pop_str	  	
	jmp $			; Jump to itself to create an infinite loop and keep the bootloader running


print:	      			; Function to print the string
	mov ah, 0x0e   		; Set the function code in ah register to print
.loop:
    	mov al, [si]  		; Load byte from memory at si into al
   	cmp al, 0     		; Check for null terminator
    	je .done      		; If null, exit
    	int 0x10      		; Print character
    	inc si        		; Increment si to point to the next byte
    	jmp .loop     		; Repeat for next character
.done:
	ret	      		; When null terminator reached come out of the function


push_str:            		; Function to push string onto the stack
    	pop dx          	; Save return address so it doesnt get overwritten on pushing
    	mov ah, 0x0e		
	mov cx, 0        	; Counter to track number of characters pushed
.loop:
    	mov al, [si]     	
    	cmp al, 0        	
    	je .done        	
    	push ax          	; Push character onto stack
    	inc cx           	; Increment counter
    	inc si           	
    	jmp .loop       	
.done:
    	jmp dx           	; Return safely
          

pop_str:             		; Function to print by popping from stack
    	pop dx          	; Save return address
    	mov ah, 0x0e       	
.loop:
    	pop ax             	; Pop a character from stack
    	cmp cx, 0          	; Check if counter is 0 i.e all elements have been popped
    	je .done           
    	int 0x10           	; Print character
    	dec cx			; Decrease counter by 1 for each pop
    	jmp .loop         	
.done:
    	jmp dx           	; Return safely        


newline:			; Function to print newline (\n)
	mov ah, 0x0e
	mov al, 0x0a		; Set al value as line feed i.e 0aH or 0x0a 
	int 0x10		; Print the line feed
	mov ah, 0x0e
	mov al, 0x0d		; Set al value as carriage return i.e 0dH or 0x0d
	int 0x10		; Print the carriage return 
	ret


mesg: db "Welcome to the Bootloader!", 0  	; Define msg as the string followed by the null byte for terminating
msg: db "...ssergorP nI", 0			; The msg here is in reverse as we are printing from stack that follows LIFO

times 510-($-$$) db 0	; Fill the empty bytes with zeros
dw 0xaa55				; Magic bytes to tell the BIOS that this is a bootloader
