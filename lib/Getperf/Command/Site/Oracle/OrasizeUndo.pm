package Getperf::Command::Site::Oracle::OrasizeUndo;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

# Date:16/05/30 11:01:00
# ACTIVE,UNDOTBS,303.3125
# EXPIRED,UNDOTBS,6019.1875
# UNDO ALLOCATION SIZE,UNDOTBS,14089.0625
# UNDO DEFINE SIZE,UNDOTBS,48400
# UNEXPIRED,UNDOTBS,7766.5625

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my @headers = qw/active expired undo_alloc undo_define unexpired/;
	my %labels = (
		'ACTIVE', 'active',
		'EXPIRED', 'expired',
		'UNDO ALLOCATION SIZE', 'undo_alloc',
		'UNDO DEFINE SIZE', 'undo_define',
		'UNEXPIRED', 'unexpired',
	);
	$data_info->step($step);
	$data_info->is_remote(1);

	# my $instance = 'Y2URA0';
	# if ( $data_info->file_name =~/^orasize_undo_(.+)$/ ) {
	# 	$instance = $1;
	# }
    my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		my ($item, $tbs, $value) = split(/\s*\|\s*/, $line);
		next if (!defined($item));
		if (defined(my $ds = $labels{$item})) {
			$results{$sec}{$ds} += $value;
		}
	}
	close($in);
	$data_info->regist_metric($instance, 'Oracle', 'ora_undo_size', \@headers);
	my $output = "Oracle/${instance}/ora_undo_size.txt";
	$data_info->pivot_report($output, \%results, \@headers);

	return 1;
}

1;
