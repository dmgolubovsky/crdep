#!/bin/bash

# This is the actual script to be executed if it is found in place.

# This script conains a number of actions to be ecexuted. Each action is defined as
# a shell function here with proper help annotation. They may call external scripts as well.

BASEPATH="$(dirname \"$0\")"

# // CRDEP: build and maintain VM bootale images for the Chrome Remote Desktop EndPoints
# // The general syntax is: crdep action [parameters]. Action may be abbreviated as long
# // as it is not ambiguous (e. g. "kern" instead of "kernel")
# // The following actions are avalable:
# //

# // kernel:  
# //   Rebuild a kernel suitable to run an endpoint (with proper virtio support) and the init program.
# //   Usually the kernel and init are built automatically at the first custom endpoint build.
# //

function _kernel {
  cd $CRDEPDIR
  DOCKER_BUILDKIT=1 docker build -f ./docker/kernel.Dockerfile -o - . |  tar x linux-5.15.85/arch/x86/boot/bzImage -O > ./kernel/bzImage 
  DOCKER_BUILDKIT=1 docker build -f ./docker/init.Dockerfile -o - .   |  tar x init -O > ./kernel/init 
}

# // baseimg: 
# //   Rebuild a base endpoint image in Docker. (no bootable VM image). The base image contains only 
# //   the minimal shell and a terminal emulator. It may however be deployed as a working endpoint.
# //

function _baseimg {
  cd $CRDEPDIR
  DOCKER_BUILDKIT=1 docker build -f ./docker/crdep-base.Dockerfile -t crdep-base .
}

# // help:    
# //   Brief information about this script

# The main script body. If called without parameters or with help as the first parameter, prints all help headers.

[ -z "$1" -o "$1" = "help" ] && {
	grep '^# //' "$0" | sed 's/^# \/\/ \?//g'
	exit 1
}

# Find if the action has been defined by a function. These functions names start with underscore.

action="_$1"

flist=$(declare -F | awk '{print $NF "\n"}' | grep '^_')

faction=$(echo -n "$flist" | grep "^$action")
fexist=$(echo -n "$flist" | grep "^$action" | wc -l)

[ $fexist -ne 1 ] && {
  echo "The requested action $action is either not defined or ambiguous"
  exit 1
}

shift

"$faction" "$@"

