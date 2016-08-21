#!/usr/bin/perl
#
# RRDtool CLI 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::RRDtool;

eval {
	my $rrd = new Getperf::RRDtool();
	$rrd->parse_command_option();
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
