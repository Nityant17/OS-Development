void kernel_main() {
    volatile char *video_memory = (volatile char*) 0xB8000;
    
    int row = 10, col = 33;  // Change row and column here
    int offset = (row * 80 + col) * 2;  // Calculate correct offset
    char *text = "Kernel Running";  // Text to print

    for (int i = 0; text[i] != '\0'; i++) {
        video_memory[offset + i * 2] = text[i];      // Character
        video_memory[offset + i * 2 + 1] = 0x04;    // Red color
    }

    while (1) {
        __asm__ __volatile__("cli; hlt");
    }
}
