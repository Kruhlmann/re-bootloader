# Re-Bootloader

This project implements a simple AMD64 UEFI bootloader that immediately reboots the system.

Useful as a fall-back disk install in case machines that rely on PXE cannot be configured to auto-retry.

<p align="center">
    <img src="./doc/demo.gif" width="60%" />
</p>

## Dependencies

This project requires the following tools and libraries:

- GCC
- GNU-EFI
- Parted
- mtools
- QEMU + OVMF (for running locally)

### Installing Dependencies

#### Ubuntu/Debian:

```sh
sudo apt-get install gcc gnu-efi parted mtools qemu-system-x86 ovmf
```

#### Fedora/CentOS:

```sh
sudo dnf install gcc gnu-efi parted mtools qemu-system-x86 ovmf
```

#### Arch Linux:

```sh
sudo pacman -S gcc gnu-efi parted mtools qemu ovmf
```

## Building

To build the project, simply run:

```sh
make
```

This will create `reboot.efi` (the UEFI application) and `reboot.img` (a disk image containing the bootloader).

## Running

To test the bootloader in QEMU, run:

```
make run
```

## Customization

The Makefile supports several variables that can be overridden:

- `INCLUDE_DIRS`: Directories to search for header files (default: `/usr/lib`)
- `LD_OBJ`: Path to the UEFI crt0 object file (default: `/usr/lib/crt0-efi-x86_64.o`)
- `EFI_LDS`: Path to the UEFI linker script (default: `/usr/lib/elf_x86_64_efi.lds`)
- `BIOS_FD`: Path to the OVMF BIOS image for QEMU (default: `/usr/share/OVMF/FV/OVMF.fd`)
- `DISK_BLOCK_COUNT`: Number of blocks in the disk image (default: 204800)
- `DISK_BLOCK_SIZE_BYTES`: Size of each block in bytes (default: 512)

Example usage:

```sh
make INCLUDE_DIRS="/path/to/efi/headers" LD_OBJ="/path/to/crt0.o"
```

## Writing to a Disk

To write the bootloader image to a physical disk (use with caution!):

```sh
sudo dd if=reboot.img of=/dev/sdX bs=4M status=progress
```

Replace `/dev/sdX` with the appropriate disk device. Be absolutely certain you're writing to the correct disk, as this will overwrite all existing data.

## How it Works

The bootloader is a minimal UEFI application that calls the UEFI firmware's ResetSystem function to immediately reboot the system. The Makefile compiles this application and creates a GPT-formatted disk image containing an EFI System Partition with the bootloader installed.
