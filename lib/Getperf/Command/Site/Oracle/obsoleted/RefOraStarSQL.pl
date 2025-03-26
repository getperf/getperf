#!/usr/local/bin/perl
use strict;

# パラメータ読込
BEGIN { 
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/"); 
}
use Time::Local;
use Getopt::Long;
use File::Basename;
use File::Spec;

# 実行オプション
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'orases.txt';

GetOptions (
	'--idir=s'     => \$IDIR,
	'--ifile=s'    => \$IFILE,
	'--odir=s'     => \$ODIR,
) || die "Usage : $0 [--idir=dir] [--odir=dir]\n";

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

my ($sec, $dt);
my (%REPDAT);

open(IN, "$IDIR/$IFILE");
while (<IN>) {
#print;
	chop;
	if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
		my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
		$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
		$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
			$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
print "DATE:$dt\n";
	# 2010/12/15 16:01:06,7tcnvqgdks3xs,delete from FRLOT_HOLDRECORD w,2196457043,...
	} elsif ($_=~/^(.*),([delete|insert|update].*?),(\d.*)$/) {
		my ($head, $sql, $body) = ($1, $2, $3);
		my ($dml, $tbl);
		if ($sql=~/delete from (.+?)\s/ || $sql=~/delete from (.+?)$/) {
			$dml = 'D';
			$tbl = $1;
		} elsif ($sql=~/insert into (.*?)\s/ || $sql=~/insert into (.*?)$/) {
			$dml = 'I';
			$tbl = $1;
		} elsif ($sql=~/update (.*?)\s/ || $sql=~/update (.*?)$/) {
			$dml = 'U';
			$tbl = $1;
		}
		my @varr = split(/,/, $body);
		next if (scalar(@varr) != 8);
		my ($hash, $exec, $disk, $buff, $row, $cpu, $ela, $type) = @varr;
		my @harr = split(/,/, $head);
		$REPDAT{$dml . '_' . $tbl} .= sprintf("%s %15.0f %15.0f %15.0f %15.0f %15.0f %15.0f\n",
			$harr[0], $exec, $disk, $buff, $row, $cpu, $ela);
#		print "$sql\n($dml,$tbl) ($exec, $disk, $buff, $row, $cpu, $ela, $type)\n";
	}
}
close(IN);

my $odir="$ODIR/starsql";
`mkdir $odir` if (!-d $odir);
for my $repkey (sort keys %REPDAT) {
	my $ofile = sprintf("orastarsql_%s.txt", $repkey);
	open(OUT, "> $odir/$ofile") || die "Can't open file $!\n";
#2010/12/15 16:01:06     525088     398466   16758693     525088       1319       1452
	print OUT "Date       Time     exec       disk       buffer     rows       cpu        elapse\n";
	print OUT $REPDAT{$repkey};
	close(OUT);
}

