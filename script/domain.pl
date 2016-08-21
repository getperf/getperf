#!/usr/bin/perl
# 
# TODO : Create specifications 
# Domain registration 
# 

use strict;
use FindBin;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::Domain;

eval {
	my $domain = new Getperf::Domain();
	$domain->parse_command_option() || die "parse error";
};
if ($@) {
  print "Error!\n$@";
  exit 1;
}
