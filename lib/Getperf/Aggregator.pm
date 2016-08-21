use strict;
use warnings;
package Getperf::Aggregator;
use FindBin;
use Path::Class;
use Getperf::Config 'config';
use Getperf::Container qw/command db loader/;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/data_info elapse_command elapse_load/);

sub new {
	my $class = shift;

	my $self = bless {
		data_info => undef,
		@_,
	}, $class;
	return $self;
}

sub flush {
	my ($self) = @_;
	if (defined(my $data_info = $self->{data_info})) {
		my $site_info = $self->{data_info}->{site_info};
      	my $rrd = Getperf::Loader::RRD->new( site_info => $site_info );
      	$rrd->flush_data();
		if (config('influx')->{GETPERF_USE_INFLUXDB}) {
	      	my $influx = Getperf::Loader::Influx->new( site_info => $site_info );
    	  	$influx->flush_data();
		}
		if (config('zabbix')->{GETPERF_USE_ZABBIX_SEND}) {
			my $Zabbix = Getperf::Loader::ZabbixSend->new( $data_info );
			$Zabbix->flush_data();
		}
	}
	return 1;
}

sub run {
	my ($self, $data_info) = @_;

	return if (!$data_info);
	my $host = $data_info->host;
	my $class_name = $data_info->find_class();
	if (!$class_name) {
		LOG->info("Unkown skip : " . $data_info->file_info);
		return;
	} else {
		LOG->info('command: ' . $data_info->{summary_dir} . ' ' . $class_name );
	}
	eval {
		my $start = [Time::HiRes::gettimeofday()];
		command($class_name)->parse($data_info);
		my $elapse_command = Time::HiRes::tv_interval($start);
		$self->elapse_command($elapse_command);
		LOG->debug("sumup : $class_name, $host, elapse = $elapse_command");
	};
	if ($@) {
		LOG->error($@);
		return;
	}

	if (!$data_info->metrics) {
		return;
	}
	eval {
		my $start = [Time::HiRes::gettimeofday()];

		loader('RRDLoader')->run($data_info);
		if (config('graphite')->{GETPERF_USE_GRAPHITE}) {
			loader('GraphiteLoader')->run($data_info);
		}
		if (config('influx')->{GETPERF_USE_INFLUXDB}) {
			loader('InfluxLoader')->run($data_info);
		}
		if (config('zabbix')->{GETPERF_USE_ZABBIX_SEND}) {
			loader('ZabbixSendLoader')->run($data_info);
		}

		my $elapse_load = Time::HiRes::tv_interval($start);
		$self->elapse_load($elapse_load);
		LOG->debug("load : $class_name, $host, elapse = $elapse_load");
	};
	if ($@) {
		LOG->error($@);
		return;
	}

	{
		my $start = [Time::HiRes::gettimeofday()];
		$data_info->update_node_config;
		my $elapse_update_node_config = Time::HiRes::tv_interval($start);
		LOG->debug("update config : $class_name, $host, elapse = $elapse_update_node_config");
	};
	$self->{data_info} = $data_info;

	return 1;
}

1;
