#!/usr/local/bin/perl
use strict;
use File::Spec;
use Test::More tests => 1;
use Data::Dumper;

sub _r {
	my ($str) = @_;
	if ($ENV{'OS'}=~/Windows/) {
		$str=~s/\//\\/g;
	}
	return $str;
}

my $rc  = 0;
my $exe = ($ENV{'OS'}=~/Windows/) ? ".exe" : "";
my $PWD = '.';
if ($ENV{'OS'}!~/Windows/) {
	$PWD =`dirname $0`; 
	chop($PWD);
}
$PWD    = File::Spec->rel2abs($PWD);
my $SRC = "${PWD}/../src";
$SRC    = File::Spec->rel2abs($SRC);

my $cmd = _r("${SRC}/getperfsoap${exe} -g -c $PWD/cfg/getperf.ini hoge");
print "$cmd\n";

my $pid = 0;
my $n = 0;
for my $exe(1..3)
{
	my $pid = fork();
	if ($pid == 0)
	{
		$rc = system($cmd);
		exit 0;
	}
	sleep(1);
	$n ++;
}

if ($ENV{'OS'}!~/Windows/) {
	while ($n != 0) {
		my $exitPid = waitpid(-1, 0);
		if ($exitPid > 0) {
			print("[WAIT] Catch child pid=$exitPid\n");
			$n --;
		}
		sleep(1);
	}
}

ok($rc == 0);
