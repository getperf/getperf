package Getperf::Data::NodeInfo;

use strict;
use warnings;
use JSON::XS;
use Path::Class;
use Data::Dumper;
use Hash::Merge::Simple qw/ merge /;
use Log::Handler app => "LOG";
use Socket;
use Getperf::Config 'config';
use Getperf::Data::SiteInfo;
use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/site_info node_infos/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my $self = bless {
		site_info  => undef,
		node_infos => undef,
		ip_lookup  => undef,
		node_lists => undef,
		node_seq   => undef,
		node_list_tsv => undef,
		@_,
	}, $class;
	if (my $file_path = $self->{file_path}) {
		unless ($self->parse_path($file_path)) {
			return;
		}
	}
	return $self;
}

sub parse_path {
	my ($self, $node_path) = @_;
	my $site_info = Getperf::Data::SiteInfo->get_instance_from_path($node_path);
	$self->site_info($site_info);
	my @node_info_jsons = ();
print "node_path:$node_path\n";
	if (-d $node_path && $node_path=~m|(^\|/)node|) {
		dir($node_path)->recurse(callback => sub {
			push(@node_info_jsons, shift);
		});
	} elsif (-f $node_path && $node_path=~m|(^\|/)node/(.*)\.json$|) {
		push(@node_info_jsons, file($node_path));
	} else {
		LOG->crit("Node directory must be specified '$node_path'.");
		return;
	}
# print Dumper \@node_info_jsons;
	my %node_infos = ();
	my $metric_count = 0;
	for my $node_info_json(@node_info_jsons) {
		if ($node_info_json=~m|(^\|/)node/(.+)/(.+)/info/(.+)\.json|) {
			my ($domain, $node, $metric) = ($2, $3, $4);
			my $node_info_text = $node_info_json->slurp || die "$!";
			my $node_info = decode_json($node_info_text);
			$node_infos{$domain}{$node} = merge($node_infos{$domain}{$node},
                                                $node_info);
			$metric_count ++;
		# ディレクトリが、'node/{ホスト}/{ドメイン}' の場合は空のノード情報を登録
		} elsif ($node_info_json=~m|(^\|/)node/(.+)|) {
			my @paths = split(/\//, $2);
			if (scalar(@paths) == 2) {
				my ($domain, $node) = @paths;
				$node_infos{$domain}{$node} = {};
				$metric_count ++;
				# print Dumper \@paths;
			}
		}
	}
print "metric_count:$metric_count\n";
print Dumper \%node_infos;
	$self->{node_infos} = \%node_infos;
	if (! $self->load_node_ip_lists ) {
		LOG->error("Load error of node IP List file");
		return;
	}
	if (! $self->generate_node_list ) {
		LOG->error("Node List creation error");
		return;
	}

	return 1;
}

sub load_node_ip_lists {
	my ($self) = @_;

	my @load_ip_files = ('/etc/hosts');
	my $site_hosts = $self->{site_info}->{home} . '/.hosts';
	if (-f $site_hosts) {
		push(@load_ip_files, $site_hosts);
	}
	if (my $node_list_tsv = $self->{node_list_tsv}) {
		if (!-f $node_list_tsv) {
			LOG->crit("Not found node_list.tsv '$node_list_tsv'.");
			return;
		} else {
			push(@load_ip_files, $node_list_tsv);
		}
	}
	for my $load_ip_file(@load_ip_files) {
		my @node_lists = file($load_ip_file)->slurp;
		my $row = 1;
		for my $node_list(@node_lists) {
			if ($node_list=~/^\s*#/ || $node_list=~/^\s*$/) {
				next;
			}
			$node_list =~s/(\r|\n)//g;
			$node_list =~s/#.*$//g;
			my ($ip, @nodes) = split(/\t|\s/, $node_list);
			if (!@nodes || !$ip) {
				my $msg = "'Ip\tNode' required : '$node_list'.";
				LOG->warn("Parse error of '$load_ip_file' : $msg");
				next;
			}
			for my $node(@nodes) {
				$self->{ip_lookup}{$node} = $ip;
			}
			$row ++;
		}
		LOG->info("Load $load_ip_file : $row rows.");
	}
	return 1;
}

sub add_node {
	my ($self, $domain, $node, $node_info) = @_;
	$self->{node_infos}{$domain}{$node} = $node_info;
}

sub generate_node_list {
	my ($self) = @_;

	my $node_infos = $self->node_infos;
	my @node_list = ();
	for my $domain(sort keys %$node_infos) {
		for my $node(sort keys %{$node_infos->{$domain}}) {
			my $node_info = $node_infos->{$domain}{$node};

			my $ip = undef;
			if (defined($self->{ip_lookup}{$node})) {
				$ip = $self->{ip_lookup}{$node};
			} else {
				my $inet = inet_aton($node);
				$ip = ($inet) ? inet_ntoa($inet) : '';
			}
			$node_info->{ip} = $ip;
			push(@node_list, {domain => $domain, node => $node, node_info => $node_info});
			$node_infos->{$domain}{$node} = $node_info;
		}
	}
	$self->{node_list} = \@node_list;
	return 1;
}

sub fetch_first_node {
	my ($self) = @_;
	$self->{node_seq} = 0;
	my @node_lists = @{$self->{node_list}};
	return $node_lists[0];
}

sub fetch_next_node {
	my ($self) = @_;

	$self->{node_seq} ++;
	my $node_seq  = $self->{node_seq};
	my @node_list = @{$self->{node_list}};
	if ($node_list[$node_seq]) {
		return $node_list[$node_seq];
	}
	return;
}

sub write {
	my ($self, $info_file, $buf) = @_;

	my $node_count = 0;
	my $node = $self->fetch_first_node;
	while($node) {
		my $domain_name = $node->{domain};
		my $node_name   = $node->{node};
		my $node_info   = $node->{node_info};

		$node = $self->fetch_next_node;
		my $info_path = file($self->{site_info}->{home}, 'node', $domain_name, $node_name, 'info', $info_file);
		my $info_path_dir = $info_path->parent;
		$info_path_dir->mkpath if (!-d $info_path_dir);
		my $writer = $info_path->open('w') || die "$! : $info_path";
		$writer->print($buf);
		$writer->close;

		LOG->info("Regist $info_file $domain_name/$node_name\n");
		$node_count ++;
	}
	LOG->notice("Regist '$info_file' $node_count nodes\n");
	return $node_count;
}

1;
