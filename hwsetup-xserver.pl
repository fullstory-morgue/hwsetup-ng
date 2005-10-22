#!/usr/bin/perl
sub eat {
  open EATFH, "<", $_[0] or die $!; my @lines = <EATFH>; close EATFH;
  return @lines if wantarray;
  chomp $lines[0]; return $lines[0];
}

sub cmp_pci_id {
  my($vendor_id, $device_id, $subsysl, $subsysh) = @_;
  while (<PCIDS>) {
    chomp;
    if (/^([0-9A-Fa-f]{4}) +(.*)$/ and $1 eq $vendor_id) {
      my $vendor = $2;
      while (<PCIDS>) {
        chomp;
        last if (/^[0-9A-Fa-f]{4}.*$/);
        if (/^\t([0-9A-Fa-f]{4}) +(.*)$/ and $1 eq $device_id) {
          my $tmp = $2;
          while (<PCIDS>) {
            chomp;
            return($vendor, $tmp) if (/^\t[0-9A-Fa-f]{4}.*/);
            if (/^\t\t([0-9A-Fa-f]{4}) +([0-9A-Fa-f]{4}) +(.*)$/ and $1 eq $subsysl and $2 eq $subsysh) {
              return($vendor, $3);
            };
          };
        };
      };
    };
  };
};

for (glob "/sys/devices/pci*/*/*") { 
	if (-f "$_/class" and substr((eat "$_/class"),2,4) eq "0300") { 
		$id = eat "$_/modalias";
		($vendor, $device, $subvendor, $subdevice) = (lc $id) =~ /^.+:v.{4}(.{4})d.{4}(.{4})sv.{4}(.{4})sd.{4}(.{4}).+$/ or die "Unknown modalias format";
	};
};

open VIDAL, "<", "/usr/share/hwdata/videoaliases" or die "could not open videoaliases";
open PCIDS, "<", "/usr/share/hwdata/pci.ids" or die "could not open pci.ids";
while (<VIDAL>) {
  chomp; $tmp = $_;
  s/^alias .+:(.+) .+$/$1/;
  s/\*/.*/g;
  $rgx = "^.*$_.*\$";
  if ($id =~ /$rgx/) {
    $xmod = (split " ", $tmp)[-1];
    print "XSERVER=\"" . (-x "/usr/X11R6/bin/Xorg" ? "Xorg" : "XFree86") . "\"\n";
    print "XMODULE=\"$xmod\"\n";
    @desc = cmp_pci_id($vendor, $device, $subvendor, $subdevice);
    print "XDESC=\"@desc\"\n";
    break; 
  };
#  print "$_ =~ $t\n" if ($id =~ /$rgx/);
};
close VIDAL;
close PCIDS;
