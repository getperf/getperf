package Getperf::Command::Base::Linux::Iostat;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

# avg-cpu:  %user   %nice %system %iowait  %steal   %idle
#            0.37    0.00    1.97    0.24    0.00   97.41

# Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util
# sda               0.34    14.29    7.65    1.97   153.33    65.03    45.37     0.01    1.16   0.93   0.89

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/rrqm_s wrqm_s r_s w_s rkb_s wkb_s svctm pct/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	open(my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;	# trim return code

		if ($line=~/^\s*([a-zA-Z]\S*?)\s+(\d.*\d)$/) {
			my ($device, $body) = ($1, $2);
			my $output_file = "device/iostat__${device}.txt";
			$results{$output_file}{headers} = \@headers;
			$data_info->regist_device($host, 'Linux', 'iostat', $device, undef, \@headers);

			my @values = split(/\s+/, $body);
			for my $header(qw/rrqm_s wrqm_s r_s w_s rkb_s wkb_s/) {
				my $value = shift(@values);
				$results{$output_file}{out}{$sec}{$header} = $value;
			}
			$results{$output_file}{out}{$sec}{pct}   = pop(@values);
			$results{$output_file}{out}{$sec}{svctm} = pop(@values);

		} elsif ($line=~/^Device:/) {
			$sec += $step;
		}

	}
	close($in);
	for my $output_file(keys %results) {
		my $headers  = $results{$output_file}{headers};
		$data_info->pivot_report($output_file, $results{$output_file}{out}, $headers);
	}
	return 1;
}

1;
