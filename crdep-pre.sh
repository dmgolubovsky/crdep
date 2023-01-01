#! /bin/bash

# crdep: create and manage VM images for Chrome Remote Desktop EndPoints
# pre-script

# The crdep script is distributed as a SHAR self-unpacking archive. A user is expected to place it in any
# location in their $PATH. When downloaded first it looks in the current user's home directory for a subdirectory 
# named .crdep and, if such subdirectory does not exist, creates it and extracts the SHAR'ed files there. 
# If such subdirectory exists it looks for a shell script located in $HOME/.crdep/scripts/crdep-main.sh and executes it
# for any further action. Therefore, to reinstall the whole tool, just the $HOME/.crdep subdrectory has to be removed,
# and the script re-downloaded.

# Look if the target script exists and if not, unshar itself there.

export CRDEPDIR="$HOME/.crdep" 

[ -x "$CRDEPDIR/scripts/crdep-main.sh" ] && {
  "$CRDEPDIR/scripts/crdep-main.sh" "$@"
  exit 0
} || {
  mkdir -p "$CRDEPDIR"
  cd "$CRDEPDIR"

# shar contents goes here and the closing bracket added by Makefile #


