#!/usr/local/bin/perl
use strict;
use File::Spec;
use Test::More tests => 6;
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

my $cmd = _r("${SRC}/getperfsoap${exe} -h");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

$cmd = _r("${SRC}/getperfsoap${exe} -s -c $PWD/cfg/getperf.ini getperfsoap");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);

$cmd = _r("${SRC}/getperfsoap${exe} -s hoge");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

$cmd = _r("${SRC}/getperfsoap${exe} -s -c $PWD/cfg/getperf.ini hoge");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

$cmd = _r("${SRC}/getperfsoap${exe} -g -c $PWD/cfg/getperf.ini sslconf.zip");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);

$cmd = _r("${SRC}/getperfsoap${exe} -g -c $PWD/cfg/getperf.ini hoge");
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

my $n = 0;
for my $exe(1..3)
{
	my $pid = fork();
	if ($pid == 0)
	{
		$rc = system($cmd);
		exit 0;
	}
}

while ($exe) {
	if ((my $exitPid = waitpid($pid, 1)) != 0) {
		gpfInfo("[WAIT] Catch child pid=%d", $exitPid);
		$exe --;
	}
}
