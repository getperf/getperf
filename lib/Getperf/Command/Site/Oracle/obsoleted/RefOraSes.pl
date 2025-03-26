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
my $PRINTSUM = 0;

my @STATE=('ACTIVE', 'INACTIVE');

GetOptions (
	'--printsummary' => \$PRINTSUM,
	'--idir=s'       => \$IDIR,
	'--ifile=s'      => \$IFILE,
	'--odir=s'       => \$ODIR,
) || die "Usage : $0 [--idir=dir] [--odir=dir]\n";

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# メイン
&main;
exit(0);

# jvmstatログ生成
sub mkoraseslog {
	my ($infile) = @_;
	my ($sec, $dt);
	my $cnt = 0;
	my %sesstat;	# セッション
	my %tms;	# 時系列

	# 出力ファイル名作成
	$infile=~/orases_(.*)\.txt/;
	my $sid = $1;
	my ($fname, $path, $suffix) = fileparse($infile, qr{\.txt});
	my $ofile = $ODIR . "/seslst_" . $sid . ".txt";

	open(OUT, ">$ofile");
	open(IN, "$IDIR/$infile");

	my $line = "Time               ,";
	$line .= "SID,SPID,USERNAME,COMMAND,STATUS,PROGRAM,SQL_ADDRESS,SQL_HASH_VALUE,";
	$line .= "PREV_SQL_ADDR,PREV_HASH_VALUE,LAST_CALL_ET,LOGON_TIME,EVENT,P1,P2,P3,WAIT_TIME,SECONDS_IN_WAIT";
	print OUT $line . "\n";

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
			my @vals =split(/,/, $line);
			my $stat;
			if (scalar(@vals) == 18) {
				$stat = $vals[4];
			} else {
				$stat = $vals[3];
			}
			my $key = join(" ", ($dt, $stat));
			$sesstat{$key} ++;
			print OUT $dt . "," . $line . "\n" ;
	    	$cnt ++;
		}
	}
	close(IN);
	close(OUT);

	# サマリデータ
	my $sumcnt = 0;
	my $sumval = 0;

	$ofile = $ODIR . "/sesstat_" . $sid . ".txt";
	open(OUT, ">$ofile");
	my $line = "Date       Time    ";
	for my $stat(@STATE) {
		$line .= sprintf(" %10s", $stat);
	}
	print OUT $line . "\n";
	for my $tm(sort keys %tms) {
		my $line = $tm;
		for my $stat(@STATE) {
			my $sescnt = $sesstat{"$tm $stat"};
			$line .= sprintf(" %10d", $sescnt);
			$sumval += $sescnt;
		}
		$sumcnt ++;
		print OUT $line . "\n";
	}
	close(OUT);

	if ($PRINTSUM) {
		my $item = "sesstat_" . $sid;
		if ($sumcnt == 0) {
			$sumval = 0;
		} else {
			$sumval = $sumval / $sumcnt;
		}
		print "$item=$sumval\n";
	}
}

sub main {
	
	opendir ( DIR, $IDIR ) || die "Can't open dir. $!\n";
	my @infiles = grep /orases_(.*)\.txt/, readdir(DIR);
	closedir( DIR ); 
	
	for my $infile(@infiles) {
		mkoraseslog($infile);
	}
}
