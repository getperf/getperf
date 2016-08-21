use strict;
use warnings;
package Getperf::Loader::RRDLoader;
use Path::Class;
use Log::Handler app => "LOG";
use parent qw(Class::Accessor::Fast);
use Getperf::Loader::RRD;
use Data::Dumper;
use base qw(Getperf::Container);
__PACKAGE__->mk_accessors(qw/type/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	bless {
		type        => 'RRD',
		row         => 0,
		node_metric => '',
		@_,
	}, $class;
}

sub run {
	my ($self, $data_info) = @_;

	$self->{row} = 0;
	my $agent = $data_info->host;
	my $start = $data_info->{start_date} . '/' . $data_info->{start_time};

	for my $metric(@{$data_info->metrics}) {
		# ノードがエージェントと同じ場合、物理ホストとしてメトリックのみでロードする
		my $load_data   = $metric->metric;
		my $node_metric = $metric->node_metric;
		if ($data_info->is_remote == 1) {
			$load_data = $metric->domain . '/' . $node_metric;
		}
		my $rrd_data  = $metric->domain . '/' . $node_metric;
		if ($metric->{devices}) {
			for my $device( @{$metric->{devices}} ) {
				$metric->{load_path} = $load_data . '__' . $device . '.txt';
				$metric->{rrd_path}  = $rrd_data  . '__' . $device . '.rrd';
				$self->write_data($metric, $data_info);
			}
		} else {
			$metric->{load_path} = $load_data . '.txt';
			$metric->{rrd_path}  = $rrd_data  . '.rrd';
			$self->write_data($metric, $data_info);
		}
	}
	my $e = $self->{errors};
	LOG->info('[RRDCache] load ' . $start . ' ' . $self->{node_metric} . ' ' . $self->{row});
}

sub write_data {
	my ($self, $metric, $data_info) = @_;
	if (!$metric->{headers}) {
		return;
	}
	if (!defined($metric->{step})) {
		$metric->{step} = $data_info->step ;
	}
	my $rrd_path  = file($data_info->absolute_storage_dir, $metric->{rrd_path} );
	my $load_path = file($data_info->absolute_summary_dir, $metric->{load_path} );
	my $rrd = Getperf::Loader::RRD->new(%{$metric});
	$rrd->path($rrd_path);
	if ($data_info->{time_shift_test} && -f $rrd->path) {
		unlink $rrd->path;
	}
	if (!-f $rrd->path) {
		if (!$rrd->create) {
			LOG->crit("RRD create error : $rrd_path");
			return;
		}
	}
	$rrd->load_data($load_path);
	$self->{row} += $rrd->row;
	$self->{node_metric} = $metric->node_metric;
	for my $error_name(keys %{$rrd->{errors}}) {
		$self->{errors}{$error_name} += $rrd->{errors}{$error_name};
	}
	return 1;
}

1;
