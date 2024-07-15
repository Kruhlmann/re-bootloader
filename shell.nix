{ pkgs ? import <nixpkgs> {} }:

let
  customizedOVMF = pkgs.OVMF.override {
    secureBoot = true;
    tpmSupport = true;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    gnumake
    gcc
    gnu-efi
    pkgsCross.x86_64-embedded.buildPackages.gcc
    qemu
    gdb
    binutils
    mtools
    customizedOVMF.fd
  ];

  shellHook = ''
    export PATH="$PATH:${pkgs.pkgsCross.x86_64-embedded.buildPackages.gcc}/bin"
    export BIOS_FD="${customizedOVMF.fd}/FV/OVMF.fd"
    export EFI_LDS="${pkgs.gnu-efi}/lib/elf_x86_64_efi.lds"
    export LD_OBJ="${pkgs.gnu-efi}/lib/crt0-efi-x86_64.o"
    export INCLUDE_DIRS="${pkgs.gnu-efi}/include/efi"
  '';
}
