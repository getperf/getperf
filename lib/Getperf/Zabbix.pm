use strict;
use warnings;
# use experimental 'switch';
package Getperf::Zabbix;
use Clone qw(clone);
use Getopt::Long;
use Path::Class;
use Time::Piece;
use Data::Dumper;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Data::NodeInfo;
use parent qw(Class::Accessor::Fast);
use Log::Handler app => "LOG";
use Zabbix::API;
use JSON::RPC::Legacy::Client;

__PACKAGE__->mk_accessors(qw/server url enable/);

our $VERSION = '0.01';

my $zabbix_master_db = {
	'type' => {
		'Zabbix agent'          => 0,
		'SNMPv1 agent'          => 1,
		'Zabbix trapper'        => 2,
		'simple check'          => 3,
		'SNMPv2 agent'          => 4,
		'Zabbix internal'       => 5,
		'SNMPv3 agent'          => 6,
		'Zabbix agent (active)' => 7,
		'Zabbix aggregate'      => 8,
		'web item'              => 9,
		'external check'        => 10,
		'database monitor'      => 11,
		'IPMI agent'            => 12,
		'SSH agent'             => 13,
		'TELNET agent'          => 14,
		'calculated'            => 15,
		'JMX agent'             => 16,
		'SNMP trap'             => 17,
	},
	'value_type' => {
		'numeric float'         => 0,
		'character'             => 1,
		'log'                   => 2,
		'numeric unsigned'      => 3,
		'text'                  => 4,
	}
};

sub new {
	my $class = shift;

	my $zabbix_conf = config('zabbix');
	config('base')->add_screen_log;

	my $zabbix_config_file = file($ENV{'SITEHOME'}, ".zabbix");
	if ($zabbix_config_file->stat) {
		my $config_json_text = $zabbix_config_file->slurp || die $@;
    	$zabbix_conf = decode_json($config_json_text);
	}
	my $server = $zabbix_conf->{ZABBIX_SERVER_IP} || 'localhost';
	my $url_prefix = $zabbix_conf->{ZABBIX_SERVER_URL} || "http://${server}/zabbix";

	bless {
		server     => $server,
		url        => "${url_prefix}/api_jsonrpc.php",
		user       => $zabbix_conf->{ZABBIX_ADMIN_USER}        || 'Admin',
		password   => $zabbix_conf->{ZABBIX_ADMIN_PASSWORD}    || 'zabbix',
		enable     => $zabbix_conf->{GETPERF_AGENT_USE_ZABBIX} || 1,
		multi_site => $zabbix_conf->{USE_ZABBIX_MULTI_SITE}    || 0,
		print_only => 0,
		command    => undef,
		zabber     => undef,
		sitekey    => undef,
		node_info  => undef,
		node_list  => undef,
		node_dir   => undef,
		@_,
	}, $class;
}

sub parse_command_option {
	my ($self, $args) = @_;

	Getopt::Long::Configure("pass_through");
	my $usage = "Usage : zabbix-cli\n" .
        "  [--hosts={.hosts}] [--node-dir={path}] [--add|--rm|--info] {./node/{domain}/...}\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	my %config = ();
	my $node_list_tsv = undef;
	my $node_dir = undef;
	my $opts = GetOptions (
		'--add'        => \$self->{command}{regist},
		'--rm'         => \$self->{command}{delete},
		'--info'       => \$self->{command}{info},
		'--hosts=s'    => \$node_list_tsv,
		'--node-dir=s' => \$self->{node_dir},
		'--help'       => \$self->{help},
	);

	my $command = $self->{command};
	if (!$command->{regist} && !$command->{delete} && !$command->{info}) {
		die "\t[--add|--rm|--info] Required.\n\n" . $usage;
	}
	$self->login;
	if ($self->{node_dir} && $self->{node_dir} !~ /^[\/\w]+/) {
		die "\tnode_dir must contain alphanumeric char and '/'\n\n". $usage;
	}
	for my $target (@ARGV) {
		my $node_info = Getperf::Data::NodeInfo->new(
			file_path => $target, node_list_tsv => $node_list_tsv
		);
		if (!$node_info) {
			next;
		}
		$self->{node_info} = $node_info;
		if ($self->{command}{regist}) {
			$self->regist_node($node_info);

		} elsif ($self->{command}{info}) {
			$self->{print_only} = 1;
			$self->regist_node($node_info);

		} elsif ($self->{command}{delete}) {
			$self->remove_node($node_info);

		} else {
			warn "Unkown command\n" . $usage;
		}

	}
	$self->logout;

	return 1;
}

sub login {
	my ($self) = @_;

	my $zabber = Zabbix::API->new(server => $self->{url});
	eval {
		# $zabber->login(user => $self->{user}, password => $self->{password});
		my $client = new JSON::RPC::Legacy::Client;
		my $json = {
			jsonrpc => "2.0",
			method 	=> "user.login",
			params 	=> {
				user     => $self->{user},
				password => $self->{password}
			},
			id => 1
		};
		my $response = $client->call( $self->{url}, $json );
		die "$@\n" unless $response->content->{'result'};
		$zabber->{cookie} = $response->content->{'result'};
		$zabber->{user} = $self->{user};
	};
	if ($@) {
	    die "Could not log in: $@";
	}
	$self->{zabber} = $zabber;
	return 1;
}

sub logout {
	my ($self) = @_;

	# https://support.zabbix.com/browse/ZBX-9700
	if (my $zabber = $self->{zabber}) {
		eval {
			$zabber->query(method => 'user.logout', params => {});
		};
		if ($@) {
			die 'Could not log out: '.$@;
		}
	}
}

sub check_or_generate_hostgroup {
	my ($self, $group) = @_;

	if (!$group || $group eq '') {
		LOG->crit ("Zabbix Group name must be specified") ;
		return;
	}
	my $zabber = $self->{zabber};
	my $filter = { name => $group };
	my $hostgroups = $zabber->fetch('HostGroup', params => { filter => $filter } );
	if ( @$hostgroups ) {
		my $hostgroup_count = scalar( @$hostgroups );
		if ( $hostgroup_count > 1 ){
			LOG->warn ("The host group search is duplicated. keyword : '$group'");
		}
		return @$hostgroups[0]->{data}->{groupid};
	}
	my $new_hostgroup = Zabbix::API::HostGroup->new(root => $zabber, data => $filter );
	eval { $new_hostgroup->push };
	if ($@) {
		LOG->crit ("Zabbix hostgroup creation error : $@") ;
		return;
	};
	return $new_hostgroup->{data}->{groupid};
}

sub remove_hostgroup {
	my ($self, $group) = @_;

	my $zabber = $self->{zabber};
	my $filter = { name => $group };
	my $hostgroups = $zabber->fetch('HostGroup', params => { search => $filter } );
	if ( @$hostgroups ) {
		return @$hostgroups[0]->delete;
	}
	return;
}

sub check_or_generate_template {
	my ($self, $template_name, $groupid) = @_;

	my $zabber = $self->{zabber};
	my $filter = { filter => { host => [ $template_name ] } };
	my $templates = $zabber->query({method => 'template.get', params => $filter });
	if ( @$templates ) {
		return @$templates[0]->{templateid};
	}
	if (!$groupid) {
		LOG->crit("Zabbix template create error : groupid must be specified");
		return;
	}
	my $params = { host => $template_name, groups => { groupid => $groupid } };
	# if ($parent_templateid) {
	# 	$params->{templates}->{templateid} = $parent_templateid;
	# }
	$templates = $zabber->query({method => 'template.create', params => $params } );
	if ($templates) {
		return $templates->{templateids}->[0];
	}

	return;
}

sub remove_template {
	my ($self, $template_name) = @_;

	my $zabber = $self->{zabber};
	my $params = { filter => { host => [ $template_name ] } };
	my $templates = $zabber->query({method => 'template.get', params => $params });
	if ( $templates ) {
		my $template_id = @$templates[0]->{templateid};
		return $zabber->query({method => 'template.delete', params => [$template_id] });
	}
	return;
}

sub check_or_generate_host {
 	my ($self, $zabbix_host) = @_;
	my ($domain_name, $node_name, $node_info);

	my $zabber      = $self->{zabber};
	my $host_name   = $zabbix_host->{host_name};
	my @host_groups = @{$zabbix_host->{host_groups}};
	my @templates   = @{$zabbix_host->{templates}};

	# Check host exists
	my $params = { host => $host_name, search => { host => $host_name }};
	# my $params = { host => $host_name, search => { host => $host_name }, searchWildcardsEnabled => "true" };
	my $hosts = $zabber->fetch('Host', params => $params);
	#print Dumper $hosts; exit(0);
	if (@$hosts) {
		$zabbix_host->{hostid} = @$hosts[0]->{data}{hostid};
		return 1;
	}

	# Generate hostgroups
	my @group_ids = ();
	for my $host_group(@host_groups) {
		my $groupid = $self->check_or_generate_hostgroup($host_group);
		push(@group_ids, { groupid => $groupid });
	}

	# Generate templates
	my $group_id = $group_ids[0]->{groupid};
	my @template_ids = ();
	for my $template(@templates) {
		my $templateid = $self->check_or_generate_template($template, $group_id);
		push(@template_ids, { templateid => $templateid });
	}
	# Generate host
	my $zabbix_data = {
		host      => $host_name,
		groups    => \@group_ids,
		templates => \@template_ids,
	};
	if ($zabbix_host->{interfaces}) {
		$zabbix_data->{interfaces} = $zabbix_host->{interfaces};
	}
	my $new_host;
	$new_host = Zabbix::API::Host->new(root => $zabber, data => $zabbix_data);
	eval { $new_host->push };
	if ($@) {
		LOG->error("Caught exception: $@ '$host_name'");
		return;
	};
	if (defined($new_host->{data}{hostid})) {
		$zabbix_host->{hostid} = $new_host->{data}{hostid};
		return 1;
	}

	return;
}

sub get_host_interface_id {
	my ($self, $zabbix_host) = @_;

	my $zabber      = $self->{zabber};
	my $hostid      = $zabbix_host->{hostid};
	my $ip          = $zabbix_host->{ip};

	my $filter = { "output" => "extend", "hostids" => $hostid };
	my $host_interfaces = $zabber->query(
		{method => 'hostinterface.get', params => $filter }
	);
	# print Dumper $zabbix_host;
	# print Dumper $filter;

	# print Dumper $host_interfaces;
	for my $host_interface(@$host_interfaces) {
		if ($host_interface->{ip} eq $ip) {
			return $host_interface->{interfaceid};
		}
	}
}

sub check_or_generate_items {
 	my ($self, $zabbix_host, $zabbix_items) = @_;
	my $zabber      = $self->{zabber};
	my $hostid      = $zabbix_host->{hostid};
	my $host_name   = $zabbix_host->{host_name};

	# Get host interface id
	my $interfaceid = $self->get_host_interface_id($zabbix_host);
	if (!$interfaceid) {
		LOG->error("Host interfaceid not found: '$host_name'");
		return;
	}

	for my $item(@$zabbix_items) {
		# Check item exists
		my $item_name = $item->{item_name};
		my $filter = { "key_" => $item->{key}, "hostids" => $hostid };
		my $item_exists = $zabber->fetch('Item', params => {search => $filter});
		if (@$item_exists) {
		 	$item->{itemid} = @$item_exists[0]->{data}{itemid};
			next;
		}

		my $item_entry;
		for my $entry (qw/type value_type/) {
			my $item_key = $item->{$entry};
			if (!defined( $zabbix_master_db->{$entry}{$item_key} )) {
				LOG->error("Zabbix item ${entry} id not found: '${item_key}'");
				return;
			}
			$item_entry->{$entry} = $zabbix_master_db->{$entry}{$item_key};
		}
		my $params = {
			name        => $item->{item_name},
			key_        => $item->{key},
			hostid      => $hostid,
			type        => $item_entry->{type},
			value_type  => $item_entry->{value_type},
			interfaceid => $interfaceid,
			delay       => $item->{delay},
		};
		my $new_item = $zabber->query({method => 'item.create', params => $params } );
		if ($@) {
			LOG->error("Caught exception: $@ '$host_name','$item_name'");
			return;
		};
	 	# $item->{itemid} = @$new_item[0]->{data}{itemid};
	}
	return 1;
}

sub remove_host {
	my ($self, $node_name) = @_;

	my $zabber = $self->{zabber};

	my $hosts = $zabber->fetch('Host', params => {
		host => $node_name,
		search => { host => $node_name }
	});
	if (!@$hosts) {
		LOG->warn("Not found Zabbix host : '$node_name'.");
		return;
	}
	eval { @$hosts[0]->delete };
	if ($@) {
		LOG->error("Caught exception: $@ '$node_name'");
		return;
	};
	return 1;
}

sub read_zabbix_domain_template {
	my ($self, $domain) = @_;

	my $site_lib = $self->{node_info}->{site_info}->{lib};
	my $template_path = file($site_lib, 'zabbix', $domain . '.json');
	if (-f $template_path) {
		my $template_text = $template_path->slurp || die "$!";
		return decode_json($template_text);
	}
}

sub read_zabbix_item_template {
	my ($self, $domain, $item_key) = @_;

	my $site_lib = $self->{node_info}->{site_info}->{lib};
	my $template_path = file($site_lib, 'zabbix', $domain, $item_key . '.json');
	if (-f $template_path) {
		my $template_text = $template_path->slurp || die "$!";
		return decode_json($template_text);
	}
}

sub create_zabbix_host_from_template {
	my ($self, $template, $node_info) = @_;
	my $host_info = clone($template);
	for my $key(keys %{$host_info}) {
		if (ref(my $objs = $host_info->{$key}) eq 'ARRAY') {
			map {
				$_=~s/<node>/$node_info->{node}/g if ($node_info->{node});
			} @{$objs};
		} else {
			$host_info->{$key}=~s/<node>/$node_info->{node}/g if ($node_info->{node});
		}
	}
	return $host_info;
}

sub create_zabbix_items_from_template {
	my ($self, $template, $item_info) = @_;

	my @items = ();
	if (ref($item_info) eq 'HASH') {
		for my $device_key(keys %$item_info) {
			my $device_value = $item_info->{$device_key};
			my $item = clone($template);
			for my $key(keys %{$item}) {
				my $str = $item->{$key};
				$str=~s/<device\.key>/$device_key/g;
				$str=~s/<device\.value>/$device_value/g;
				$item->{$key} = $str;
			}
			push(@items, $item);
		}

	} elsif (ref($item_info) eq 'ARRAY') {
		for my $device_key(@$item_info) {
			my $item = clone($template);
			for my $key(keys %{$item}) {
				my $str = $item->{$key};
				$str=~s/<device>/$device_key/g;
				$item->{$key} = $str;
			}
			push(@items, $item);
		}

	}
	return \@items;
}

sub parse_zabbix_item_rule {
	my ($self, $node) = @_;
	my $domain_name = $node->{domain};

	# Parse item config rule
	my $zabbix_items = undef;
	my %node_item_info = %{$node->{node_info}};
	for my $item_key(keys %node_item_info) {
		my $item_info = $node_item_info{$item_key};
		if (my $item_templates = $self->read_zabbix_item_template($domain_name, $item_key)) {
			for my $item_template(@{$item_templates}) {
				my $items = $self->create_zabbix_items_from_template($item_template, $item_info);
				push(@$zabbix_items, @$items);
			}
		}
	}

	return $zabbix_items;
}

sub merge_additional_node_path_host_info {
	my ($self, $zabbix_host, $node_path) = @_;

	$node_path=~s/,/_/g;
	my $node_dir = $node_path || '';
	$node_dir =~s|^/*(.*)/(.+?)$|$1|;
	$node_dir =~s|/| - |g;
	if ($self->{multi_site}) {
		my $dir = $self->{node_info}{site_info}{sitekey};
		if ($node_dir ne '') {
			$dir = $dir . ' - ' . $node_dir;
		}
		$node_dir = $dir;
	}
	if ($node_dir ne '') {
		my @addition_groups = map {	$_ . ' - ' . $node_dir;	} @{$zabbix_host->{host_groups}};
		push (@{$zabbix_host->{host_groups}}, @addition_groups);
		my @addition_templates = map {	$_ . ' - ' . $node_dir;	} @{$zabbix_host->{templates}};
		push (@{$zabbix_host->{templates}}, @addition_templates);
	}
}

sub merge_additional_interface_host_info {
	my ($self, $zabbix_host, $ip) = @_;
	$zabbix_host->{interfaces} = [
       	{
       		type => 1,
       		main => 1,
       		dns => "",
       		port => "10050",
       		ip => $ip,
            useip => 1,
        }
	];
	$zabbix_host->{ip} = $ip;
}

sub dump_zabbix_registration_info {
	my ($self, $zabbix_host, $zabbix_items) = @_;

	local $Data::Dumper::Indent   = 1;
	local $Data::Dumper::Purity   = 1;
	local $Data::Dumper::Sortkeys = 0;
	local $Data::Dumper::Deepcopy = 1;

	my $content_host  = Dumper $zabbix_host;
	$content_host =~s/\$VAR1 = /host => /g;
	my $content_items = Dumper $zabbix_items;
	$content_items =~s/\$VAR1 = /items => /g;

	print $content_host . $content_items;
}


sub regist_node {
	my ($self, $node_info) = @_;

	my $node = $node_info->fetch_first_node;
	while($node) {
		my $domain_name = $node->{domain};
		my $node_name   = $node->{node};

		LOG->notice("Regist Zabbix node $domain_name/$node_name\n");
		# Parse host config rule
		my $zabbix_host;
		if (my $host_template = $self->read_zabbix_domain_template($domain_name)) {
			$zabbix_host = $self->create_zabbix_host_from_template($host_template, $node);
		}
		if ($zabbix_host) {
			# If a node_path is set, add it for the host groups and templates
			my $node_path = $node->{node_info}{node_path} || '';
			if ($self->{node_dir}) {
				$node_path = $self->{node_dir} . '/' . $node_name;
			}
			$self->merge_additional_node_path_host_info($zabbix_host, $node_path);

			if ($zabbix_host->{is_physical_device}) {
				if (my $ip = $node->{node_info}{ip}) {
					$self->merge_additional_interface_host_info($zabbix_host, $ip);
				} else {
					LOG->error("IP address lookup failure : ${node_name}. SKIP");
					$node = $node_info->fetch_next_node;
					next;
				}
			} else {
				$self->merge_additional_interface_host_info($zabbix_host, '127.0.0.1');
			}
			my $zabbix_items = $self->parse_zabbix_item_rule($node);

			if ($self->{print_only}) {
				$self->dump_zabbix_registration_info($zabbix_host, $zabbix_items);
			} else {
				if (! $self->check_or_generate_host($zabbix_host) ) {
					LOG->info("check_or_generate_host() failed. SKIP");
					$node = $node_info->fetch_next_node;
					next;
				}
				if (! $self->check_or_generate_items($zabbix_host, $zabbix_items) ) {
					LOG->info("check_or_generate_items() failed. SKIP");
				}
			}
		} else {
			LOG->warn("Zabbix host parse error : $domain_name, $node_name. SKIP");
		}
		$node = $node_info->fetch_next_node;
	}

	return 1;
}

sub remove_node {
	my ($self) = @_;
	my $node_count = 0;
	my $node_infos = $self->{node_info};
	my $node = $node_infos->fetch_first_node;

	while($node) {
		my $node_name = $node->{node};
		$node = $node_infos->fetch_next_node;
		LOG->notice("Remove Zabbix node $node_name\n");
		if (!$self->remove_host($node_name)) {
			LOG->warn("remove_host() failed. skip. '$node_name'");
			next;
		}
		$node_count ++;
	}
	return 1;
}

1;
