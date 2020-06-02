#!/usr/bin/perl
#
# Site sync 
#

use strict;
use FindBin;
use Path::Class;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::GetconfigSync;

eval {
	my $monitor = Getperf::GetconfigSync->new;
	$monitor->parse_command_option();
	$monitor->run;
#	$monitor->unzip;
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
