#!/usr/local/bin/perl
use strict;

# パラメータ読込
my $PWD = `dirname $0`; chop($PWD);
BEGIN { 
    push(@INC, "$PWD/libs", "$PWD/"); 
}
use Time::Local;
use Getopt::Long;
use File::Basename;
use File::Spec;
#use Param;

# 実行オプション
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'awrreport.lst';
my $PARFILE='./RefPs.pm';

# 実行オプションチェック
GetOptions ('--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
) || die "Usage : $0 [--ifile=file] [--idir=dir] [--odir=dir]\n";

# 環境変数設定
my $SPFILE="$IDIR/$IFILE";
my $SID;

# ファイルオープン
# /analysis/db_rtd_s/HW/20100512/1500/
exit if ($IDIR!~m|/*analysis/*(.*_s)/*ORACLE_DET/*(\d*)/*(\d*)/|);
my ($host, $DT, $TM) = ($1, $2, $3);
print "HOST : $host\n";

$ODIR = "$PWD/../summary/viewer/ORACLE/$DT/$TM";
`mkdir -p $ODIR` if (!-d $ODIR);

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
my $WORK = "$PWD/../_wk";               # ~mon/_wk
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

my %LOADPROFS = (
	'Redo' => 'Redo size', 
	'LogicalRd' => 'Logical reads', 
	'BlockChg' => 'Block changes', 
	'PhysicalRd' => 'Physical reads',
	'PhysicalWr' => 'Physical writes', 
	'Parses' => 'Parses', 
	'HardParses' => 'Hard parses', 
	'Sorts' => 'Sorts', 
	'Logons' => 'Logons', 
	'Executes' => 'Executes',
	'Transactions' => 'Transactions');

my %HITS = (
	'BufferNW' => 'Buffer Nowait %',
	'RedoNW' => 'Redo NoWait %', 
	'BufHit' => 'Buffer  Hit   %',
	'MemSort' => 'In-memory Sort %', 
	'LibHit' => 'Library Hit   %', 
	'SoftParse' => 'Soft Parse %',
	'ExecParse' => 'Execute to Parse %', 
	'LatchHit' => 'Latch Hit %', 
	'ParseCPU' => 'Parse CPU to Parse Elapsd %',
	'NonParseCPU' => '% Non-Parse CPU');

my %EVENTS = (
	'CPUTime' => 'CPU time',
	'DBScattRd' => 'db file scattered read',
	'DBSeqRd' => 'db file sequential read',
	'SQLNetMsg' => 'SQL\*Net message from dblink',
	'SQLNetMoreDat' => 'SQL\*Net more data from dblink',
	'LogSync' => 'log file sync',
	'LogParaWr' => 'log file parallel write', 
	'BufferWait' => 'buffer busy waits', 
	'Enqueue' => 'enq: .*[a-z]',
	'DBParaWr' => 'db file parallel write',
	'SQLNetClient' => 'SQL\*Net more data to client', 
	'LatchFree' => 'latch: .*[a-z]',
	'GlobalCacheCr' => 'global cache cr request',
	'FreeBufWait' => 'free buffer',
  'ReadByOther' => 'read by other session',
);

my %REPEVENTS;

$REPEVENTS{'oraevent'} = join('|', qw (
  BufferWait CPUTime DBParaWr DBScattRd DBSeqRd Enqueue FreeBufWait 
  GlobalCacheCr LatchFree LogParaWr LogSync SQLNetClient 
  SQLNetMoreDat SQLNetMsg));

$REPEVENTS{'ora2event'} = join('|', qw (
	ReadByOther));

my (%loadprof, %hit, %event);

my ($sec, $dt);
# 月マスタ
my %month = (
    '1月', 1, '2月', 2, '3月', 3, '4月', 4, '5月', 5, '6月', 6, '7月', 7,
    '8月', 8, '9月', 9, '10月', 10, '11月', 11, '12月', 12,
    'Jan', 1, 'Feb', 2, 'Mar', 3, 'Apr', 4, 'May', 5, 'Jun', 6, 'Jul', 7,
    'Aug', 8, 'Sep', 9, 'Oct', 10, 'Nov', 11, 'Dec', 12);

&main;
exit(0);

sub parse_loadprof {
	my ($str) = @_;

	for my $key(keys %LOADPROFS) {
		my $keyword = $LOADPROFS{$key};
		if ($str=~/$keyword:(.*)$/) {
			my @vals = split(' ', $1);
			$loadprof{$key} = shift(@vals);
		} else {
			$loadprof{$key} = 0;
		}
	}
}

sub parse_hit {
	my ($str) = @_;

	for my $key(keys %HITS) {
		my $keyword = $HITS{$key};
		if ($str=~/$keyword:(.*)$/) {
			my @vals = split(' ', $1);
			$hit{$key} = shift(@vals);
		} else {
			$hit{$key} = 0;
		}
	}
}

sub parse_event {
	my ($str) = @_;

#print "$str\n";
	for my $key(keys %EVENTS) {
		my $keyword = $EVENTS{$key};
		if ($str=~/$keyword\s+(\d.*)$/) {
			my @vals = split(' ', $1);
			if ($keyword eq 'CPU time') {
				$event{$key} = shift(@vals);
			} else {
#print "$key,$event{$key},$vals[1]\n";
				my $val = $vals[1];
				$val=~s/,//g;
				$event{$key} += $val;
			} 
		} else {
			$event{$key} = 0;
		}
	}
}

sub rep_output {
	my ($fname, %dat) = @_;

	open(OUT, "> $ODIR/$fname" . "_$SID.txt") || die "Can't create : $!";

	print OUT "Date       Time     ";
	for my $key(sort keys %dat) {
		my $head=$key;
		$head=~s/\s+/_/g;
		print OUT " $head";
	}
	print OUT "\n";
	print OUT $dt;
	for my $key(sort keys %dat) {
		print OUT " $dat{$key}";
	}
	print OUT "\n";
	close(OUT);
}

sub rep_output2 {
	my ($fname, %dat) = @_;

	open(OUT, "> $ODIR/${fname}__${SID}.txt") || die "Can't create : $!";

	my $buf = "Date       Time     PCT\n";
	my $total = 0;
	for my $key(keys %dat) {
		$dat{$key}=~s/,//g;
		$total += $dat{$key};
	}

	# CPUTimeを除いたイベント時間から、以下悪玉イベントの割合を求める
#	$total = $total - $dat{'CPUTime'};
	my $bad = 0;
	for my $e('DBScattRd', 'DBSeqRd', 'LogSync', 'LogParaWr', 'BufferWait', 'Enqueue', 'LatchFree', 'FreeBufWait') {
		$bad += $dat{$e};
	}
	$buf .= sprintf("%s %10.3f\n", $dt, 100 * $bad / $total);

	print OUT $buf;
	close(OUT);
}

sub rep_output_keys {
	my ($fname, $keys, %dat) = @_;

	open(OUT, "> $ODIR/$fname" . "_$SID.txt") || die "Can't create : $!";

	print OUT "Date       Time     ";
	for my $key(split(/\|/, $keys)) {
		my $head=$key;
		$head=~s/\s+/_/g;
		print OUT " $head";
	}
	print OUT "\n";
	print OUT $dt;
	for my $key(split(/\|/, $keys)) {
		print OUT " $dat{$key}";
	}
	print OUT "\n";
	close(OUT);
}

sub repsp {
	my $tm_flg = 0;
	my $tm_str;
	my $loadprof_flg = 0;
	my $loadprof_str;
	my $hit_flg = 0;
	my $hit_str;
	my $event_flg = 0;
	my $event_str;

	if ($SPFILE=~/awrreport_(.*)\.lst/) {
		$SID=$1;
	}
	# spreport.lst 読込
	open(IN, "$SPFILE");
	while(<IN>) {
		chop;
		# 日付読込
		if ($_=~/^  End Snap:/) {
			$tm_flg = 1;
		} elsif ($_=~/^   Elapsed:/) {
			$tm_flg = 0;
		}
		if ($tm_flg == 1) {
			$tm_str .= ' '. $_;
		}

		# ロードプロファイル読込
		if ($_=~/^Load Profile/) {
			$loadprof_flg = 1;
		} elsif ($_=~/^  % Blocks changed per Read:/) {
			$loadprof_flg = 0;
		}
		if ($loadprof_flg == 1) {
			$loadprof_str .= ' '. $_;
		}

		# ヒット率読込
		if ($_=~/^Instance Efficiency Percentages/) {
			$hit_flg = 1;
		} elsif ($_=~/^ Shared Pool Statistics/) {
			$hit_flg = 0;
		}
		if ($hit_flg == 1) {
			$hit_str .= ' '. $_;
		}

		# Top5イベント読込
		if ($_=~/^Top \d* Timed Events/) {
			$event_flg = 1;
		} elsif ($_=~/^          --------------/) {
			$event_flg = 0;
		}
		if ($event_flg == 1) {
			$event_str .= ' '. $_;
		}
	}
	close(IN);


	# 日付変換
	if ($tm_str=~/(\d\d)-\s*(.*?)\s*-(\d\d) (\d\d):(\d\d):(\d\d)/) {
		my ($DD, $MM, $YY, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);

		$sec = timelocal($ss,$mm,$hh,$DD,$month{$MM}-1,$YY-1900+2000);
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
		$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
			$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
	}

	# 各ブロックのレポートをデータに変換
	parse_loadprof($loadprof_str);
	parse_hit($hit_str);
	parse_event($event_str);

	# ロードプロファイルの出力
#	rep_output('oraload', %loadprof);
#	rep_output('orahit', %hit);
	rep_output2('v_oraperf', %event);

#	for my $ev(sort keys %REPEVENTS) {
#		rep_output_keys($ev, $REPEVENTS{$ev}, %event);
#	}
}

sub copyfile {
	my ($fname, $path, $suffix) = fileparse($SPFILE, qr{\.lst});

	my $cmd = "/bin/cp $SPFILE $ODIR/$fname.lst";
	print("$cmd\n");
	system($cmd);
}

sub main {
	# DML対象キューテーブル設定
	if (-f $SPFILE) {
		repsp();
#		copyfile();
	}
}
