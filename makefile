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
