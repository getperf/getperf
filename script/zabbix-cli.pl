#!/usr/bin/perl
#
# Zabbix CLI 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Zabbix;

eval {
	my $zabbix = new Getperf::Zabbix();
	$zabbix->parse_command_option();
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
