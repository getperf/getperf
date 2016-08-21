#!/usr/bin/perl
#
# Graphite installation 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Deploy;

my $rc = -1;
eval {
	my $deploy = Getperf::Deploy->new();
	$deploy->parse_command_option;
	$rc = $deploy->config_graphite_init_script || die "config graphite script error";
	$rc = $deploy->create_graphite_repository_db || die "create graphite db error";
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
my $ret = ($rc==1)?0:-1;
exit $ret;
