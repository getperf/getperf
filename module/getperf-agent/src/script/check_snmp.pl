#!/usr/bin/perl
use strict;
use utf8;
use Encode;
use Data::Dumper;
use Getopt::Long;

# ディレクトリの設定

my $SHOWVER   = 0;
my $COMMUNITY = 'public';
my $SNMP_VER  = '1';
my $NETWORKS  = '';
my $PWD       = GetAbsPath();
my $ODIR      = "${PWD}/../_wk/verify";
my $USAGE     = "check_snmp, version : 2.5.0(UNIX)\n" .
	"Usage : check_snmp.pl [--community=...] [--version=[1|2c|3]] [--networks=...]\n";

GetOptions('--odir=s' => \$ODIR, '--help' => \$SHOWVER, '--version' => \$SNMP_VER, 
	'--community=s' => \$COMMUNITY, '--networks=s' => \$NETWORKS) || die $USAGE;

if ($SHOWVER) {
	print $USAGE ;
	exit 0;
}
mkdir($ODIR) if (!-d $ODIR);

# メイン

my ($snmp_report);
if (!checkNetwork(\$snmp_report)) {
	exit -1;
}
verifyNetInterface(\$snmp_report);
reportNetInterface(\$snmp_report);
exit;

# ネットワーク機器のチェック

sub checkNetwork {
	my ($ref_snmp) = @_;
	my $yesno = 'n';
	my $msg   = '';
	my $cmd   = '';
	my $rc    = 0;
	my %hosts = ();

	# ネットワーク機器の入力
	if ($NETWORKS eq '') {
		PutLine("ネットワーク機器のIPアドレス、ホスト名を入力して下さい");
		$yesno = 'n';
		while($yesno ne 'y') {
			while (1) {
				my $host = '';
				$msg = "IPアドレス、ホスト名を入力して下さい。終了時はRETURN";
				GetLine($msg, \$host);
				last if ($host eq '');
				if ($host=~/[\/|\s]/) {
					PutLine("${host} は適切なネットワーク名ではありません");
					next;
				}
				$hosts{$host} = 1;
			}
			$yesno = 'y';
			$msg = sprintf( "対象機器は、%s ですね。よろしいですか?", join(",", keys(%hosts)));
			GetLine($msg, \$yesno);
			if ($yesno ne 'y') {
				%hosts = ();
			}
		}
	} else {
		for my $host(split(/,/, $NETWORKS)) {
			$hosts{$host} = 1;
		}
	}
	# SNMPコミュニティ名の入力
	while (1) {
		GetLine("SNMPコミュニティを入力して下さい ", \$COMMUNITY);
		last if ($COMMUNITY!~/[\/|\s]/ && $COMMUNITY ne '');
		PutLine("${COMMUNITY} は適切なコミュニティ名ではありません") if ($COMMUNITY ne '');
	}

	# SNMPバージョンの入力
	while (1) {
		GetLine("SNMPバージョン[1,2c,3]を入力して下さい ", \$SNMP_VER);
		last if ($SNMP_VER=~/^(1|2c|3)$/);
		PutLine("${SNMP_VER} は適切なバージョン名ではありません") if ($SNMP_VER ne '');
	}

	if (scalar(keys %hosts) > 0 && $COMMUNITY ne '' && $SNMP_VER ne '') {
		$$ref_snmp->{hosts}     = \%hosts;
		$$ref_snmp->{community} = $COMMUNITY;
		$$ref_snmp->{snmp_ver}  = $SNMP_VER;
		$rc = 1;
	}
	return $rc;
}

# SNMPユーティリティのパスとバージョンをチェック
sub checkSnmpUtilPathAndVersion {
	my ($ref_snmp) = @_;
	my $yesno = 'n';
	my $msg   = '';

	for my $cmd (['snmpwalk', 'snmpget']) {
		my @buf = `which $cmd`;
	}
	return 1;
}

# ネットワークインターフェースの検証

sub verifyNetInterface {
	my ($ref_snmp) = @_;
	my $sfx = 1;
	for my $host(keys %{$$ref_snmp->{hosts}}) {
		PutLine("${host}をチェックします");
		for my $oid('ifOperStatus', 'ifDescr') {
			my $test = "${oid}_${host}";
			my $cmd  = "snmpwalk -c ${COMMUNITY} -v ${SNMP_VER} ${host} ${oid} " .
				"1> \"${ODIR}/${test}.out\" 2> \"${ODIR}/${test}.err\"";

			PutLine("EXEC[ $cmd ]");
			my $rc = system($cmd);
			my $msg = ($rc == 0)?'OK':'NG';
			PutLine("結果 : ${msg}");
			$$ref_snmp->{$oid}{$sfx}{host} = $host;
			$$ref_snmp->{$oid}{$sfx}{cmd}  = $cmd;
			$$ref_snmp->{$oid}{$sfx}{out}  = "${test}.out";
			$$ref_snmp->{$oid}{$sfx}{err}  = "${test}.err";
			$$ref_snmp->{$oid}{$sfx}{rc}   = $rc;
		}
		$sfx ++;
	}
}

# ネットワークインターフェース検証レポート
sub reportNetInterface {
	my ($ref_snmp) = @_;

	# ネットワークインターフェースの検証結果集計
	my %device = ();
	for my $oid ('ifOperStatus', 'ifDescr'){
		for my $host_id(sort keys %{$$ref_snmp->{$oid}}) {
			my $rc   = $$ref_snmp->{$oid}{$host_id}{rc};
			my $out  = $$ref_snmp->{$oid}{$host_id}{out};
			my $host = $$ref_snmp->{$oid}{$host_id}{host};
			$device{$host_id}{rc}   = $rc;
			$device{$host_id}{host} = $host;
			if ($rc == 0) {
				open(IN, "${ODIR}/${out}") || die "${ODIR}/${out} : $@";
				while (<IN>) {
					# IF-MIB::ifOperStatus.1 = INTEGER: up(1) のみ抽出
					if ($_=~/fOperStatus\.(\d+) = INTEGER: up/) {
						my $device_id = $1;
						$device{$host_id}{oid}{$device_id}{ifOperStatus} = 'up';
					}
					# IF-MIB::ifDescr.1 = STRING: LAN1 で　up の I/F のみ抽出
					if ($_=~/ifDescr\.(\d+) = (.*)$/) {
						my ($device_id, $ifDescr) = ($1, $2);
						$ifDescr=~s/^STRING:\s+//g;
						if (defined($device{$host_id}{oid}{$device_id})) {
							$device{$host_id}{oid}{$device_id}{ifDescr} = $ifDescr;
						}
					}
				}
			}
		}
	}

	my $buf = '';
	$buf  = "community: $$ref_snmp->{community}\n";
	$buf .= "version: $$ref_snmp->{snmp_ver}\n";
	$buf .= "hosts: \n";
	for my $host_id(sort keys %device) {
		$buf .= "  ${host_id}: \n";
		$buf .= "    host: $device{$host_id}{host}\n";
		$buf .= "    rc: $device{$host_id}{rc}\n";
		if (defined($device{$host_id}{oid})) {
			$buf .= "    devices: \n";
			my %devs = %{$device{$host_id}{oid}};
			for my $device_id(sort keys %devs) {
				$buf .= "      $device_id: $devs{$device_id}{ifDescr}\n";

			}
		}
	}
	my $ofile = "$ODIR/check_snmp.yaml";
	PutLine("${ofile}に検証結果を出力します");
	open (OUT, ">$ofile") || die "$ofile : $@";
	print OUT $buf;
	close(OUT);
}

# プリント出力

sub PutLine {
	my ($line, $noreturn) = @_;
	if ($^O eq 'solaris') {
		$line = encode('euc-jp', $line);
	} else {
		$line = encode('utf-8', $line);
	}
	if ($noreturn) {
		print $line;
	} else {
		print $line . "\n";
	}
}

# メッセージを出力し、1行入力する

sub GetLine {
	my ($msg, $buf) = @_;

	my $line = $msg;
	$line .= ($$buf eq '')?' ':' [' . $$buf . '] ';
	if ($^O eq 'solaris') {
		$line = encode('euc-jp', $line);
	} else {
		$line = encode('utf-8', $line);
	}
	print $line;
	my $res = '';
	$res = <>;
	$res =~ s/[\r\n]+//g;	# chompの替わり
	if ($res ne '') {
		$$buf = $res;
	}
}

# 実行パスの絶対パスの取得

sub GetAbsPath {
	my $pwd_push = `pwd`; 
	$pwd_push =~ s/[\r\n]+//g;

	my $dirname = `dirname $0`;
	$dirname =~ s/[\r\n]+//g;

	chdir($dirname);
	my $pwd = `pwd`;
	$pwd =~ s/[\r\n]+//g;
	chdir($pwd_push);
	
	return $pwd;
}

