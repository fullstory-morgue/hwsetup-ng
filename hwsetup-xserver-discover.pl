#!/usr/bin/perl
#   hwsetup-xserver-discover, a Perl script that returns the driver and 
#   description for the videocard detected in the machine it runs on, 
#   plus fallback methods.
#   Copyright (C) 2006  M.L. de Boer a.k.a locsmif <locsmif@kanotix.com>

use strict;
use constant {
	DEBUG => 0,
	VGA => '0300', # Must be quoted! (Else this becomes '192')
	PCILST => '/lib/discover/pci.lst', # Comma goes here because that is allowed. (Think of expansion later)
	SLURP => 1,
};
eval "require File::Slurp"; 
if ($@) {
	sub slurp {
	 	open EATFH, "<", $_[0] or die $!; my @lines = <EATFH>; close EATFH;
		return @lines if wantarray;
		chomp $lines[0]; return $lines[0];
	}
	DEBUG and print("Using locsmif's File::Slurp emulator\n");
}
else {
	import File::Slurp "slurp"; # slurp will be a Perl6 builtin.
	DEBUG and print("Enabling File::Slurp\n");
}

my ($desc, $device, $drv, $id, $mod, $pci, $type, $v, $vendor);
my @arr;
my %h;

for (</sys/devices/pci*/*{,/*}/class>) { 
	if (substr(slurp($_),2,4) eq VGA) { $pci = $_; last; }
}
$pci =~ s|/class$||;

chomp($vendor = substr(slurp("$pci/vendor"),2,4));
chomp($device = substr(slurp("$pci/device"),2,4));

open(F, "<", PCILST);
while (<F>) {
	$v and last if /^\w/;
	$v = $1 if (/^$vendor\s+(.*)$/);
	if ($v) {
		if (/^\t(?:${vendor}${device}|ffffffff)\t(\S+)\t(\S+\((\S+)\))\t(.+)$/) { 
			($type, $drv, $mod, $desc) = ($1, $2, $3, "$v $4");
			last;
		}
	}
}
close(F);
($mod and $desc) or ($type, $drv, $mod, $desc) = (undef, undef, "vesa", "Unknown device ${vendor}:${device}"); # No need for lspci, it would generate exactly the same output

print <<_EOF_
XSERVER="Xorg"
XMODULE="$mod"
XDESC="$desc"
_EOF_
;
exit(0);
