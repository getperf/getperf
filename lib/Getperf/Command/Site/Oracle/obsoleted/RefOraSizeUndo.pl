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

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || './tmp';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'spreport.lst';

# 集計対象スキーマ(下記変数に集計するスキーマを指定)
my @SCHEMA=('UNDO ALLOCATION SIZE', 'UNDO DEFINE SIZE');
my @SCHEMA2=('UNDO ALLOCATION SIZE', 'UNDO DEFINE SIZE', 'ACTIVE', 'EXPIRED', 'UNEXPIRED');

GetOptions ('--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR);

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# メイン
&main;
exit(0);

# jvmstatログ生成
sub mkoraseglog {
	my ($infile) = @_;
	my ($sec, $dt);
	my $cnt = 0;
	my %tbs;	# テーブルサイズ
	my %tbsname;
	my %tbssum;
	my %tms;	# 時系列

	open(IN, "$IDIR/$infile");

#Date:08/09/01 19:50:12
#UNDO ALLOCATION SIZE,UNDOTBS,2651.375
#UNDO DEFINE SIZE,UNDOTBS,12000

	while (<IN>) {
		chop;
		my $line = $_;
		if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
			my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
			$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
			$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			$tms{$dt} = 1;
		} else {
			my ($user, $name, $capa) = split(/,/, $line);
			$tbsname{$name} = 1;
			my $key = join(" ", ($name, $dt, $user));
			$tbs{$key} += $capa;
        	$cnt ++;
		}
	}
	close(IN);

	# ヘッダー
  # Date       Time     ALLOCATION     DEFINE
  # 2008/09/01 20:00:13    2651.38   12000.00
	my $head  = "Date       Time     ALLOCATION     DEFINE";
	my $head2 = "Date       Time     ALLOCATION     DEFINE      ACTIVE    EXPIRED     UNEXPIRED";

	# 表サイズレポート
  for my $tname(keys %tbsname) {
		my ($fname, $path, $suffix) = fileparse($IFILE, qr{\.txt});
		my $ofile = $ODIR . "/". $fname . "_" . $tname . ".txt";
		open(OUT, ">$ofile");
		print OUT $head . "\n";
		for my $tm(sort keys %tms) {
			my $line = $tm;
			for my $usr(@SCHEMA) {
				my $key = join(" ", ($tname, $tm, $usr));
				$line .= sprintf(" %10.2f", $tbs{$key});
			}
			print OUT $line . "\n";
		}
		close(OUT);

		$fname=~s/orasize_undo/orasize2_undo/g;
		my $ofile2 = $ODIR . "/". $fname . "_" . $tname . ".txt";
		open(OUT2, ">$ofile2");
		print OUT2 $head2 . "\n";
		for my $tm(sort keys %tms) {
			my $line2 = $tm;
			for my $usr(@SCHEMA2) {
				my $key = join(" ", ($tname, $tm, $usr));
				$line2 .= sprintf(" %10.2f", $tbs{$key});
			}
			print OUT2 $line2 . "\n";
		}
		close(OUT2);
	}
}

sub main {
	
	mkoraseglog("$IFILE");
}
