package Getperf::Command::Site::Oracle::OraSeg;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my @headers = qw/mbyte/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		next if ($line=~/^Date:/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		my @columns = split(/\s*\|\s*/, $line);
		if (scalar(@columns) == 13) {
# print $line . "\n";
		my ($OWNER,
			$SEGMENT_TOTAL,
			$TABLE,
			$TABLE_PARTITION,
			$TABLE_SUBPARTITION,
			$INDEX,
			$INDEX_PARTITION,
			$INDE,
			$X_SUBPARTITION,
			$LOBSEGMENT,
			$LOB_PARTITION,
			$LOB_SUBPARTITION,
			$LOBINDEX,
			$MISC) = @columns;
			next if (!defined($OWNER) || $OWNER eq 'OWNER');
			my $device = 'Total|' . $OWNER;
			$results{$device}{$sec} += $SEGMENT_TOTAL;

		} else {
			my ($user, $type, @csvs) = split(/\s*\|\s*/, $line);
			
			next if (!defined($user) || $user eq 'USERNAME');
			my $tablespace = pop(@csvs);
			my $mbyte      = pop(@csvs);
			$type = 'ETC'  if ($type!~/^(TABLE|INDEX)$/);
			$type = lc $type;
			$user = 'MISC' if ($user=~/^(EXFSYS|SYSTEM|SYS|OUTLN|XDB|WMSYS|APPQOSSYS|DBSNMP)$/);
			my $device = $type . '|' . $user;
			$results{$device}{$sec} += $mbyte;
		}

	}
	close(IN);
	print Dumper \%results;
	for my $device(keys %results) {
		my ($type, $user) = split(/\|/, $device);
		next if ($type eq 'etc');
		my $output = "Oracle/${host}/device/ora_seg_${type}__${user}.txt";
		my $data   = $results{$device};
		$data_info->regist_device($host, 'Oracle', "ora_seg_${type}", $user, $user, \@headers);
		$data_info->simple_report($output, $data, \@headers);
	}
	return 1;
}

1;
