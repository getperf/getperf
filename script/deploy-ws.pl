#!/usr/bin/perl
#
# Apache, Tomcat, Axis2 Web service installation 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Deploy;

my $rc = -1;
eval {
	my $deploy = Getperf::Deploy->new();
	$deploy->parse_command_option() || die "parse error";
	$rc = $deploy->run || die "execute error";
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
my $ret = ($rc==1)?0:-1;
exit $ret;