#!/usr/bin/perl
#
# Node configuration 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Node;

eval {
	my $node_config = new Getperf::Node();
	$node_config->parse_command_option();
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
