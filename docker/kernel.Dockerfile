# Build the Linux kernel in Docker. Return only the kernel image via tar.

from ubuntu:20.04

run apt -y update
run apt -y upgrade
run apt -y autoremove

run env DEBIAN_FRONTEND=noninteractive apt -y install build-essential wget flex bison bc libelf-dev

# Build the kernel

run wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.85.tar.xz -O linux-5.15.85.tar.xz 
run tar -xf linux-5.15.85.tar.xz
workdir linux-5.15.85
add kernel/linux-5.15.85-config .
run mv linux-5.15.85-config .config
run make -j `nproc`


