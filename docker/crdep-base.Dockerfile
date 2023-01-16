# Build the base image for Chrome Remote Desktop EndPoint.
# The base image is to be reused by custom endpoint builds.
# It contains only the very basic GNOME shell, the Gnome Online Accounts package,
# and the Chrome Remote Desktop package. This image is not intended to be deployed,
# but it is fully functional.

from ubuntu:20.04 as crdep-base

run apt -y update
run apt -y upgrade
run apt -y autoremove

# Install the most basic things for the minimal endpoint environment

run env DEBIAN_FRONTEND=noninteractive apt -y install util-linux e2fsprogs systemd isc-dhcp-client wget dialog locales openssh-client sudo mc \
                   software-properties-common inetutils-ping less vim gnome-session gnome-online-accounts nautilus gnome-terminal \
                   squashfs-tools squashfs-tools-ng sed zenity

run env DEBIAN_FRONTEND=noninteractive apt -y --no-install-recommends --no-install-suggests install cloud-init

# The hostname for this endpoint is "crdep-base"

run /usr/bin/echo crdep-base >/etc/hostname

# Add / overwrite custom files / remove unneeded

add kernel/init /sbin/
add xtrafiles/units /lib/systemd/system
add xtrafiles/hosts /etc
add xtrafiles/squash.issue /etc
add xtrafiles/issue /etc
add xtrafiles/bash_login /root/.bash_login
add xtrafiles/crd-auth /usr/bin
add xtrafiles/squash /usr/bin
add xtrafiles/overlay /usr/bin
add xtrafiles/nolock.sh /usr/bin
add xtrafiles/nolock.desktop /etc/xdg/autostart
add xtrafiles/ushutdn.desktop /usr/share/applications
add xtrafiles/rpulse.desktop /usr/share/applications
add xtrafiles/jl.conf /etc/systemd/journald.conf.d
add xtrafiles/fsmod.conf /etc/modules-load.d
add xtrafiles/45-allow-colord.pkla /etc/polkit-1/localauthority/50-local.d
add xtrafiles/org.freedesktop.timedate1.policy /usr/share/polkit-1/actions
add xtrafiles/org.freedesktop.consolekit.policy /usr/share/polkit-1/actions
add xtrafiles/nogetty.conf /etc/systemd/system/getty-static.service.d/
add xtrafiles/nogetty.conf /etc/systemd/system/getty@.service.d/
add xtrafiles/nogetty.conf /etc/systemd/system/serial-getty@.service.d/
add xtrafiles/nogetty.conf /etc/systemd/system/container-getty@.service.d/
add xtrafiles/nogetty.conf /etc/systemd/system/console-getty.service.d/


# Enable shutdown when a user creates /tmp/ushutdn.tmp

run systemctl enable ushutdn.path

# Configure the network (old way)

run systemctl enable dhclient@eth0.service

# Enable squash service (but it runs only if the kernel command line has do.squash=yes)

run systemctl enable squash.service

# Disable these as they are useless (and Network Manager just gets in the way)

run systemctl disable systemd-resolved.service NetworkManager.service

# Necessary fix so getty will start on the console

run /bin/ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service

# Set temporary password for root

run /bin/sh -c 'echo root:crdep | /usr/sbin/chpasswd'

# Download the Chrome Remote Desktop

run wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb

# Install it with dependencies and remove

run sh -c "dpkg -i chrome-remote-desktop_current_amd64.deb || env DEBIAN_FRONTEND=noninteractive apt -yf install"

run rm /chrome-remote-desktop_current_amd64.deb

# Remove these so unnecessary tabs in Gnome settings are not shown 
# Remove few other unneeded files as well

run rm -f \
          /usr/share/applications/gnome-bluetooth-panel.desktop \
          /usr/share/applications/gnome-camera-panel.desktop \
          /usr/share/applications/gnome-microphone-panel.desktop \
          /usr/share/applications/gnome-power-panel.desktop \
          /usr/share/applications/gnome-sharing-panel.desktop \
          /usr/share/applications/gnome-lock-panel.desktop \
          /usr/share/applications/gnome-printers-panel.desktop \
          /usr/share/applications/gnome-network-panel.desktop \
          /usr/share/applications/gnome-thunderbolt-panel.desktop \
          /usr/share/applications/gnome-removable-media-panel.desktop \
          /usr/share/applications/gnome-connectivity-panel.desktop \
          /usr/share/applications/gnome-user-accounts-panel.desktop \
          /usr/share/applications/gnome-notifications-panel.desktop \
          /usr/share/applications/gnome-display-panel.desktop \
          /usr/share/applications/gnome-location-panel.desktop \
          /usr/share/applications/gnome-diagnostics-panel.desktop \
          /usr/share/applications/gnome-usage-panel.desktop \
          /usr/share/applications/gnome-info-overview-panel.desktop \
          /usr/share/applications/gnome-color-panel.desktop \
          /etc/update-motd.d/* /etc/legal /usr/share/xsessions/gnome.desktop \
	  /usr/share/gnome-session/sessions/gnome-dummy.session \
	  /usr/share/gnome-session/sessions/gnome-login.session

# Other stuff

run locale-gen en_US.UTF-8

# Remove poweroff as it does not exit qemu cleanly and make it do reboot

run rm /sbin/poweroff

run echo exec /sbin/reboot \"\$\@\" > /sbin/poweroff
run chmod +x /sbin/poweroff

from scratch

copy --from=crdep-base / /


