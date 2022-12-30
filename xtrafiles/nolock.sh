#! /bin/sh

logger "Disabling lock screen for the CRDEP user"

/usr/bin/gsettings set org.gnome.desktop.lockdown disable-lock-screen true 
/usr/bin/gsettings set org.gnome.desktop.lockdown disable-log-out true 
/usr/bin/gsettings set org.gnome.desktop.lockdown disable-user-switching true 
/usr/bin/gsettings set org.gnome.desktop.session idle-delay 0

