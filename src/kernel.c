#include <stdint.h>
#include <stddef.h>

// Kernel main function (must be the first function)
void kernel_main() {
    volatile char *video_memory = (volatile char*) 0xB8000;
    int row = 10, col = 33;  // Change row and column here
    int offset = (row * 80 + col) * 2;  // Calculate correct offset
    char *text = "Kernel Running";  // Text to print

    for (int i = 0; text[i] != '\0'; i++) {
        video_memory[offset + i * 2] = text[i];     // Character
        video_memory[offset + i * 2 + 1] = 0x04;    // Red color
    }

    idt_install();
    // Trigger interrupt vector 0 to test ISR functionality
    asm volatile ("int $0");

    while (1) {
        __asm__ __volatile__("cli; hlt");
    }
}

// Custom memset implementation for freestanding environments
void *my_memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return s;
}

// Define the structure of an IDT entry
struct idt_entry {
    uint16_t base_low;  // Lower 16 bits of the handler's address
    uint16_t sel;       // Kernel segment selector
    uint8_t zero;       // Reserved, always set to 0
    uint8_t flags;      // Type and attributes
    uint16_t base_high; // Higher 16 bits of the handler's address
} __attribute__((packed));

// Define the structure for the IDT pointer
struct idt_ptr {
    uint16_t limit;     // Size of the IDT - 1
    uint32_t base;      // Base address of the IDT
} __attribute__((packed));

// Declare the IDT and its pointer
struct idt_entry idt[256];
struct idt_ptr idtp;

// Function to set an entry in the IDT
void set_idt_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags) {
    idt[num].base_low = base & 0xFFFF;
    idt[num].base_high = (base >> 16) & 0xFFFF;
    idt[num].sel = sel;
    idt[num].zero = 0;
    idt[num].flags = flags;
}

// Function to initialize the IDT
void idt_install() {
    idtp.limit = (sizeof(struct idt_entry) * 256) - 1;
    idtp.base = (uint32_t)&idt;

    // Clear all entries in the IDT using custom memset
    my_memset(&idt, 0, sizeof(struct idt_entry) * 256);

    // Set up IDT entry for interrupt vector 0 (ISR handler)
    extern void isr0_handler(); // Defined in isr.asm
    set_idt_gate(0, (uint32_t)isr0_handler, 0x08, 0x8E);

    // Load the IDT using lidt instruction (implemented in assembly)
    asm volatile ("lidt (%0)" : : "r" (&idtp));
}
