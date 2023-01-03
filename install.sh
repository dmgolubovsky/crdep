#! /bin/bash

# Find the first writable directory on user's PATH and install crdep there (ask first)

fstw=""

fstw=$(echo $PATH | sed 's/:/\n/g' | while read ; do [ -d "$REPLY" -a -w "$REPLY" ] && echo $REPLY ; done | head -n 1)

[ -z "$fstw" ] && {
  echo "No writable directories on your PATH"
  exit 1
}

dialog --yesno "Install to\n${fstw}?" 6 $((${#fstw} + 10)) && cp crdep "$fstw"

