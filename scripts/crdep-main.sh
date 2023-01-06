#!/bin/bash

# This is the actual script to be executed if it is found in place.

# This script conains a number of actions to be ecexuted. Each action is defined as
# a shell function here with proper help annotation. They may call external scripts as well.

SCRIPT="$0"

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

# // new <name>:
# //   Initialize a new endpoint build project in the current directory. It should not be any directory
# //   under the crdep base directory ($HOME/.crdep) or a directory outside the current directory. 
# //   This command creates a default-populated JSON file describing the build. If a project file 
# //   already exists it won't be changed.
# //

function _new {
  [ -z "$1" ] && {
    echo "This action requires one parameter: name of the new JSON build project file to be default-populated."
    echo "Existing project file will not be altered."
    exit 1
  }
  pf="$1"
  curdir=`pwd`
  nosub=$(find "$CRDEPDIR" -wholename "$curdir" -and -type d | wc -l)
  [ $nosub -ne 0 ] && {
    echo "Current directory should not be a subdirectory of $CRDEPDIR"
    exit 1
  }
  projson=""
  canpf=$(readlink -f "$pf") || {
    echo "Cannot canonicalize $pf: parts of its path may not exist"
    exit 1
  }
  incd=$(find "$curdir" -wholename "$(dirname $canpf)" -and -type d | wc -l)
  [ $incd -ne 1 ] && {
    echo "New project file $canpf should be created under the current directory $curdir"
    exit 1
  }
  case "$canpf" in
    *.json)
      projson="$canpf"
      ;;
    *)
      projson="${canpf}.json"
      ;;
  esac
  [ -e "$projson" ] && {
    echo "project file $projson already exists in $curdir"
    exit 1
  }

  projname=$(basename "$projson" .json)

# Default values for a project necessary to create/boot a VM image from the base-crdep pre-generated image.
# Some starting with an underscore are comments (the ony way in JSON) to be populated with the project.

  def__Notes="['Chrome Remote Desktop EndPoint Build Project JSON file', 'Generated by crdep-$(date -r $0 +%d%m%Y) $(date)', 'Project: $projname']"
  def__kernel="$CRDEPDIR/kernel/bzImage"        # kernel path to boot with
  def__base="crdep-base"                        # Docker VM image to start building with
  def__host="$projname"                         # host name to set, same as the project name specified with the command
  def__addspace="2G"                            # how much extra space to add to the QCOW mutable VM image
  def__memory="4096"                            # VM memory size
  def__smp=4                                    # VM CPUs
  def__dfauto=1                                 # autogenerate the Dockerfile
  def__username=$(whoami)                       # username to use for CRD authentication
  def___packages="['install', 'additional', 'packages', 'as needed']"  # comment: to be replaced with an actual list of packages
  def___dfappend="path to custom Dockerfile"    # use this Dockerfile instead of the autgenerated, or append to the autogenerated one

# Collect all the variables that go into the initial JSON and output them.

  {
    echo "{"
    ( 
      set -o posix  
      set | grep "^def__" | 
            sed 's/^def__/\"/g; s/\=/\": \"/g; s/$/\"/g ; s/\\''/\"/g' | 
            tr -d "'" |
            sed 's/\"\[/[/g; s/\]\"/]/g'
    ) | while read ; do echo ${REPLY} "," ; done
    echo '"_":null'}
  } | jq 'del (.. | nulls)' > $projson
}

# // dfgen <name>:
# //   Generate a Dockerfile to build a VM image based on the project JSON file and output to stdout.
# //   Only project name should be provided rather than a path to the project file. 
# //   If dfauto is set to 1, a Dockerfile will be generated on the fly and
# //   if dfappend is defined, the custom Dockerfile will be appended to it. The whole generated Dockerfile
# //   be used to build a VM root image in qcow2 format.
# //

function _dfgen {
  [ -z "$1" ] && {
    echo "This action requires one parameter: name of the project to generate a Dockerfile for."
    echo "Do not provide a file name or path, just the project name."
    exit 1
  }
  prjf=$(readlink -f "$(pwd)/${1}.json")
  [ ! -e "$prjf" ] && {
    echo "The project file $prjf does not exist"
    exit 1
  }

# Generate a Dockerfile to build the image. If dfauto is set to 1 or true then the automatic part
# of the Dockerfile will be generated and output first. If dfappend contains a non-empty path
# to another Dockerfile it will be output next.

# We cannot modify /etc/hosts in the container while building (via the RUN command).
# Instead we create it in another layer under a different name and COPY from there 
# as if it were an added file.

  dfauto=$(jq -r '(.dfauto)' < "$prjf")
  [ "$dfauto" = "1" -o "$dfauto" = "true" ] && {
    echo "# This part of the Dockerfile is autogenerated by crdep-$(date -r $0 +%d%m%Y) $(date)" ; echo
    bi=$(jq -r '(.base)' < "$prjf")
    echo "from $bi as ${bi}__"
    for pkgact in update upgrade autoremove ; do
      echo run apt -y "$pkgact"
    done ; echo
    host=$(jq -r '(.host)' < "$prjf")
    echo "run echo \"$host\" > /etc/hostname" ; echo
    echo "from $bi as ${bi}___"; echo
    echo "run rm -f /etc/hosts-xxx" ; echo
  }
  cat <<<"    127.0.0.1       localhost
    127.0.1.1       $host
    ::1     localhost ip6-localhost ip6-loopback
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters" | while read ; do
      echo "run echo $REPLY >> /etc/hosts-xxx"
  done
  echo "from ${bi}__"; echo
  echo "copy --from=${bi}___ /etc/hosts-xxx /etc/hosts" ; echo
}

# // qcow <name>:
# //   Generate a mutable VM image (qcow2) based on the project JSON file.
# //   Only project name should be provided rather than a path to the project file. 
# //   This action runs the dfgen action on the project JSON file feeding its output to Docker.
# //   The container image built by Docker is returned as a tar archive and next is converted into
# //   a QCOW2 bootable image.
# //

function _qcow {
  [ -z "$1" ] && {
    echo "This action requires one parameter: name of the project to build a QCOW2 image for."
    echo "Do not provide a file name or path, just the project name."
    exit 1
  }
  export prjf=$(readlink -f "$(pwd)/${1}.json")
  [ ! -e "$prjf" ] && {
    echo "The project file $prjf does not exist"
    exit 1
  }
  tar=$(readlink -f "$(pwd)/${1}.tar")
  qcow_large=$(readlink -f "$(pwd)/${1}_large.qcow2")
  qcow=$(readlink -f "$(pwd)/${1}.qcow2")
  "$SCRIPT" dfgen "$1" | {
    env DOCKER_BUILDKIT=1 docker build --output "type=tar,dest=$tar" - &&
    xspc=$(jq -r '(.addspace)' < "$prjf" | sed 's/null//g') &&
    virt-make-fs --type=ext4 --format=qcow2 --size=+"${xspc:-2G}" "$tar" "$qcow_large" &&
    qemu-img convert "$qcow_large" -O qcow2 "$qcow"
  }
  rm -f "$qcow_large"
}

# // authorize <name>:
# //   Authorize the endpoint for Chrome Remote Desktop access and store the authorization
# //   tokens in the QCOW2 VM image while it is mutable.
# //   Only project name should be provided rather than a path to the project file.
# //   This action boots the generated QCOW2 endpoint VM image using the kernel provided
# //   in the project file. Root login is enabled (with password 'crdep'). Upon the login
# //   a dialog window is displayed where authorization code from the Chrome Remote Desktop
# //   website may be pasted, and the endpoint image will be able to connect to the desktop
# //   viewer upon future boots.
# //   This action runs qemu in the user session mode, so only user-mode networking is
# //   available. However the project creator still can make the necessary adjustments
# //   to the image for practical use.
# //

function _authorize {
  [ -z "$1" ] && {
    echo "This action requires one parameter: name of the project to authorize the QCOW2 image for."
    echo "Do not provide a file name or path, just the project name."
    exit 1
  }
  export prjf=$(readlink -f "$(pwd)/${1}.json")
  [ ! -e "$prjf" ] && {
    echo "The project file $prjf does not exist"
    exit 1
  }
  kern=$(readlink -f $(jq -r '(.kernel)' < "$prjf"))
  user=$(jq -r '(.username)' < "$prjf")
  qcow=$(readlink -f "$(pwd)/${1}.qcow2")
  vmem=$(jq -r '(.memory)' < "$prjf" | sed 's/null//g')
  vmsmp=$(jq -r '(.smp)' < "$prjf" | sed 's/null//g')
  qemu-system-x86_64 -m ${vmem:-4096} -smp ${vmsmp:-4} \
    -nographic -no-reboot -no-acpi \
    -drive file="$qcow",format=qcow2 \
    -kernel "$kern" \
    -append "console=ttyS0 root=/dev/vda rw  acpi=off reboot=t panic=-1 cons.lines=`tput lines` cons.cols=`tput cols` crdep.user=$user"
}

# // help:    
# //   Brief information about this script
# //

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

