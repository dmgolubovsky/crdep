from ubuntu:20.04

run apt -y update
run apt -y upgrade
run apt -y autoremove

# Install the most basic things for the minimal endpoint environment

run env DEBIAN_FRONTEND=noninteractive apt -y install util-linux e2fsprogs systemd isc-dhcp-client wget dialog locales ssh sudo mc \
                   software-properties-common inetutils-ping less vim gnome-session gnome-online-accounts nautilus gnome-terminal \
                   squashfs-tools squashfs-tools-ng

run /usr/bin/echo crdep-base >/etc/hostname

# Add / overwrite custom files / remove unneeded

add init /sbin/
add units /lib/systemd/system
add hosts /etc
add issue /etc
add bash_login /root/.bash_login
add crd-auth /usr/bin
add squash /usr/bin
add overlay /usr/bin
add nolock.sh /usr/bin
add nolock.desktop /etc/xdg/autostart
add jl.conf /etc/systemd/journald.conf.d
add fsmod.conf /etc/modules-load.d
add 45-allow-colord.pkla /etc/polkit-1/localauthority/50-local.d
add org.freedesktop.timedate1.policy /usr/share/polkit-1/actions

run rm -f /etc/update-motd.d/* /etc/legal /usr/share/xsessions/gnome.desktop \
	  /usr/share/gnome-session/sessions/gnome-dummy.session \
	  /usr/share/gnome-session/sessions/gnome-login.session


# Configure the network (old way)

run systemctl enable conlog.service
run systemctl enable dhclient@eth0.service
run systemctl enable dhclient@enp1s0.service

# Disable these as they are useless (and Network Manager just gets in the way)

run systemctl disable systemd-resolved.service NetworkManager.service

# Necessary fix so getty will start on the console

run /bin/ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service

# Set temporary password for root

run /bin/sh -c 'echo root:crdep | /usr/sbin/chpasswd'

# Download the Crome Remote Desktop

run wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb

# Install it with dependencies and remove

run sh -c "dpkg -i chrome-remote-desktop_current_amd64.deb || env DEBIAN_FRONTEND=noninteractive apt -yf install"

run rm /chrome-remote-desktop_current_amd64.deb

# Remove these so unnecessary tabs in Gnome settings are not shown

run rm -f \
          /usr/share/applications/gnome-bluetooth-panel.desktop \
          /usr/share/applications/gnome-camera-panel.desktop \
          /usr/share/applications/gnome-sound-panel.desktop \
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
          /usr/share/applications/gnome-color-panel.desktop 

# Other stuff

run locale-gen en_US.UTF-8



