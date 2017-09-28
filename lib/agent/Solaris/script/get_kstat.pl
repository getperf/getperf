#!/bin/perl

die "Usage: get_kstat.sh [sec] [cnt]" if (scalar(@ARGV) != 2);
my ($sec, $cnt) = @ARGV;

my @interfaces = ();
open IN, "kstat -p ':::link_up'|" || die "$@";
while (<IN>) {
	push (@interfaces, $1) if ($_=~/^(.+):\d.*link_up/);
}
close(IN);

while ($cnt-- > 0) {
	for my $interface(@interfaces) {
		print `kstat -Tu -p '${interface}:0:${interface}*:*'`;
		die "$@" if ($? != 0);
	}
	sleep($sec) if ($cnt > 0);
}
