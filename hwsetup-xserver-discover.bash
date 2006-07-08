#!/bin/bash
# HWSETUP NG - xserver detection - discover database variant
# (C) 2005-2006 Joerg Schirottke <master@kanotix.com>
SYS=$(cut -f2 -d: /sys/devices/pci*/{,*/}*/modalias 2>&-)
unset found found_driver
while read id driver; do
 for sysid in $SYS; do
  case $sysid in $id) found=$id; found_driver=$driver; break; esac
  #if [[ $sysid == $id ]]; then found=$id; found_driver=$driver; break; fi
 done
 [ "$found" ] && break
done < <(awk -F'[\t()]' '/Server:XFree86/ && length($2)==8 {print "v0000" toupper(substr($2,0,4)) "d0000" toupper(substr($2,5,4)) "sv*sd*bc*sc*i* "$5}' /lib/discover/pci.lst)
echo XSERVER=\"$([ -x /usr/X11R6/bin/Xorg ] && echo Xorg || echo XFree86)\"
if [ "$found" ]; then
 echo XMODULE=\"$found_driver\"
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
