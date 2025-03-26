#!/usr/local/bin/perl
use strict;

# �ѥ�᡼���ɹ�
BEGIN { 
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/"); 
}
use Time::Local;
use Getopt::Long;
use File::Basename;
use File::Spec;
#use Param;

# �¹ԥ��ץ����
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'spreport.lst';

# �¹ԥ��ץ��������å�
GetOptions ('--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
) || die "Usage : $0 [--ifile=file] [--idir=dir] [--odir=dir]\n";

# �Ķ��ѿ�����
my $SPFILE="$IDIR/$IFILE";
my $SID;

# �ǥ��쥯�ȥ�����
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
	'Enqueue' => 'enqueue',
	'DBParaWr' => 'db file parallel write',
	'SQLNetClient' => 'SQL\*Net more data to client', 
	'LatchFree' => 'latch free',
	'GlobalCacheCr' => 'global cache cr request');

my (%loadprof, %hit, %event);

my ($sec, $dt);
my %month = (
    '1��', 1, '2��', 2, '3��', 3, '4��', 4, '5��', 5, '6��', 6, '7��', 7,
    '8��', 8, '9��', 9, '10��', 10, '11��', 11, '12��', 12,
    'Jan', 1, 'Feb', 2, 'Mar', 3, 'Apr', 4, 'May', 5, 'Jun', 6, 'Jul', 7,
    'Aug', 8, 'Sep', 9, 'Oct', 10, 'Nov', 11, 'Dec', 12);

# �ᥤ��

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

	for my $key(keys %EVENTS) {
		my $keyword = $EVENTS{$key};
		if ($str=~/$keyword(.*)$/) {
			my @vals = split(' ', $1);
			if ($keyword eq 'CPU time') {
				$event{$key} = shift(@vals);
			} else {
				$event{$key} = $vals[1];
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

sub repsp {
	my $tm_flg = 0;
	my $tm_str;
	my $loadprof_flg = 0;
	my $loadprof_str;
	my $hit_flg = 0;
	my $hit_str;
	my $event_flg = 0;
	my $event_str;

	if ($SPFILE=~/spreport_(.*)\.lst/) {
		$SID=$1;
	}
	# spreport.lst �ɹ�
	open(IN, "$SPFILE");
	while(<IN>) {
		chop;
		# �����ɹ�
		if ($_=~/^  End Snap:/) {
			$tm_flg = 1;
		} elsif ($_=~/^   Elapsed:/) {
			$tm_flg = 0;
		}
		if ($tm_flg == 1) {
			$tm_str .= ' '. $_;
		}

		# ���ɥץ�ե������ɹ�
		if ($_=~/^Load Profile/) {
			$loadprof_flg = 1;
		} elsif ($_=~/^  % Blocks changed per Read:/) {
			$loadprof_flg = 0;
		}
		if ($loadprof_flg == 1) {
			$loadprof_str .= ' '. $_;
		}

		# �ҥå�Ψ�ɹ�
		if ($_=~/^Instance Efficiency Percentages/) {
			$hit_flg = 1;
		} elsif ($_=~/^ Shared Pool Statistics/) {
			$hit_flg = 0;
		}
		if ($hit_flg == 1) {
			$hit_str .= ' '. $_;
		}

		# Top5���٥���ɹ�
		if ($_=~/^Top 5 Timed Events/) {
			$event_flg = 1;
		} elsif ($_=~/^Wait Events for DB:/) {
			$event_flg = 0;
		}
		if ($event_flg == 1) {
			$event_str .= ' '. $_;
		}
	}
	close(IN);


	# �����Ѵ�
	if ($tm_str=~/(\d\d)-(.*)\s*-(\d\d) (\d\d):(\d\d):(\d\d)/) {
		my ($DD, $MM, $YY, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
		$sec = timelocal($ss,$mm,$hh,$DD,$month{$MM}-1,$YY-1900+2000);
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
		$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
			$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
	}

	# �ƥ֥�å��Υ�ݡ��Ȥ�ǡ������Ѵ�
	parse_loadprof($loadprof_str);
	parse_hit($hit_str);
	parse_event($event_str);

	# ���ɥץ�ե�����ν���
	rep_output('oraload', %loadprof);
	rep_output('orahit', %hit);
	rep_output('oraevent', %event);
}

sub copyfile {
	my ($fname, $path, $suffix) = fileparse($SPFILE, qr{\.lst});

	my $cmd = "/bin/cp $SPFILE $ODIR/$fname.lst";
	system($cmd);
}

sub main {
	# DML�оݥ��塼�ơ��֥�����
	if (-f $SPFILE) {
		repsp();
		copyfile();
	}
}
