package Getperf::Command::Site::SNMPNetworkConfig::CheckSnmp;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Path::Class;
use YAML::Tiny;
use base qw(Getperf::Container);
use Getperf::Command::Master::SNMPNetworkConfig;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

    my $snmp_config_text = file($data_info->input_file)->slurp;
    my $snmp_config_yaml = YAML::Tiny->read_string($snmp_config_text);
    my $snmp_configs = $snmp_config_yaml->[0];

    for my $id(sort keys %{$snmp_configs->{hosts}}) {
     	my $config  = $snmp_configs->{hosts}{$id};
     	my $host    = $config->{host};
     	my $system  = $config->{sysName};
		my $devices = $config->{devices};

		my ($alias_devices, $alias_main_devices);
		for my $id (sort keys %$devices) {
			if (my $alias = alias_network_port($system, $devices->{$id})) {
				my $device_text = $alias->{device};
				push (@{$alias_devices->{id}},  $id);
				push (@{$alias_devices->{text}}, $device_text);
				if ($alias->{main_port}) {
					push (@{$alias_main_devices->{id}},  $id);
					push (@{$alias_main_devices->{text}}, $device_text);
				}
			}
		}

		if (my $alias_network = alias_network($system)) {
	     	my %infos = (node_alias => $system, node_path => "$alias_network/$host");
			$data_info->regist_node($host, 'SNMPNetwork', 'info/model', \%infos);
		}
		$data_info->regist_devices_alias($host, 'SNMPNetwork', 'snmp_network_port',
			                            'snmp_network_port_alias',
			                            \@{$alias_devices->{id}}, \@{$alias_devices->{text}});
		$data_info->regist_devices_alias($host, 'SNMPNetwork', 'snmp_network_port',
			                            'snmp_network_main_port_alias',
			                            \@{$alias_main_devices->{id}}, \@{$alias_main_devices->{text}});
    }
	return 1;
}

1;
