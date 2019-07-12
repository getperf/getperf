#!/usr/bin/perl
#
# AIX nmon���O�̃o�b�N�A�b�v
#
use strict;

# �p�b�P�[�W�Ǎ�
BEGIN {
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/");
}
#use CGI::Carp qw(carpout);
use File::Spec;
use Getopt::Long;
# use Param;

# ���ϐ��ݒ�
$ENV{'LANG'}='C';
my $SRC='/siview/log/SMC/nmon/hourly';
my $QUEID='nmon_hourly';
my $GREP='nmon';
my $TARGET='.';
my $MTIME=30;
GetOptions ('--src=s' => \$SRC,
    '--id=s' => \$QUEID,
    '--grep=s' => \$GREP,
    '--target=s' => \$TARGET,
    '--mtime=s' => \$MTIME);

#$SRCPERF .= $QUEID;

# �f�B���N�g���ݒ�
my $HOST=`hostname`; chop($HOST);
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
my $WORK = "$PWD/../_wk";           # ~mon/_wk
#$TARGET = File::Spec->rel2abs( $TARGET );


# �f�B���N�g���`�F�b�N
if (!-d "$WORK"){
    `/bin/mkdir -p $WORK`;
}

# ���C��
&main;
exit(0);

sub udatefile {
    my ($fname) = @_;

    warn("CHECK DATE[$fname]\n");
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
        = stat($fname);
    my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($mtime);
    my $dt = sprintf("%04d%02d%02d%02d%02d.%02d",
        $YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
    warn("LAST UPDATE[$dt]\n");

    return($dt);
}

sub lasttime {
    my $mtime = time() - 60 * $MTIME;
    my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($mtime);
    my $dt = sprintf("%04d%02d%02d%02d%02d.%02d",
        $YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
    return($dt);
}

sub main {
    # �^�C���X�^���v�`�F�b�N
    if (! -f "$WORK/lastupd_$QUEID") {
        my $last_upd = lasttime();
        my $cmd = "/bin/touch -t $last_upd $WORK/lastupd_$QUEID";
        warn("INIT:\n$cmd\n");
        system($cmd);
    }

    # ���O�t�@�C������
    my $cmd="/bin/find $SRC -name \"*.*\" -newer $WORK/lastupd_$QUEID -prune";
    warn("FIND:\n$cmd\n");
    my @INFILES;
        open(IN, "$cmd|");
        while(<IN>) {
            chop;
            # �����Ő��������t�@�C���͏��O����
            next if ($_=~/_2345\.nmon/);
            push(@INFILES, $_);
    }
    # �ŐV�̃t�@�C���͎�菜��
    pop(@INFILES);

    # �Ώۃt�@�C����10�ȏ�̏ꍇ�͍ŐV��10�݂̂��R�s�[����
    while (scalar(@INFILES) > 10) {
        shift(@INFILES);
    }

    # �Ώۃt�@�C�����Ȃ��ꍇ�͏I��
    die "No backup file" if (scalar(@INFILES) == 0);

    # �^�C���X�^���v�쐬
    unlink("$WORK/lastupd_$QUEID") if (-f "$WORK/lastupd_$QUEID");
    $cmd = "/bin/touch $WORK/lastupd_$QUEID";
    warn("TOUCH:\n$cmd\n");
    system($cmd);

    # �Ώۃt�@�C�����X�g�쐬
    my $srcfiles;
    open(OUT , "> $TARGET/list_$QUEID.txt");
    for my $file(sort @INFILES) {
        $file =~ s|$SRC|.|;
        if ($GREP) {
            next if ($file!~/$GREP/);
        }
	$file=~s/^\.//g;
	$file=~s/^\///g;
        $srcfiles .= " " . $file;
        print OUT "$file\n";
    }
    close(OUT);

    # �Ώۃt�@�C���R�s�[
    # �Ώۃt�@�C���R�s�[
    my $targetdir = "$TARGET/$QUEID";
    warn("mkdir $targetdir");
    `mkdir $targetdir` if (! -d $targetdir);
    my $cmd = "(cd $SRC; /bin/cp -p $srcfiles $targetdir)";
    warn("COPY:\n$cmd\n");
    system($cmd);
}


