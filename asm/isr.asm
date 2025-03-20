bits 32
section .text
global isr0_handler

; ISR for interrupt vector 0
isr0_handler:
    pusha                     ; Save all general-purpose registers
    mov esi, messag           ; Load the address of the message into esi
    call print_message        ; Call the function to print the message
    popa                      ; Restore all general-purpose registers
    iret                      ; Return from interrupt

; Function to print a message to VGA memory
print_message:
    mov edi, (0xB8000+ ((80*11+32)*2))          ; VGA memory starts at 0xB8000
.loop:
    mov al, [esi]
    cmp al, 0                 ; Check if it's the null terminator
    je .done                  ; If null terminator, exit loop
    mov ah, 0x0F
    mov [edi], ax             ; Write character to VGA memory
    add esi, 1
    add edi, 2                ; Move to next character position in VGA memory
    jmp .loop                 ; Repeat for next character
.done:
    ret                       ; Return from function

section .data
messag: db "First Interrupt!", 0            ; Null-terminated string

; GNU Stack Note: Marks this section as non-executable, non-writable, and non-allocatable (needed otherwise gives warning)
section .note.GNU-stack noalloc noexec nowrite progbits
