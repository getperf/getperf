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

# �Ķ��ѿ�����
$ENV{'LANG'}='C';
my $ODIR='./tmp';
my $IDIR='.';
my $IFILE = $ENV{'PS_IFILE'} || 'spreport.lst';

# �����оݥ�������(�����ѿ��˽��פ��륹�����ޤ����)
my @SCHEMA=('ACTIVE', 'CURRENT', 'INACTIVE');

GetOptions ('--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR);

# �ǥ��쥯�ȥ�����
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# �ᥤ��
&main;
exit(0);

# jvmstat������
sub mkoraseglog {
	my ($infile) = @_;
	my ($sec, $dt);
	my $cnt = 0;
	my %tbs;	# �ơ��֥륵����
	my %tbssum;
	my %tms;	# ������

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
			$tms{$dt} = 1;
		} else {
			my ($user, $sescnt) = split(/,/, $line);
			my $key = join(" ", ($dt, $user));
			$tbs{$key} += $sescnt;
        	$cnt ++;
		}
	}
	close(IN);

	# �إå���
	my $head = "Date       Time         ";
	for my $stat(@SCHEMA) {
		$head .= sprintf(" %10s", $stat);
	}

	# ɽ��������ݡ���
	my $ofile = $ODIR . "/". $IFILE;
	open(OUT, ">$ofile");
	print OUT $head . "\n";
	for my $tm(sort keys %tms) {
		my $line = $tm;
		for my $usr(@SCHEMA) {
			my $key = join(" ", ($tm, $usr));
			$line .= sprintf(" %10.2f", $tbs{$key});
		}
		print OUT $line . "\n";
	}
	close(OUT);
}

sub main {
	
	mkoraseglog("$IFILE");
}
