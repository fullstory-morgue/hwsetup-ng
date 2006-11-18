#!/bin/sh
# HWSETUP NG - xserver detection - discover database variant
# (C) 2005-2006 Joerg Schirottke <master@kanotix.com>
# (C) 2006 Stefan Lippers-Hollmann <s.l-h@gmx.de>

SYS="$(cut -f2 -d: /sys/devices/pci*/*/modalias /sys/devices/pci*/*/*/modalias|grep 03sc00)"

unset found found_driver
while read id driver; do
	for sysid in $SYS; do
		case "$sysid" in
			$id)
				found="$id"
				found_driver="$driver"
				break
				;;
		esac
	done
	[ "$found" ] && break
done <<EOT
$(gawk -F'[\t()]' '/Server:XFree86/ && length($2)==8 {print "v0000" toupper(substr($2,0,4)) "d0000" toupper(substr($2,5,4)) "sv*sd*bc*sc*i* "$5}' /lib/discover/pci.lst)
EOT

echo "XSERVER=\"Xorg\""

if [ "$found" ]; then
	echo "XMODULE=\"$found_driver\""
	echo "XDESC=\"$(echo $(lspci -d $(echo $sysid|sed 's/sv.*//;s/v0000//;s/d0000/:/')|sed 's/.*://'))\""
else
	VENDOR=$(echo $sysid|sed -r 's/^v0000(\w\w\w\w).*/\1/'|gawk '{print tolower($1)}')
	DRIVER=$(sed -n '/^'$VENDOR'/,/^[0-9]/ s/\tffffffff\t.*(\([^)]*\)).*$/\1/p' /lib/discover/pci.lst)
	[ -z "$DRIVER" ] && DRIVER=vesa

	echo "XMODULE=\"$DRIVER\""
	VGA="$(lspci|grep VGA|sed 's/.*://')"
	if [ "$VGA" ]; then
		echo "XDESC=\"$(echo $VGA)\""
	else 
		echo "XDESC=\"Generic VGA card\""
	fi
fi
