package Getperf::Data::MetricInfo;
use strict;
use warnings;
use Log::Handler app => "LOG";
use Data::Dumper;
use Path::Class;
use JSON::XS;
use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/agent_dir site_info domain node nodepath metric step rrd devices device_texts node_metric headers load_path rrd_path infos/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my $self = {
		domain   => '_default',
		step     => undef,
		node     => undef,
		nodepath => undef,
		metric   => undef,
		rrd      => undef,
		devices  => undef,
		headers  => undef,
		device_texts => undef,
		node_metric  => undef,
		@_,
	};
	if ($self->{node} && $self->{metric}) {
		$self->{node_metric} = $self->{node} . '/' . $self->{metric};
	}
	return bless $self, $class;
}

sub save_config {
	my $self = shift;
	# node/HW/{Agent}/cpuinfo.json
	my $metric_name = $self->metric;
	my $node_dir = $self->site_info->node;

	my $metric_path = file($node_dir, $self->domain, $self->node, "${metric_name}.json");
	my $metric_dir = $metric_path->dir;
	if (!-d $metric_dir) {
		if (!File::Path::Tiny::mk($metric_dir)) {
	        LOG->crit("Could not make path '$metric_dir': $!");
	        return;
		}
	}
#	my %metric_config = (domain => $self->domain, node_path => $self->nodepath);
	my %metric_config = ();
	if ($self->{headers}) {
#		$metric_config{nodepath} = $self->nodepath;
		if ($self->devices) {
			$metric_config{rrd} = $self->domain . '/' . $self->node_metric . '__*.rrd';
			$metric_config{devices} = $self->devices;
			if (defined($self->{device_texts})) {
				$metric_config{device_texts} = $self->{device_texts};
			}
		} else {
			$metric_config{rrd} = $self->domain . '/' . $self->node_metric . '.rrd';
		}
	}
	if ($self->{infos}) {
		%metric_config = (%metric_config, %{$self->{infos}});
	}
	my $metric_config_json = JSON::XS->new->pretty(1)->canonical(1)->encode (\%metric_config);
	my $writer = $metric_path->open('w');
	unless ($writer) {
        LOG->crit("Could not write '$metric_path': $!");
        return;
	}
	$writer->print($metric_config_json);
	$writer->close;
}

sub print {
	my $self = shift;
	for my $metric(@{$self->metrics}) {
		my @headers = @{$metric->{headers}};
		print $metric->{metric} . ":\n\theader : " . join(',', @headers) . "\n";
		if ($metric->{devices}) {
			print "\tdevices : " . join(',', @{$metric->{devices}}) . "\n";
		}
	}
}

1;
