package Getperf::Command::Site::Oracle::OraTbs;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %zabbix_send_data);
	my $step = 3600;
	my @headers = qw/total_mb used_mb usage available_mb/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}

	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		my ($tbs, @values) = split(/\s*\|\s*/, $line);
		next if (!defined($tbs) || $tbs eq 'TABLESPACE_NAME');
		$results{$tbs}{$sec} = join(' ', @values);
		my $zabbix_item = "adm.oracle.tbs.usage." . $tbs;
		$zabbix_send_data{$sec}{$zabbix_item} = $values[2];
	}
	close($in);
	for my $tbs(keys %results) {
		$data_info->regist_device($instance, 'Oracle', 'ora_tbs', $tbs, undef, \@headers);
		my $output = "Oracle/${instance}/device/ora_tbs__${tbs}.txt";	# Remote collection
		$data_info->simple_report($output, $results{$tbs}, \@headers);
	}

	my %stats = ();
	my @tablespaces = keys %results;
	$stats{ora_tbs} = \@tablespaces;
	my $info_file = "info/ora_tbs__${instance}";
	$data_info->regist_node($instance, 'Oracle', $info_file, \%stats);
	$data_info->report_zabbix_send_data($instance, \%zabbix_send_data);

	return 1;
}

1;
