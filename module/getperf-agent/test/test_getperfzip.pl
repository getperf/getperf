#!/usr/local/bin/perl
use strict;
use File::Spec;
use Test::More tests => 6;
use Data::Dumper;

my $rc  = 0;
my $exe = ($ENV{'OS'}=~/Windows/) ? ".exe" : "";
my $PWD = '.';
if ($ENV{'OS'}!~/Windows/) {
	$PWD =`dirname $0`; 
	chop($PWD);
}
$PWD    = File::Spec->rel2abs($PWD);
my $SRC = "${PWD}/../src";

my $cmd = "${SRC}/getperfzip${exe} -h";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

$cmd = "${SRC}/getperfzip${exe} -z -b ${PWD}/cfg -d ssl ${PWD}/test.zip";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);

$cmd = "${SRC}/getperfzip${exe} -u -b ${PWD}/cfg ${PWD}/test.zip";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);

$cmd = "${SRC}/getperfzip${exe} -z -b ${PWD}/cfg -d ssl -p test ${PWD}/test.zip";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);

$cmd = "${SRC}/getperfzip${exe} -u -b ${PWD}/cfg ${PWD}/test.zip";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc != 0);

$cmd = "${SRC}/getperfzip${exe} -u -b ${PWD}/cfg -p test ${PWD}/test.zip";
print "$cmd\n";
$rc = system($cmd);
print "RC=$rc\n";
ok($rc == 0);
