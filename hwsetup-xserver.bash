#!/bin/bash
# HWSETUP NG - xserver detection
# (C) 2005 Joerg Schirottke <master@kanotix.com>

SYS=$(cut -f2 -d: /sys/devices/pci*/*/*/modalias)
unset found found_driver

while read id driver; do
	for sysid in $SYS; do
		case $sysid in $id) found=$id; found_driver=$driver; break; esac
		#if [[ $sysid == $id ]]; then found=$id; found_driver=$driver; break; fi
	done
	[ "$found" ] && break
done < <(cut -f2 -d: /usr/share/hwdata/videoaliases)

echo XSERVER=\"$([ -x /usr/X11R6/bin/Xorg ] && echo Xorg || echo XFree86)\"

if [ "$found" ]; then
	echo XMODULE=\"$found_driver\"
	echo XDESC=\"$(echo $(lspci -d $(echo $sysid|sed 's/sv.*//;s/v0000//;s/d0000/:/')|cut -f4- -d:))\"
else
	echo XMODULE=\"vesa\"
	VGA=$(lspci|grep VGA|cut -f4- -d:)

	if [ "$VGA" ]; then
		echo XDESC=\"$VGA\"
	else 
		echo XDESC=\"Generic VGA card\"
	fi
fi

