#!/bin/bash

# This is the actual script to be executed if it is found in place.

# This script conains a number of actions to be ecexuted. Each action is defined as
# a shell function here with proper help annotation. They may call external scripts as well.

BASEPATH="$(dirname \"$0\")"

# // CRDEP: build and maintain VM bootale images for the Chrome Remote Desktop EndPoints
# // The following actions are avalable:
# //

# // kernel:  
# //   Rebuild a kernel suitable to run an endpoint (with proper virtio support).
# //   Usually the kernel is built automatically at the first custom endpoint build.
# //

function kernel {
  echo
}

# // baseimg: 
# //   Rebuild a base endpoint image in Docker. (no bootable VM image). The base image contains only 
# //   the minimal shell and a terminal emulator. It may however be deployed as a working endpoint.
# //

function baseimg {
  echo
}

# // help:    
# //   Brief information about this script

# The main script body. If called without parameters or with help as the first parameter, prints all help headers.

[ -z "$1" -o "$1" = "help" ] && {
	grep '^# //' "$0" | sed 's/^# \/\/ \?//g'
	exit 1
}

echo "$@"



