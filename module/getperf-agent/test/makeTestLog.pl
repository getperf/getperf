#!/usr/local/bin/perl
use strict;
use File::Spec;
use Data::Dumper;
use File::Path qw/mkpath rmtree/;
use Time::Local qw(timelocal);
use FindBin;
use Getopt::Long;

sub _r {
        my ($str) = @_;
        if ($ENV{'OS'}=~/Windows/) {
                $str=~s/\//\\/g;
        }
        return $str;
}

my $DIRCNT=0;
my $USAGE   = "makeTestLog.pl [--ckdir=...]\n";
GetOptions('--ckdir=i' => \$DIRCNT) || die $USAGE;

print $FindBin::Bin, "\n";
my $PWD = $FindBin::Bin;
$PWD     = File::Spec->rel2abs($PWD);

my $logDir = ($ENV{'OS'}=~/Windows/) ? "$PWD/win/log" : "$PWD/cfg/log";

if ( $DIRCNT == 0 ) {
	rmtree( $logDir );

	my $now = time();
	for my $hour(1..48)
	{
		my $currTime = $now - 3600 * $hour;
		my ($ss, $mi, $hh, $dd, $mm, $yy) = localtime($currTime);
		my $tms = sprintf("%04d%02d%02d/%02d%02d%02d", $yy + 1900, $mm + 1, $dd, $hh, $mi, $ss);
		my $target = "$logDir/HW/$tms";
		warn "mkdir $target\n";
		mkpath( $target );
	}
} else {
	if ($ENV{'OS'}=~/Windows/) {
	} else {
		my $cmd = "ls ${logDir}/*/*/* | grep \":\" | wc";
		my $res = `${cmd}`;
		if ($res=~/^\s*(\d+)\s/) {
			my $rows = $1;
			if ( $rows == $DIRCNT ) {
				exit 0;
			} else {
				die "rows is not equal $DIRCNT : $res";
			}
		} else {
			die $res;
		}
	}
}

