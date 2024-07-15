FROM debian:bookworm

ENV PATH="/usr/local/bin:${PATH}"
RUN apt-get update && \
    apt-get install -y \
    make \
    gcc \
    gdb \
    binutils \
    build-essential \
    bison \
    flex \
    libelf-dev \
    libssl-dev \
    uuid-dev \
    libncurses5-dev \
    libglib2.0-dev \
    git \
    wget \
    gnu-efi && \
    wget https://ftpmirror.gnu.org/binutils/binutils-2.36.tar.gz && \
    tar xvf binutils-2.36.tar.gz && \
    cd binutils-2.36 && \
    ./configure --target=x86_64-elf --disable-nls --disable-werror && \
    make && \
    make install && \
    wget https://ftpmirror.gnu.org/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz && \
    tar xvf gcc-10.2.0.tar.gz && \
    cd gcc-10.2.0 && \
    ./contrib/download_prerequisites && \
    mkdir build && \
    cd build && \
    ../configure --target=x86_64-elf --disable-nls --enable-languages=c,c++ --without-headers && \
    make all-gcc && \
    make all-target-libgcc && \
    make install-gcc && \
    make install-target-libgcc && \
    x86_64-elf-gcc -v && \
    make --version && \
    gdb --version && \
    ld --version

# Set the entrypoint to bash for an interactive shell
ENTRYPOINT ["/bin/bash"]
