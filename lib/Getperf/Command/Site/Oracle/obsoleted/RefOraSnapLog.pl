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
my $IFILE = $ENV{'PS_IFILE'} || 'snaplog';

# 実行オプション解析
my $interval = 5;
GetOptions ('--interval=i' => \$interval,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
	'--ifile=s' => \$IFILE);

# メイン
my $START = '';

# ファイルオープン
my $ofile = "$ODIR/$IFILE";
my $infile = "$IDIR/$IFILE";

`mkdir -p $ODIR` if (! -d $ODIR);
open(IN, $infile) || die "Can't open infile. $! : $infile\n";

my %tms;
my $sec;
while (<IN>) {
	chop;
	# 採取日時取得
	if ($_=~/^(BEGIN|END)\s+(\w+)\s+(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
		my ($stat, $proc, $YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6, $7, $8);
		$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY+2000-1900);
		my $key = "$stat|$proc";
		$tms{$key} = $sec;

		$START = "$YY/$MM/$DD $hh:$mm:$ss" if ($START eq '');
	}
}

close(IN);

my $HEAD = "DATE     TIME     SNAP  REP SQLR OBJR PURG\n";

open(OUT, ">$ofile") || die "Can't open outfile. $!\n";

my $snap = $tms{"END|SNAP"} - $tms{"BEGIN|SNAP"};
$snap = 0 if (!($snap > 0));
my $rep  = $tms{"END|REP"}  - $tms{"BEGIN|REP"};
$rep  = 0 if (!($rep > 0));
my $sqlr = $tms{"END|SQLR"} - $tms{"BEGIN|SQLR"};
$sqlr = 0 if (!($sqlr > 0));
my $objr = $tms{"END|OBJR"} - $tms{"BEGIN|OBJR"};
$objr = 0 if (!($objr > 0));
my $purg = $tms{"END|PURG"} - $tms{"BEGIN|PURG"};
$purg = 0 if (!($purg > 0));

print OUT $HEAD;
my $line = sprintf("%4d %4d %4d %4d %4d", $snap, $rep, $sqlr, $objr, $purg);
print OUT "$START $line\n";

close(OUT);
