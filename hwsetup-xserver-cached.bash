#!/bin/bash
# HWSETUP NG - xserver detection (precached mode)
# (C) 2005 Joerg Schirottke <master@kanotix.com>
count=0
unset VIDEO_ID VIDEO_DRIVER
while read id driver; do
 VIDEO_ID[$count]="$id"
 VIDEO_DRIVER[$count]="$driver"
 ((count++))
done < <(cut -f2 -d: /usr/share/hwdata/videoaliases)
((count--))
SYS=$(cut -f2 -d: /sys/devices/pci*/{,*/}*/modalias 2>&-)
unset found 
for id in $(seq 0 $count); do
 for sysid in $SYS; do
  case $sysid in ${VIDEO_ID[$id]}) found=$id; break; esac
  #if [[ $sysid == ${VIDEO_ID[$id]} ]]; then found=$id; break; fi
 done
 [ "$found" ] && break
done
echo XSERVER=\"$([ -x /usr/X11R6/bin/Xorg ] && echo Xorg || echo XFree86)\"
if [ "$found" ]; then
 echo XMODULE=\"${VIDEO_DRIVER[$found]}\"
 echo XDESC=\"$(echo $(lspci -d $(echo $sysid|sed 's/sv.*//;s/v0000//;s/d0000/:/')|sed 's/.*://'))\"
else
 echo XMODULE=\"vesa\"
 VGA=$(lspci|grep VGA|sed 's/.*://')
 if [ "$VGA" ]; then
  echo XDESC=\"$(echo $VGA)\"
 else 
  echo XDESC=\"Generic VGA card\"
 fi
fi
