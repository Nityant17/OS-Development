BITS 32
section .text
global _start     ; Define the global entry point for the linker

_start:
    [extern kernel_main]    ; Declare kernel_main as an external function
    call kernel_main        ; Call kernel_main

    cli
    hlt

; GNU Stack Note: Marks this section as non-executable, non-writable, and non-allocatable (needed otherwise gives warning)
section .note.GNU-stack noalloc noexec nowrite progbits

