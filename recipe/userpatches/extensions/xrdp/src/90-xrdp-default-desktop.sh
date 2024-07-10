#!/usr/bin/env bash
# Set the default desktop session for XRDP
if [ -n "$XRDP_SESSION" -a -z "$DESKTOP_SESSION" ]; then
  DESKTOPS=$(ls -1 /usr/share/xsessions | sed -n -e "s/\.desktop$//p")
  DESKTOP_SESSION=$(echo "$DESKTOPS" | head -n1)
  if [ "$(echo "$DESKTOPS" | wc -l)" != "1" ]; then
    SESSIONPROP=XSession
    if cat /etc/X11/default-display-manager | grep -sq gdm3; then
      if [ $(/usr/sbin/gdm3 --version | cut -d" " -f2 | cut -d. -f1) -ge 40 ]; then SESSIONPROP=Session; fi
    fi
    SAVEDSESSION=$(busctl get-property org.freedesktop.Accounts /org/freedesktop/Accounts/User$(id -u) org.freedesktop.Accounts.User $SESSIONPROP | cut -d\" -f2)
    if [ -f /usr/share/xsessions/${SAVEDSESSION}.desktop ]; then
      DESKTOP_SESSION=$SAVEDSESSION
    else
      for DESKTOP in $DESKTOPS; do
        if  [ x$DESKTOP = xubuntu ]; then DESKTOP_SESSION=ubuntu; break
        elif  [ x$DESKTOP = xgnome ]; then DESKTOP_SESSION=gnome; fi
      done
    fi
  fi
  export DESKTOP_SESSION
fi