#!/usr/bin/perl
#
# SSL certification 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::SSL;

my $rc = -1;
eval {
	my $ssl = Getperf::SSL->new();
	$ssl->parse_command_option() || die "parse error";
	$rc = $ssl->run || die "execute error";
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
my $ret = ($rc==1)?0:-1;
exit $ret;