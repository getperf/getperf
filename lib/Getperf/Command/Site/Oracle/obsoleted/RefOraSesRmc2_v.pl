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

my %refmetric = (
	'execute count'            => 'exec',
	'physical reads'           => 'disk',
	'db block gets'            => 'buff',
	'consistent gets'          => 'buff',
	'table fetch by rowid'     => 'row',
	'redo synch time'          => 'redo',
	'user I/O wait time'       => 'iowait',
	'CPU used by this session' => 'cpu',
	'user commits'             => 'commit',
);

my (%TMS, %RMC, %DAT, %SID);

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

# メイン
&main;
exit(0);

# jvmstatログ生成
sub mkoraseslog {
	my ($infile) = @_;
	my ($sec, $dt);

	return if ($infile!~/orarmcstat_(.*)\.txt/);
	my $sid = $1;
	$SID{$sid} = 1;
	my ($fname, $path, $suffix) = fileparse($infile, qr{\.txt});

	open(IN, "$IDIR/$infile");

	while (<IN>) {
		chop;
		my $line = $_;
		if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
			my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
			$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
			$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			$TMS{$dt} = 1;
		} else {
			my ($dt2, $tm, $ses, $id, $body) = split(/\s+/, $_, 5);
			next if ($body!~/^(.+?)\s+(\w+?)\s+(\d+) (RMC.*?)$/);
			my ($metric, $cat, $val, $mod) = ($1, $2, $3, $4);
#print "($metric, $cat, $val, $mod)\n";
			$mod=~s/@.*//g;
			$mod=~s/\(.*\)//g;
			$RMC{$mod} = 1;
			my $key  = join(",", ($dt, $sid, $mod));
			my $key2 = $refmetric{$metric};
			if ($key2 ne '') {
#print "[$key,$key2] $metric=$val\n";
				$DAT{$key . ',' . $key2}   += $val;
			}
		}
	}
	close(IN);
}

sub main {
	opendir ( DIR, $IDIR ) || die "Can't open dir. $!\n";
	my @infiles = grep /orarmcstat_(.*)\.txt/, readdir(DIR);
	closedir( DIR ); 
	
	for my $infile(@infiles) {
		mkoraseslog($infile);
	}

	for my $sid (sort keys %SID) {
		for my $rmc (sort keys %RMC) {
			my $ofile = sprintf("orasesrmc_%s_%s.txt", $sid, $rmc);
			open(OUT, "> $ODIR/$ofile") || die "Can't open file $!\n";
			my $ln = sprintf("%s %10s %10s %10s %10s %10s %10s %10s",
				'date', 'time', 'exec', 'disk', 'buff', 'row', 'cpu', 'elapse');
			print OUT $ln . "\n";
			for my $dt (sort keys %TMS) {
				my ($exec,$disk,$buff,$row,$cpu,$elapse);
				my $key = join(",", ($dt, $sid, $rmc));
				$DAT{$key . ',elapse'} = $DAT{$key . ',cpu'} + $DAT{$key . ',redo'} +
					$DAT{$key . ',iowait'};
				my $ln = sprintf("%s %10d %10d %10d %10d %10d %10d",
					$dt, $DAT{$key . ',exec'}, $DAT{$key . ',disk'}, 
					$DAT{$key . ',buff'}, $DAT{$key . ',row'}, 
					$DAT{$key . ',cpu'} * 100, $DAT{$key . ',elapse'} * 100);
				print OUT $ln . "\n";
			}
			close(OUT);
			my $ofile = sprintf("oracommitrmc_%s_%s.txt", $sid, $rmc);
			open(OUT, "> $ODIR/$ofile") || die "Can't open file $!\n";
			my $ln = sprintf("%s %10s %10s %10s", 'date', 'time', 'commit');
			print OUT $ln . "\n";
			for my $dt (sort keys %TMS) {
				my $key = join(",", ($dt, $sid, $rmc));
				$DAT{$key . ',elapse'} = $DAT{$key . ',cpu'} + 
					$DAT{$key . ',redo'} +
					$DAT{$key . ',iowait'};
				my $ln = sprintf("%s %10d", $dt, $DAT{$key . ',commit'});
				print OUT $ln . "\n";
			}
			close(OUT);
		}
	}
}

