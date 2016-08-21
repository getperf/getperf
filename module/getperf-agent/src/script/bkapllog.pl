#!/usr/bin/perl
#
# ���ΥХå����å�
# 
# �����㡧
#  perl bkapllog.pl --src=/var/log --target=/home/psadmin/work/sfw/tmp --grep=logwatch
#
use strict;

# �ѥå������ɹ�
use File::Spec;
use Getopt::Long;
use Data::Dumper;

# �Ķ��ѿ�����
$ENV{'LANG'}='C';
my $SRC='/var/log';
my $QUEID='';
my $GREP='';
my $TARGET='.';
my $MTIME=30;
GetOptions (
	'--src=s'    => \$SRC,
	'--id=s'     => \$QUEID,
	'--grep=s'   => \$GREP,
	'--target=s' => \$TARGET,
	'--mtime=s'  => \$MTIME);

# �ǥ��쥯�ȥ�����
my $PWD = `dirname $0`; chop($PWD);
my $WORK = File::Spec->rel2abs("$PWD/../_wk");
$TARGET = File::Spec->rel2abs( $TARGET );


# �ǥ��쥯�ȥ�����å�
if (!-d "$WORK"){
    `/bin/mkdir -p $WORK`;
}

# �ᥤ��
&main;
exit(0);

# �ե�����κǽ��������դ����
sub lastupdate {
    my ($fname) = @_;

	my @fstat = stat( $fname );
	return $fstat[9];		# �ǽ���������
}

sub main {
    # �����ॹ����ץ����å�
	my $last_timestamp = ($QUEID eq '') ? "$WORK/last_upd_${GREP}" : "$WORK/last_upd_${QUEID}";
	my $tms = (-f $last_timestamp) ? lastupdate( $last_timestamp ) : time() - $MTIME * 24*60;

    # ���ե����븡��
    opendir DIR, $SRC;
	my @filelist = ();
	map { 
		my $timestamp = lastupdate( "$SRC/$_" );
		push(@filelist,  $_) if ($timestamp > $tms);
	} grep ( /^[^.]/ && /$GREP/ && -f "$SRC/$_", readdir DIR );
	close DIR;
	
	# �оݥե����뤬�ʤ����Ͻ�λ
	die "No backup file\n" if (scalar(@filelist) == 0);

	# �����ॹ����׺���
	my $cmd = "touch ${last_timestamp}";
	warn("TOUCH:\n$cmd\n");
	system($cmd);

    # �оݥե����륳�ԡ�
	my $sources = join(" ", @filelist);
	my $targets = "${TARGET}/${QUEID}";
	system("mkdir $targets") if (! -d $targets);
	$cmd = "(cd $SRC; /bin/cp -p $sources $targets)";
	warn("COPY:\n$cmd\n");
	system($cmd);

	# �ե�����ꥹ�Ⱥ���
	if ($QUEID ne '') {
		open OUT, ">${targets}.txt" || die "Can't open ${targets}.txt @?\n";
		print OUT $sources;
		close(OUT);
	}
}

