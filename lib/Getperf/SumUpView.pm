package Getperf::SumUpView;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin;
use Path::Class;
use Log::Handler app => "LOG";
use Getperf::Config 'config';
use JSON::XS;
use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/input_paths view_path base_dir tenant view_file/);

sub new {
	config('base')->add_screen_log;
	bless{},+shift;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = 'Usage : report_config.pl ' . 
		"\n\t[input file or directory]\n\t[--config=file]\n\t[--grep=keyword]\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--config=s' => \$self->{config},
		'--grep=s'   => \$self->{grep},
	);
	unless (@ARGV) {
		print "No input path\n" . $usage;
		return;
	}
	for my $input_path(@ARGV) {
		$self->{input_paths}{$input_path} = 1;	
	}
	return 1;
}

sub run {
	my $self = shift;

	my @input_files = ();
	for my $input_path(sort keys %{$self->{input_paths}}) {
		if (-f $input_path) {
			push(@input_files, file($input_path));
		} elsif (-d $input_path) {
			dir($input_path)->recurse(callback => sub {
				my $input_file = shift;
				push(@input_files, $input_file) if (-f $input_file);
			});
		}
	}
	for my $input_file(@input_files) {
		my $path = $input_file->absolute->resolve->stringify;
		next if ($path !~m|^(.*)/view/(.+?)/(.+)\.json$|);
		$self->{view_path} = $path;
		$self->{base_dir}  = $1;
		$self->{tenant}    = $2;
		$self->{view_file} = $3;
		$self->report_view_config;
	}

	return 1;
}

sub get_vm_info {
	my ($self, $node) = @_;
	my $infos;
	# {sitedir}/node/VM/{node}/hw.json
	my $node_path = file($self->{base_dir}, 'node', $self->{view_file}, $node, 'hw.json');
	if (-f $node_path) {
		$infos = decode_json(file($node_path)->slurp);
	}
	my @csv = (
		$infos->{cluster_name}    || 'NaN',
		$infos->{host_name}       || 'NaN',
		$infos->{guest_full_name} || 'NaN',
		$infos->{vcpu}            || 'NaN',
		$infos->{mem_size}        || 'NaN',
		$infos->{disk_size}       || 'NaN',
	);
	return(\@csv);
}

sub report_view_config {
	my $self = shift;

	my $nodes_path = $self->view_path;
	my $nodes_json = decode_json(file($nodes_path)->slurp);
	if (!$nodes_json) {
		LOG->crit("Can't read JSON : ${nodes_path}");
		return;
	}
	if (ref($nodes_json) eq "ARRAY") { 
		for my $node(@$nodes_json) {
			if ($self->view_file eq 'VM') {
				my $infos = $self->get_vm_info($node);
				print join(",", 'VM', $self->tenant,$node, @{$infos}) . "\n";
			}
		}
	} else {
		LOG->crit("JSON data isn't array : ${nodes_path}");
		return;
	}
	return 1;
}
1;
