use strict;
use warnings;
package Getperf::Loader::InfluxLoader;
use Path::Class;
use Time::Piece;
use Object::Container '-base';
use Log::Handler app => "LOG";
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use base qw(Getperf::Container);
use Getperf::Config 'config';
use Getperf::Loader::Influx;
__PACKAGE__->mk_accessors(qw/type/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	bless {
		type => 'InfluxDB',
		@_,
	}, $class;
}

sub run {
	my ($self, $data_info) = @_;

	$self->{row} = 0;
	my $agent = $data_info->host;
	for my $metric(@{$data_info->metrics}) {
		# ノードがエージェントと同じ場合、物理ホストとしてメトリックのみでロードする
		my $load_data = $metric->metric;
		if ($data_info->is_remote == 1) {
			$load_data = $metric->domain . '/' . $metric->node_metric;
		}
		my $rrd_data  = $metric->domain . '/' . $metric->node_metric;
		if ($metric->{devices}) {
			for my $device( @{$metric->{devices}} ) {
				$metric->{load_path} = $load_data . '__' . $device . '.txt';
				$metric->{device}    = $device;
				$self->write_data($metric, $data_info);
			}
		} else {
			$metric->{load_path} = $load_data . '.txt';
			$metric->{device}    = undef;
			# $metric->{rrd_path}  = $rrd_data;
			$self->write_data($metric, $data_info);
		}
	}
	my $row = $self->{row} || 0;
	LOG->info("[InfluxDB] load row=${row}");
}

sub write_data {
	my ($self, $metric, $data_info) = @_;
	if (!$metric->{headers}) {
		return;
	}
	my $load_path = $data_info->absolute_summary_dir . '/' . $metric->{load_path};
	my $influx = Getperf::Loader::Influx->new(%{$metric});
	$influx->load_data($load_path);
	$self->{row} += $influx->{row};
}

1;
