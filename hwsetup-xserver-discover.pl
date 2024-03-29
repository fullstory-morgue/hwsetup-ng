#!/usr/bin/perl
#   hwsetup-xserver-discover, a Perl script that returns the driver and 
#   description for the videocard detected in the machine it runs on, 
#   plus fallback methods.
#   Copyright (C) 2006  M.L. de Boer a.k.a locsmif <locsmif@kanotix.com>

# All variables must be declared, no symrefs, and misc strict safety checks.
# Remember: "use strict is a good servant, but a bad master, and must be treated
# as such." -- Simon Cozens, author of "Advanced Perl Programming - O'Reilly"
use strict;
# Define constants (via an anonymous hash)
use constant {
	DEBUG => 0,
	VGA => '0300', # Must be quoted! (Else this becomes '192')
	PCILST => '/lib/discover/pci.lst', # Comma goes here because that is allowed. (Think of expansion later)
	SLURP => 0,
};
# Check for File::Slurp, catch errors in $@
eval "require File::Slurp"; 
if ($@) {
	# Errors found, use own emulator
	sub slurp {
	 	open EATFH, "<", $_[0] or die $!; my @lines = <EATFH>; close EATFH;
		return @lines if wantarray;
		chomp $lines[0]; return $lines[0];
	}
	DEBUG and print("Using locsmif's File::Slurp emulator\n");
}
else {
	# Present, import 'slurp' (let's hope Perl 6 comes quick)
	import File::Slurp "slurp"; # slurp will be a Perl6 builtin.
	DEBUG and print("Enabling File::Slurp\n");
}

# Declare variables
my ($desc, $device, $drv, $mod, $pci, $type, $v, $vendor);

# Glob /sys/devices/pci*/*/class and /sys/device/pci*/*/*/class
# Works similar to Bash, returns a list. Shortcut to glob = <..>
for (</sys/devices/pci*/*{,/*}/class>) {
	# Check for type VGA (see use constant at the top)
	if (substr(slurp($_),2,4) eq VGA) { $pci = $_; last; }
}
# Strip '/class' from the end of the path
$pci =~ s|/class$||;
# Get vendor and device
chomp($vendor = substr(slurp("$pci/vendor"),2,4));
chomp($device = substr(slurp("$pci/device"),2,4));

# Open PCILST for reading (see use constant at the top) and associate with 'F'
open(F, "<", PCILST);
while (<F>) {
	# Inside vendor block and new vendor block found? Then exit loop.
	$v and last if /^\w/;
	# Inside vendor?
	if ($v) {
		# Match vendor and device of GFX card found or match fallback driver(ffffffff)?
		if (/^\t(?:${vendor}${device}|ffffffff)\t(\S+)\t(\S+\((\S+)\))\t(.+)$/) { 
			# Get strings captured from backreferences above.
			($type, $drv, $mod, $desc) = ($1, $2, $3, "$v $4");
			# Break loop
			last;
		}
	}
	# Found target vendor block? Set $v with the vendor name captured from backref.
	$v = $1 if (/^$vendor\s+(.*)$/);
}
close(F);
# If module and description are not both set, goto fallback. (Should this be more flexible?)
($mod and $desc) or ($type, $drv, $mod, $desc) = (undef, undef, "vesa", "Unknown device ${vendor}:${device}"); # No need for lspci, it would generate exactly the same output

# Output stuff that can be sourced by shellscripts.
print <<_EOF_
XSERVER="Xorg"
XMODULE="$mod"
XDESC="$desc"
_EOF_
;
exit(0);
