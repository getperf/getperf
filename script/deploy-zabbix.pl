#!/usr/bin/perl
#
# Zabbix installation 
#

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Deploy;

my $rc = -1;
eval {
	my $deploy = Getperf::Deploy->new();
	$deploy->parse_command_option;
	my $os_distribution = `head -1 /etc/issue| cut -f1 -d' '`;
	chomp($os_distribution);
	if ($os_distribution eq 'Ubuntu') {
		$rc = $deploy->create_zabbix_repository_db_ubuntu || die "execute error";
	} else {
		$rc = $deploy->create_zabbix_repository_db || die "execute error";
	}
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
my $ret = ($rc==1)?0:-1;
exit $ret;
