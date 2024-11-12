package Getperf::Command::Site::Oracle::OraAsm;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $results;
	my $step = 600;
	my @headers = qw/total_gb used_gb free_gb usage/;

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
        if ($line!~/^\d/) {
            next;
        }
        $line =~s/,//g; # trim numeric comma : ','
		my ($date, $service, $tbs, $type, @values) = split(/\s*\|\s*/, $line);
		$results->{$service}{$tbs}{$sec} = join(' ', @values);
	}
	close($in);
    for my $service(keys %{$results}) {
        for my $tbs(keys %{$results->{$service}}) {
            $data_info->regist_device($service, 'Oracle', 'ora_asm', $tbs, undef, \@headers);
            my $output = "Oracle/${service}/device/ora_asm__${tbs}.txt";
            $data_info->simple_report($output, $results->{$service}{$tbs}, \@headers);
        }
    }
	return 1;
}

1;
