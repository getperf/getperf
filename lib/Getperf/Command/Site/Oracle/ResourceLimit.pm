package Getperf::Command::Site::Oracle::ResourceLimit;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Log::Handler app => 'Log';
use Log::Handler::Output::File::Stamper;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

my %MAX_USAGE_TH = ('sessions' => 90, 'processes' => 90);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my @headers = qw/curr_util max_util initial_alloc limit_value/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $site_info = $data_info->site_info;

	my $log = Log::Handler->new();
	$log->add( file => +{
			filename => $site_info->storage . "/oracle_resource_limit.log",
			permissions => '0664',
		}
	);

	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	my $inst_id = undef;
	my $alarm = '';
	while (my $line = <IN>) {
		next if ($line=~/^Date:/ || $line=~/^\s*RESOURCE_NAME/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		# my ($sid, $spid, $user, $command, $status, @csvs) = split(/\s*\|\s*/, $line);
		my @csvs = split(/\s*\|\s*/, $line);
		# print scalar(@csvs) . "\n";
		if (scalar(@csvs) == 6) {
			$inst_id = shift(@csvs);
		} elsif (scalar(@csvs) != 5) {
			next;
		}
		my $resource_name = shift(@csvs);
		if ($resource_name !~/(processes|sessions)/) {
			next;
		}
		my $node = $host;
		if ($inst_id) {
			$node .= sprintf("_instance%d", $inst_id);
		}
		# max_util usage の閾値チェック
		my ($max_util, $limit_value) = ($csvs[1], $csvs[3]);
		my $pct = ($limit_value == 0) ? 0 : $max_util/$limit_value;
		if (defined(my $th = $MAX_USAGE_TH{$resource_name})) {
			$pct = $pct * 100.0;
			if ($pct > $th) {
				my $th_s = sprintf("%0.1f", $th);
				my $pct_s = sprintf("%0.1f", $pct);
				$log->crit("${node} Oracle ${resource_name} max usage is over ${th_s}% : ${pct_s}%");
			}
		}
		$results{$node}{$resource_name}{$sec} = join(" ", @csvs);
	}
	close(IN);
	for my $node(keys %results) {
		for my $metric(keys %{$results{$node}}) {
			my $output = "Oracle/${node}/device/resource__${metric}.txt";
			my $data   = $results{$node}{$metric};
			$data_info->regist_device($node, 'Oracle', "resource", $metric, $metric, \@headers);
			$data_info->simple_report($output, $data, \@headers);
		}
	}
	return 1;
}

1;
