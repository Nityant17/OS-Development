# Directories
ASM_DIR := asm
SRC_DIR := src
OUT_DIR := out

# Output files
BOOT_BIN := $(OUT_DIR)/boot.bin
FUNC_OBJ := $(OUT_DIR)/func.o
ISR_OBJ := $(OUT_DIR)/isr.o
KERNEL_OBJ := $(OUT_DIR)/kernel.o
KERNEL_ELF := $(OUT_DIR)/kernel.elf
KERNEL_BIN := $(OUT_DIR)/kernel.bin
OS_IMAGE := $(OUT_DIR)/os.img

# Sources
ASM_SOURCES := $(ASM_DIR)/func.asm $(ASM_DIR)/isr.asm $(ASM_DIR)/boot.asm
C_SOURCES := $(SRC_DIR)/kernel.c

# Default target
all: pre-config image run

# Ensure output directory exists
pre-config:
	@mkdir -p $(OUT_DIR)
.PHONY: pre-config

# Assemble bootloader as raw binary (real mode)
$(BOOT_BIN): $(ASM_DIR)/boot.asm
	@nasm -f bin -o $@ $<

# Assemble func.asm into an ELF object file (protected mode)
$(FUNC_OBJ): $(ASM_DIR)/func.asm
	@nasm -f elf32 -o $@ $<

# Assemble isr.asm into an ELF object file (protected mode)
$(ISR_OBJ): $(ASM_DIR)/isr.asm
	@nasm -f elf32 -o $@ $<

# Compile kernel C code into an ELF object file (protected mode)
$(KERNEL_OBJ): $(SRC_DIR)/kernel.c
	@gcc -m32 -ffreestanding -Wall -Wextra -nostdlib -c $< -o $@

# Link func.o, isr.o, and kernel.o into a single ELF binary using ld (protected mode)
$(KERNEL_ELF): $(FUNC_OBJ) $(ISR_OBJ) $(KERNEL_OBJ)
	@ld -m elf_i386 -Ttext 0x7e00 -e _start -o $@ $^

# Convert ELF binary to raw binary for bootable image creation (kernel)
$(KERNEL_BIN): $(KERNEL_ELF)
	@objcopy -O binary $< $@

# Create bootable image by concatenating binaries (bootloader + kernel)
image: $(OS_IMAGE)
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	@cat $^ > $@
.PHONY: image

# Run in QEMU emulator (test OS image)
run: $(OS_IMAGE)
	@qemu-system-i386 -drive format=raw,file=$<
.PHONY: run

# Clean build files (cleanup output directory)
clean:
	@rm -rf $(OUT_DIR)
.PHONY: clean

# Debug the code
debug: $(BOOT_BIN)
	@qemu-system-i386 -s -S -drive format=raw,file=$(BOOT_BIN)
# use (gdb -ex "target remote localhost:1234") on seperate terminal to connect gdb and qemu
.PHONY: debug
