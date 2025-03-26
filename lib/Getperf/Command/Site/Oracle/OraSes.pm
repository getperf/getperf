package Getperf::Command::Site::Oracle::OraSes;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my @headers = qw/count/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		# print $line . "\n";
		next if ($line=~/^Date:/ || $line=~/^\s*SID/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		my ($sid, $spid, $user, $command, $status, @csvs) = split(/\s*[\|,]\s*/, $line);
		if (defined($status)) {
			$results{$status}{$sec} += 1;
		}
	}
	close(IN);
	for my $status(keys %results) {
		my $output = "Oracle/${host}/device/ora_ses__${status}.txt";
		my $data   = $results{$status};
		$data_info->regist_device($host, 'Oracle', "ora_ses", $status, $status, \@headers);
		$data_info->simple_report($output, $data, \@headers);
	}
	return 1;
}

1;
