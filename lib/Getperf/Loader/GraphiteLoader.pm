use strict;
use warnings;
package Getperf::Loader::GraphiteLoader;
use Path::Class;
use Time::Piece;
use Net::Graphite;
use Log::Handler app => "LOG";
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use base qw(Getperf::Container);
use Getperf::Config 'config';
__PACKAGE__->mk_accessors(qw/type/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my $graphite_config = config('graphite');
	my $graphite = Net::Graphite->new(
	     # except for host, these hopefully have reasonable defaults, so are optional
	     host                  => $graphite_config->{GRAPHITE_LOADER_HOST} || '127.0.0.1',
	     port                  => $graphite_config->{GRAPHITE_LOADER_PORT} || 2003,
	     trace                 => 0,                # if true, copy what's sent to STDERR
	     proto                 => 'tcp',            # can be 'udp'
	     timeout               => 5,                # timeout of socket connect in seconds
	     fire_and_forget       => 0,                # if true, ignore sending errors
	     return_connect_error  => 0,                # if true, forward connect error to caller
	);

	bless {
		type       => 'Graphite',
		graphite   => $graphite,
		multi_site => $graphite_config->{USE_GRAPHITE_MULTI_SITE}    || 0,
		@_,
	}, $class;
}

sub run {
	my ($self, $data_info) = @_;

	$self->{row} = 0;
	my $agent = $data_info->host;
	my $sitekey = $data_info->{site_info}->{sitekey};
	for my $metric(@{$data_info->metrics}) {
		# ノードがエージェントと同じ場合、物理ホストとしてメトリックのみでロードする
		my $load_data = $metric->metric;
		if ($data_info->is_remote == 1) {
			$load_data = $metric->domain . '/' . $metric->node_metric;
		}
		my $rrd_data  = $metric->domain;
		if ($self->{multi_site}) {
			$rrd_data  .= '/' . $sitekey;
		}
		$rrd_data  .= '/' . $metric->node_metric;
		if ($metric->{devices}) {
			for my $device( @{$metric->{devices}} ) {
				$metric->{load_path} = $load_data . '__' . $device . '.txt';
				$metric->{rrd_path}  = $rrd_data  . '/' . $device;
				$self->write_data($metric, $data_info);
			}
		} else {
			$metric->{load_path} = $load_data . '.txt';
			$metric->{rrd_path}  = $rrd_data;
			$self->write_data($metric, $data_info);
		}
	}
	LOG->info(sprintf("[Graphite] load row=%d", $self->{row}));
}

sub write_data {
	my ($self, $metric, $data_info) = @_;
	if (!$metric->{headers}) {
		return;
	}

	my %error_count = ();
	my $load_path = $metric->{load_path};
	my $reader = file($data_info->absolute_summary_dir, $load_path )->openr;
	if (!$reader) {
		LOG->crit("Can't read $load_path: $!");
		return;
	}

	my $row        = 0;
	my %send_data;
	while (my $line = $reader->getline ) {
		next if ($row++ < 1 || $line =~/^\s*$/);
		my ($tm, @csvs) = split(/\s+/, $line);
		# my $local_time = Time::Piece::localtime->strptime($tm, '%Y-%m-%dT%H:%M:%S')->epoch;
		for my $item(@{$metric->{headers}}) {
			$send_data{$tm}{$item} = shift(@csvs);
		}
	}
	$reader->close;

	my $graphite = $self->{graphite};
	my $rrdfile  = $metric->{rrd_path};
	$rrdfile =~s/\//./g;
	my $rc = 0;
	if (%send_data) {
 		$rc = $graphite->send(path => $rrdfile, data => \%send_data);
 		$row --;
	}
	$self->{row} += $row;

	return 1;
}

1;
