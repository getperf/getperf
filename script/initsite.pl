#!/usr/bin/perl
#
# Site initialization 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Site;

eval {
	my $site = new Getperf::Site();
	$site->parse_command_option();
	$site->run;
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
