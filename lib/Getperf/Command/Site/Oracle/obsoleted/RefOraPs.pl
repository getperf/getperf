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
my $INTERVAL=30;
my %ORAPS;
my %ORASES;
my %DATELIST;

# �¹ԥ��ץ����
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'psutil.txt';

GetOptions (
	'--idir=s'     => \$IDIR,
	'--ifile=s'    => \$IFILE,
	'--odir=s'     => \$ODIR,
	'--interval=i' => \$INTERVAL);

my $PSFILE = "$IDIR/$IFILE";

# Oracle�ץ��������ʡ�
my $OSUSER = 'oracle';

# �ץ������ץ��ƥ���(����������)
my @USRCAT = (
	'RTDMGR',
	'STARSTATE',
	'PERFSTAT',
);
my $USRCAT_STR = join(',', @USRCAT);

# �ץ������ץ��ƥ���(�ץ������)
my @PROGCAT = (
	'oracle',
	'sqlplus',
	'JDBC',
	'.exe',
);
my $PROGCAT_STR = join(',', @PROGCAT);

# �ץ������ץ��ƥ���(�ۥ�����)
my @HOSTCAT = (
	'yiura',
	'yiwfm',
	'yyyis',
);
my $HOSTCAT_STR = join(',', @HOSTCAT);

# �ǥ��쥯�ȥ�����
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# �ᥤ��
&main;
exit(0);

# �������ä��Ѵ�
sub time2sec {
        my ($time) = @_;
        my $day = 0;

        # �����Ѵ�
        if ($time=~/(\d+)-(.*)/) {
                ($day, $time) = ($1, $2);
        }

        # �����Ѵ�
        my @hhmmss = split(/:/, $time);
        my $y = 0;
        for my $x(@hhmmss) {
                $y = 60 * $y + $x;
        }
        $y += 24 * 3600 * $day;

        return ($y);
}

# Oracle�ץ��������
sub getoraps {
	my ($sec, $dt);
	my $cnt = 0;
	my %sesstat;	# ���å����

	# psutil.txt ����¸�ǥ��쥯�ȥ꤫�鳺���ե����븡��
	my ($fname, $path, $suffix) = fileparse($PSFILE, qr{\.txt});

	# oraproc_XXX.txt�ե����븡��
	opendir ( DIR, $path ) || die "Can't open dir. $!\n";
	my @infiles = grep /oraproc_(.*)\.txt/, readdir(DIR);
	closedir( DIR ); 

	for my $infile(@infiles) {
		# �ե������ɹ�
		$infile=~/oraproc_(.*)\.txt/;
		my $sid = $1;

		open(IN, $path . "/" . $infile);
		while (<IN>) {
			chop;
			my $line = $_;
			# ���դ����
			if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
				my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
				$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
				$sec = 60 * int($sec / 60);
				my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
				$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
					$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			# �ǡ��������
			} else {
				my @vals =split(/,/, $line);
				# �ʰץե����ޥåȥ����å�
				if (scalar(@vals) != 5) {
					next;
				} 
				# PID�򥭡��˥ϥå������
				my $sesid = shift(@vals);
				my $pid = shift(@vals);
				my $key = join(",", ($pid));
				$ORASES{$key} = join(",", ($sid, @vals));
			}
		}
		close(IN);
	}

#	for my $key(sort keys %ORASES) {
#		my $line = join(",", ($key , $ORASES{$key}));
#		print $line . "\n";
#	}
}

# �ץ���ID����Oracle���å���������å�
sub check_proc {
	my ($pid, $grp, $usr, $cmd) = @_;
	my $key;

	if ($usr ne $OSUSER) {
		$key = join(",", ('others', undef, undef, undef));
		return($key);
	}

	# Oracle�ץ����Υ����å�
	if ($ORASES{$pid}) {
		my @orases = split(",", $ORASES{$pid});
		shift(@orases);

		# �桼�����ƥ�������å�
		my $schema = shift(@orases);	# �桼��
		$schema = 'ETC' if ($schema eq '');	# �桼����null�ξ��
		my $usercat = 'ETC';
		for my $key(@USRCAT) {
			if ($schema=~/$key/) {
				$usercat = $key;
			}
		}
		$usercat = $schema;

		# �ۥ��ȥ��ƥ�������å�
		my $host = shift(@orases);	# �ۥ���
		$host=~s/[0-9|\\|.].*//g;	# ���ե��å�������
		my $hostcat = 'ETC';
		for my $key(@HOSTCAT) {		
			if ($host=~/$key/) {
				$hostcat = $key;
			}
		}
		$hostcat = $host;

		# Program���ƥ�������å�
		my $prog = shift(@orases);	# �ץ����
		my $progcat = 'ETC';
		for my $key(@PROGCAT) {
			if ($prog=~/$key/) {
				$progcat = $key;
			}
		}

		$key = join(",", ($hostcat, $usercat, $progcat, $prog));
	# ����¾�ξ��Υ����å�
	} else {
		$key = join(",", ('ETC', 'ETC', 'ETC', 'ETC'));
	}

	return($key);
}

# Pivot�Ѵ� �ļ������ա�������slist
sub ps_pivot {
	my ($dt, $slist, %dat) = @_;
	my $line = $dt;

	my @cat = split(',', $slist);
	for my $ps(@cat) {
		my $key = $dt . "," . $ps;
		# 1�������CPU����*100��CPU����Ψ�˴���
		$line .= " " . sprintf("%8.2f", $dat{$key} * 100.0 / $INTERVAL);
	}
	return($line);
}

# CPU���ֽ��ץ�ݡ���
sub mklogfile {
	my ($fname, $slist, %dat) = @_;

	# �ե����륪���ץ�
	my $outfile = "$ODIR/$fname";
	print("MKLOG : $outfile\n");
	open(OUT, ">$outfile") || die "Can't open $outfile : $1";

	# ���ץإå�����
	my @cat = split(',', $slist);
	push(@cat, 'ETC');
	$slist = join(',', @cat);

	# �إå�����
	my $line = 'DATE     TIME    ';
	for my $ps(@cat) {
		$line .= " " . sprintf("%8s", $ps);
	}
	print OUT $line . "\n";

	for my $dt(sort keys %DATELIST) {
		print OUT ps_pivot($dt, $slist, %dat) . "\n";
	}
	close(OUT);
}

sub mkorapslog {
	my (%cpu_wk);
	my (%pscpu_host, %pscpu_prog, %pscpu_usr);
	my ($sec);
	my $cnt = 0;

	# �ե������������
	my $outfile = "$ODIR/orapsutil.txt";
	print("MKLOG : $outfile\n");
	open(OUT, ">$outfile") || die "Can't open $outfile : $1";

	# �ե�������������
	die "$PSFILE not found : $!" if (!-f $PSFILE);
	open(IN, $PSFILE);

	my ($dt, $pid, $ppid, $grp, $usr, $tms, $nlwp, $vsz, $arg);
	while (<IN>) {
		chop;

		# �������
		if ($_=~/^Date:(.*)$/) {
			$dt = $1;
			$DATELIST{$dt} = 1 if ($cnt > 0);
			$cnt ++;
			next;
		}
		# �إå��Ͻ���
		next if ($_=~/\s+PID/);

		# �ǡ��������
		my @args = split(/\s+/, $_);
		if (!$args[0]) {
			shift(@args);
		}
		my ($pid, $ppid, $grp, $usr, $tms, $nlwp, $vsz, $cmd) = @args;
		next if ($cmd eq '');	# �ʰץե����ޥåȥ����å�

		# ���ƥ�������å�
		my ($orahost, $orausr, $oracat, $oraprog)
			= split(/,/, check_proc($pid, $grp, $usr, $cmd));

		# CPU���ֻ���
		my $pid_key = join(",", ($pid, $ppid));
		my $cputm = time2sec($tms);
		my $cpusec = 0;
		if ($cpu_wk{$pid_key}) {
			$cpusec = $cputm - $cpu_wk{$pid_key};
		} else {
			$cpusec = $cputm;
		}
		$cpu_wk{$pid_key} = $cputm;

		next if ($orahost eq 'others');		# Oracle �ʳ��Υץ������ɤ����Ф�

		# Oracle�ץ�����CPU���ֽ��ϡ�����
		if ($cnt > 1) {
			print OUT join(",", 
				($dt,$orahost,$oracat,$oraprog,$pid,$usr,$nlwp,$vsz,$cpusec,$cmd)) . "\n";
			# ���ա��ۥ���̾��CPU���ֽ���
			my $key = $dt . ',' . $orahost;
			$pscpu_host{$key} += $cpusec * 1.0;
			# ���ա��桼��̾��CPU���ֽ���
			my $key = $dt . ',' . $orausr;
			$pscpu_usr{$key} += $cpusec * 1.0;
			# ���ա�Program���ƥ���̾��CPU���ֽ���
			my $key = $dt . ',' . $oracat;
			$pscpu_prog{$key} += $cpusec * 1.0;
		}
	}

	close(IN);
	close(OUT);

	mklogfile('orapshost.txt', $HOSTCAT_STR, %pscpu_host);
	mklogfile('orapsusr.txt', $USRCAT_STR, %pscpu_usr);
	mklogfile('orapsprog.txt', $PROGCAT_STR, %pscpu_prog);

}

sub main {
	getoraps();
	mkorapslog();
}
