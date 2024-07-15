.POSIX:
.DELETE_ON_ERROR:

INCLUDE_DIRS ?= /usr/lib
LD_OBJ ?= /usr/lib/crt0-efi-x86_64.o
EFI_LDS ?= /usr/lib/elf_x86_64_efi.lds
BIOS_FD ?= /usr/share/OVMF/FV/OVMF.fd
LD_EXTRA ?= 
DISK_BLOCK_COUNT ?= 204800
DISK_BLOCK_SIZE_BYTES ?= 512

CC := gcc
CFLAGS := -c -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER $(addprefix -I,$(INCLUDE_DIRS))
LDFLAGS := $(LD_OBJ) -nostdlib -znocombreloc -T $(EFI_LDS) -shared -Bsymbolic -lgnuefi -lefi $(LD_EXTRA)
QEMUFLAGS := -bios $(BIOS_FD) -nographic -serial mon:stdio 
OBJCOPYFLAGS := -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64

.PHONY: all
all: reboot.efi

.PHONY: run
run: reboot.img
	qemu-system-x86_64 -drive file=$<,format=raw $(QEMUFLAGS)

reboot.img: main.efi
	dd if=/dev/zero of=$@ bs=$(DISK_BLOCK_SIZE_BYTES) count=$(DISK_BLOCK_COUNT)
	parted -s $@ mklabel gpt
	parted -s $@ mkpart EFI fat32 2048s 100%
	parted -s $@ set 1 esp on
	$(eval ESP_OFFSET := $(shell parted -s $@ unit b print | grep EFI | awk '{print $$2}' | tr -d 'B'))
	mformat -i $@@@$(ESP_OFFSET) -h 32 -t 32 -n 64 -c 1 ::
	mmd -i $@@@$(ESP_OFFSET) ::/EFI
	mmd -i $@@@$(ESP_OFFSET) ::/EFI/BOOT
	mcopy -i $@@@$(ESP_OFFSET) $< ::/EFI/BOOT/BOOTX64.EFI

%.efi: %.so
	objcopy $(OBJCOPYFLAGS) $< $@

%.o: %.c
	$(CC) $< $(CFLAGS) -o $@

%.so: %.o
	ld $< $(LDFLAGS) -o $@

.PHONY:
clean:
	rm *.o *.so *.efi reboot.img
