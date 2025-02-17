# Directories
ASM_DIR := asm
SRC_DIR := src
OUT_DIR := out

# Tools
NASM := nasm
CC := gcc
LD := ld
QEMU := qemu-system-i386
MKDIR := mkdir -p
RM := rm -rf
OBJCOPY := objcopy
DD := dd

# Flags
NFLAGS := -f bin
CFLAGS := -m32 -ffreestanding -Wall -Wextra -nostdlib
LDFLAGS := -m elf_i386

# Output files
BOOT_BIN := $(OUT_DIR)/boot.bin
KERNEL_BIN := $(OUT_DIR)/kernel.bin
KERNEL_ELF := $(OUT_DIR)/kernel.elf
OS_IMAGE := $(OUT_DIR)/os.img

# Sources
ASM_SOURCES := $(ASM_DIR)/boot.asm
C_SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OUT_DIR)/%.o,$(C_SOURCES))

# Default target
#default: pre-config bootloader kernel image run
all: pre-config bootloader kernel image run

# Ensure output directory exists
pre-config:
	@$(MKDIR) $(OUT_DIR)
.PHONY: pre-config

# Assemble bootloader
bootloader: $(BOOT_BIN)
$(BOOT_BIN): $(ASM_SOURCES)
	$(NASM) $(NFLAGS) -o $@ $<
.PHONY: bootloader

# Compile C kernel
kernel: $(KERNEL_BIN)
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

$(KERNEL_ELF): $(OBJ_FILES)
	$(LD) $(LDFLAGS) -o $@ $^

$(OUT_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# OVERKILL
#image: $(OS_IMAGE)
#$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	# Create an empty image with 1 sectors (of 512 bytes)
	#$(DD) if=/dev/zero of=$@ bs=512 count=200
	# Copy the bootloader at the start
	#$(DD) if=$(BOOT_BIN) of=$@ conv=notrunc
	# Copy the kernel binary at address 0x7e00 (the 64th sector)
	#$(DD) if=$(KERNEL_BIN) of=$@ bs=1 seek=528 conv=notrunc
#.PHONY: image

# Create bootable image
image: $(OS_IMAGE)
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	# Concatenate the bootloader and kernel binary into a single image
	cat $(BOOT_BIN) $(KERNEL_BIN) > $@
.PHONY: image

# Run in QEMU
run: $(OS_IMAGE)
	$(QEMU) -drive format=raw,file=$(OS_IMAGE)
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
