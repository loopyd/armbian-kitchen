#!/usr/bin/env bash

# Set the default desktop session for XRDP
if [[ -n "$XRDP_SESSION" && -z "$DESKTOP_SESSION" ]]; then
  DESKTOPS=$(ls -1 /usr/share/xsessions | sed -n -e "s/\.desktop$//p")
  DESKTOP_SESSION=$(echo "$DESKTOPS" | head -n1)
  if [ "$(echo "$DESKTOPS" | wc -l)" != "1" ]; then
    SESSIONPROP=XSession
    if cat /etc/X11/default-display-manager | grep -sq lightdm; then
      SESSIONPROP=Session
    fi
    SAVEDSESSION=$(busctl get-property org.freedesktop.Accounts /org/freedesktop/Accounts/User$(id -u) org.freedesktop.Accounts.User $SESSIONPROP | cut -d\" -f2)
    if [ -f /usr/share/xsessions/${SAVEDSESSION}.desktop ]; then
      DESKTOP_SESSION=$SAVEDSESSION
    else
      for DESKTOP in $DESKTOPS; do
        if  [ x$DESKTOP = xubuntu ]; then DESKTOP_SESSION=ubuntu; break
        elif  [ x$DESKTOP = xgnome ]; then DESKTOP_SESSION=gnome; break
        elif  [ x$DESKTOP = xmate ]; then DESKTOP_SESSION=mate; break
        elif  [ x$DESKTOP = xlxde ]; then DESKTOP_SESSION=lxde; break
        elif  [ x$DESKTOP = xlxqt ]; then DESKTOP_SESSION=lxqt; break
        elif  [ x$DESKTOP = xplasma ]; then DESKTOP_SESSION=plasma; break
        elif  [ x$DESKTOP = xxfce ]; then DESKTOP_SESSION=xfce; break
        fi
      done
    fi
  fi
  export DESKTOP_SESSION
fi