package Getperf::Command::Site::Solaris::Iostat;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

#                    extended device statistics
#    r/s    w/s   kr/s   kw/s wait actv wsvc_t asvc_t  %w  %b device
#    0.0    0.0    0.0    0.0  0.0  0.0    0.0    0.0   0   0 fd0
#    0.2    2.1    2.9   21.3  0.0  0.1   19.2   49.5   0   0 c1t0d0
#    0.0    0.0    0.0    0.0  0.0  0.0    0.0    0.4   0   0 c0t0d0
#    0.0    0.0    0.0    0.0  0.0  0.0    0.0    0.0   0   0 sol:vold(pid1533)

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;

	my $step = 30;
	$data_info->step($step);
	my @headers = qw/r_s w_s rkb_s wkb_s svctm w pct/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	# my $sec  = $data_info->start_time_sec;
	open( IN, $data_info->input_file ) || die "@!";
	my ($used, $free, $shared, $buffers, $cached);
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code

		if ($line=~/^\s*(\d.*\d)\s+([a-zA-Z]\S*?)\s*$/) {
			my ($body, $device) = ($1, $2);
			if (my $device = alias_iostat($host, $device)) {
				$data_info->regist_device($host, 'Solaris', 'iostat', $device, undef, \@headers);

				my @values = split(/\s+/, $body);
				for my $header(qw/r_s w_s rkb_s wkb_s/) {
					my $value = shift(@values);
					$results{$device}{$sec}{$header} = $value;
				}
				$results{$device}{$sec}{pct}   = pop(@values);
				$results{$device}{$sec}{w}     = pop(@values);
				$results{$device}{$sec}{svctm} = pop(@values);
			}

		} elsif ($line=~/^\s+r\/s/) {
			$sec += $step;
		}
	}
	close(IN);
	for my $device(keys %results) {
		my $output_file = "device/iostat__${device}.txt";
		$data_info->pivot_report($output_file, $results{$device}, \@headers);
	}
	return 1;
}

1;
