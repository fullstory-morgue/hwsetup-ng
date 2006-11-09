#!/bin/bash
# HWSETUP NG - xserver detection
# (C) 2005 Joerg Schirottke <master@kanotix.com>
# (C) 2006 Stefan Lippers-Hollmann

SYS="$(cut -f2 -d: /sys/devices/pci*/{,*/}*/modalias 2>&-)"
unset found found_driver
while read id driver; do
	for sysid in $SYS; do
		case "$sysid" in
			"$id")
				found="$id"
				found_driver="$driver"
				break
				;;
		esac
	done
	
	[ "$found" ] && break
done < <(cut -f2 -d: /usr/share/hwdata/videoaliases)

echo "XSERVER=\"Xorg\""

if [ "$found" ]; then
	echo "XMODULE=\"$found_driver\""
	echo "XDESC=\"$(echo $(lspci -d $(echo $sysid|sed 's/sv.*//;s/v0000//;s/d0000/:/')|sed 's/.*://'))\""
else
	echo "XMODULE=\"vesa\""
	VGA="$(lspci|grep VGA|sed 's/.*://')"
	if [ "$VGA" ]; then
		echo "XDESC=\"$(echo $VGA)\""
	else 
		echo "XDESC=\"Generic VGA card\""
	fi
fi

