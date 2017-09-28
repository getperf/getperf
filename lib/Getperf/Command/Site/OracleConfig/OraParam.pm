package Getperf::Command::Site::OracleConfig::OraParam;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::OracleConfig;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %infos;
	my $host = $data_info->host;
	my $osname = $data_info->get_domain_osname();
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		my ($name, $value) = split(/\s*\|\s*/, $line);
		next if (!defined($name) || $name eq 'NAME');
		$infos{$name} = $value;
	}
	close($in);

	my $dump_dest = $infos{'Diag Trace'};
	my $db   = $infos{instance_name};
	my $alert_log = "${dump_dest}/alert_${db}.log";
	my $info_file = "info/oracle_log__${db}";
	my %stats = ();
	$stats{ora_alert_log}{$db} = $alert_log;
	$data_info->regist_node($host, $osname, $info_file, \%stats);
	return 1;
}

1;
