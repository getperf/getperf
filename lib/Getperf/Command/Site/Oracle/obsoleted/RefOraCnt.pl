#!/usr/local/bin/perl
use strict;

# パッケージ読込
BEGIN { 
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/"); 
}
use Time::Local;
use Getopt::Long;

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'get_cnt_fbprod.txt';

# 実行オプション解析
my $interval = 5;
GetOptions ('--interval=i' => \$interval,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
	'--ifile=s' => \$IFILE);

# メイン
my ($MM, $DD, $YY) = ($1, $2, $3);

# ファイルオープン
my $ofile = "$ODIR/$IFILE";
my $infile = "$IDIR/$IFILE";

`mkdir -p $ODIR` if (! -d $ODIR);
open(OUT, ">$ofile") || die "Can't open outfile. $!\n";
open(IN, $infile) || die "Can't open infile. $!\n";

print OUT "Date       Time     cnt\n";

my $sec;
while (<IN>) {
	chop;
	# 採取日時取得
	if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
		my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
		$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY+2000-1900);
	}

	if ($_=~/^(\d+)$/) {
		my ($cnt) = ($1);
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
		my $dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
			$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
		my $str = sprintf("%s %8d\n", $dt, $cnt);

        print OUT $str;
	}
}

close(IN);
close(OUT);
