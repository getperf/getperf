#!/usr/local/bin/perl
use strict;

# �p�b�P�[�W�Ǎ�
BEGIN { 
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/"); 
}
use Time::Local;
use Getopt::Long;

# ���ϐ��ݒ�
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'orasesela_RTDYYY.txt';
#my @HOSTS = ('YYYIS', 'Y4WEB', 'YQDMS', 'YQSC4', 'YQSC3', 'Y4IWFM', 'YIWFM', 'Y3DB', 'Y4DB', 'MISC');
my @HOSTS = (
	'Y3DB','Y4DB','Y5DB','Y3WEB','Y4WEB','Y5WEB','Y3WFM','Y4WFM','Y5WFM','YYYIS','YQXXX','YIXXX','MISC');

# ���s�I�v�V�������
my $interval = 5;
GetOptions ('--interval=i' => \$interval,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
	'--ifile=s' => \$IFILE);

# ���C��
my ($MM, $DD, $YY) = ($1, $2, $3);

# �t�@�C���I�[�v��
my $ofile = "$ODIR/$IFILE";
my $infile = "$IDIR/$IFILE";

`mkdir -p $ODIR` if (! -d $ODIR);
open(IN, $infile) || die "Can't open infile. $!\n";

my $HEAD = "Date       Time     transactions avg_time max_time\n";
my %buf;

# �f�[�^�ǂݍ��� Host,Session,Tran,Actives
my $sec;
while (<IN>) {
	chop;
	# �̎�����擾
	if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
		my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
		$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY+2000-1900);
	}

	# �z�X�g,SESSONS,TRANSACTIONS,ACTIVES
	#MISC,36,0,1
	if ($_=~/^(.*\d+)$/) {
		my ($host, $tran, $avg, $max) = split(",", $1);
		my $str = sprintf("%8d %8.1f %8.1f\n", $tran, $avg, $max);
		$buf{$host} = $str;
	}
}
close(IN);

# �f�[�^��������
# orases/orasescnt_{SID}_{HOST}.txt �� "���t ���� Sesson Tran Active" �`���ŏo��

my $opath = $ODIR . '/orases';
`mkdir -p $opath` if (!-d $opath);

die "input file error : $IFILE\n" if ($IFILE!~/(.*?)\.txt/);
my $fname = $1;
my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
my $dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
	$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

for my $host(@HOSTS) {
	my $ofile = $ODIR . '/orases/' . $fname . '_' . $host . '.txt';
	open(OUT, ">$ofile") || die "Can't open outfile. $!\n";
	my $line = $buf{$host};
	print OUT $HEAD;
	if (length($line) == 0) {
		print OUT $dt . " " . sprintf("%8d %8d %8d\n", 0, 0, 0);
	} else {
		print OUT $dt . " " . $buf{$host};
	}
	close(OUT);
}
