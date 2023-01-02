# Build the init program in Docker. Return only the program executable via tar.

from ubuntu:20.04

run apt -y update
run apt -y upgrade
run apt -y autoremove

run env DEBIAN_FRONTEND=noninteractive apt -y install build-essential

# Build the program

add xtrafiles/init.c .
run gcc -Wall -o init -static init.c
run strip init

