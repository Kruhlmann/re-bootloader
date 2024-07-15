.POSIX:
.DELETE_ON_ERROR:

INCLUDE_DIRS ?= /usr/lib
LD_OBJ ?= /usr/lib/crt0-efi-x86_64.o
EFI_LDS ?= /usr/lib/elf_x86_64_efi.lds
BIOS_FD ?= /usr/share/OVMF/FV/OVMF.fd
DISK_BLOCK_COUNT ?= 204800
DISK_BLOCK_SIZE_BYTES ?= 512
DISK_SIZE_MiB := $(shell echo $$(($(DISK_BLOCK_COUNT) * $(DISK_BLOCK_SIZE_BYTES) / 1024)))

CFLAGS := -c -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER $(addprefix -I,$(INCLUDE_DIRS))
LDFLAGS := -nostdlib -znocombreloc -T $(EFI_LDS) -shared -Bsymbolic -L ./ -l:libgnuefi.a -l:libefi.a
QEMUFLAGS := -bios $(BIOS_FD) -nographic -serial mon:stdio 

.PHONY: all
all: reboot.efi

.PHONY: run
run: reboot.img
	qemu-system-x86_64 -drive file=$<,format=raw $(QEMUFLAGS)


reboot.img: reboot.efi
	dd if=/dev/zero of=$@ bs=$(DISK_BLOCK_SIZE_BYTES) count=$(DISK_BLOCK_COUNT)
	parted -s $@ mklabel gpt
	parted -s $@ mkpart EFI fat32 2048s 100%
	parted -s $@ set 1 esp on
	$(eval ESP_OFFSET := $(shell parted -s $@ unit b print | grep EFI | awk '{print $$2}' | tr -d 'B'))
	mformat -i $@@@$(ESP_OFFSET) -h 32 -t 32 -n 64 -c 1 ::
	mmd -i $@@@$(ESP_OFFSET) ::/EFI
	mmd -i $@@@$(ESP_OFFSET) ::/EFI/BOOT
	mcopy -i $@@@$(ESP_OFFSET) reboot.efi ::/EFI/BOOT/BOOTX64.EFI

reboot.efi: main.so
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 $< $@

%.o: %.c
	gcc $< $(CFLAGS) -o $@

%.so: %.o
	ld $< $(LD_OBJ) $(LDFLAGS) -o $@

clean:
	rm *.o *.so reboot.efi reboot.img
