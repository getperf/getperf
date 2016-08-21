use strict;
use warnings;
package Getperf::RRDtool;
use Getopt::Long;
use Path::Class;
use Time::Piece;
use Data::Dumper;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Loader::RRD;
use parent qw(Class::Accessor::Fast);
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/server url enable/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	config('base')->add_screen_log;

	bless {
		rrdtool      => $ENV{RRDTOOL_PATH} || 'rrdtool',
		command      => undef,
		rra_interval => 30,
		rra_days     => 8,
		rrd_clone    => undef,
		rrd_start    => localtime(Time::Piece->strptime('2014-09-01', '%Y-%m-%d'))->epoch,
		@_,
	}, $class;
}

sub parse_command_option {
	my ($self, $args) = @_;

	Getopt::Long::Configure("pass_through");
	my $usage = "Usage : rrd-cli\n" .
        "\t[--add-rra|--remove-rra] {rrd_paths} [--interval i] [--days i]\n" .
        "\t--create {rrd_path} --from {rrd_path}\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	my %config = ();
	my $node_list_tsv = undef;
	my $opts = GetOptions (
		'--add-rra'    => \$self->{command}{add_rra},
		'--remove-rra' => \$self->{command}{remove_rra},
		'--interval=i' => \$self->{rra_interval},
		'--days=i'     => \$self->{rra_days},

		'--create=s'   => \$self->{rrd_clone}{to},
		'--from=s'     => \$self->{rrd_clone}{from},
	);

	my $rrd_clone = $self->{rrd_clone};
	if ($rrd_clone->{to}) {
		if ($rrd_clone->{from}) {
			return $self->clone_rrd($rrd_clone->{from}, $rrd_clone->{to});
		} else {
			die "\t[--from=s] Required.\n\n" . $usage;
		}
	}

	my $command = $self->{command};
	if (!$command->{add_rra} && !$command->{remove_rra}) {
		die "\t[--add-rra|--remove-rra] Required.\n\n" . $usage;
	}

	eval {
		for my $rrd_path (@ARGV) {
			if (-d $rrd_path) {
				dir($rrd_path)->recurse(callback => sub {
					my $rrd_file = shift;
					$self->rra_admin($rrd_file);
				});
			} elsif (-f $rrd_path) {
				$self->rra_admin($rrd_path);
			}
		}
	};
	if ($@) {
		LOG->error($@);
		die "RRA admin failed\n";
	}

	return 1;
}

sub clone_rrd {
	my ($self, $from, $to) = @_;

	if (!-f $from || $from!~/\.rrd/) {
		LOG->error("Invalid rrd datasource : $from");
		return;
	}
	if (-f $to) {
		LOG->error("Already exists : $to");
		return;
	}

	# read rrdtool info command
	my $rrdtool = $self->{rrdtool};
	my @info_buffers = `${rrdtool} info ${from}`;
	if ($? != 0) {
		LOG->error("${rrdtool} info $from : $!");
		return;
	}
	my ($step, %ds, %rra);
	my $ds_cnt = 0;
	for my $info(@info_buffers) {
		chomp($info);
		if ($info=~/^step = (\d+)$/) {
			$step = $1;
		} elsif ($info=~/^ds\[(.+?)\]\.(.+?) = (.+?)$/) {
			my ($dsname, $prop, $value) = ($1, $2, $3);
			$ds{$1}{cnt} = defined($ds{$dsname}) ? $ds_cnt : $ds_cnt ++;
			$value = 'U' if ($value eq 'NaN');
			$value =~s/\"//g;
			$ds{$dsname}{$prop} = $value;
		} elsif ($info=~/^rra\[(\d+?)\]\.(.+?) = (.+?)$/) {
			$rra{$1}{$2} = $3;
		}
	}

	# parse header
	my $base_dir = file($to)->parent;
	if (!-d $base_dir) {
		$base_dir->mkpath() || die "$!";
	}
	my $cmd = "${rrdtool} create ${to} "; 
	$cmd   .= "--start $self->{rrd_start} ";
	$cmd   .= "--step ${step}s \\\n";

	# parse data source. eg) 'DS:cpu:GAUGE:500:0.0:'
	for my $datasource(sort {$ds{$a}{cnt} <=> $ds{$b}{cnt}} keys %ds) {
		my $prop = $ds{$datasource};
		my $type = $prop->{type};
		my $hb   = $prop->{minimal_heartbeat};
		my $min  = ($prop->{min} eq 'U') ? 'U' : $prop->{min} * 1.0;
		my $max  = ($prop->{max} eq 'U') ? 'U' : $prop->{max} * 1.0;
		$cmd .= "\tDS:${datasource}:${type}:${hb}:${min}:${max} \\\n";
	}

	# parse rra. eg) 'RRA:AVERAGE:0.5:6:5670'
	for my $rra_id(sort keys %rra) {
		my $prop     = $rra{$rra_id};
		my $cf       = $prop->{cf};
		my $xff      = $prop->{xff} * 1.0;
		my $pdp_rows = $prop->{pdp_per_row};
		my $rows     = $prop->{rows};
		$cmd .= "\tRRA:${cf}:${xff}:${pdp_rows}:${rows} \\\n";
	}
	$cmd =~s/\\$//g;

	print $cmd . "\n";
	if (system($cmd) != 0) {
		die "rrdtool create command error : $!";
	}
	return 1;
}

sub rra_admin {
	my ($self, $rrd_path) = @_;
	print "[rra_admin] $rrd_path\n";

	# read rrdtool info command, fetch step
	my $step = 0;
	my $rrdtool = $self->{rrdtool};
	my @info_buffers = `${rrdtool} info ${rrd_path}`;
	if ($? != 0) {
		LOG->error("${rrdtool} info ${rrd_path} : $!");
		return;
	}
	my %rra;
	map { 
		$step = $1 if ($_=~/^step = (\d+)/);
		$rra{$1}{$2} = $3 if ($_=~/^rra\[(\d+?)\]\.(.+?) = (.+?)$/);
	} @info_buffers;

	# calucrate pdp_per_row = $interval / $step
	if (!$step) {
		LOG->error("Unkown step : $rrd_path");
		return;
	}
	my $pdp_per_row = int($self->{rra_interval} / $step);
	if ($pdp_per_row == 0) {
		LOG->error("rra interval(--interval) must be larger than step : $step");
		return;
	}
	my $rows = int ($self->{rra_days} * 24 * 3600 / $self->{rra_interval});

	my $cmd = "${rrdtool} tune ${rrd_path} \\\n";
	if ($self->{command}{add_rra}) {
		# check rra exists
		for my $rra_id(sort keys %rra) {
			my $prop     = $rra{$rra_id};
			if ($pdp_per_row == $prop->{pdp_per_row}) {
				LOG->error("Aleady exists [step=$step, pdp_per_row=$pdp_per_row] : $rrd_path");
				return;
			}
		}
		$cmd .= "\tRRA:AVERAGE:0.5:${pdp_per_row}:${rows} \\\n";
		if ($pdp_per_row > 1) {
			$cmd .= "\tRRA:MAX:0.5:${pdp_per_row}:${rows} \\\n";
		}

	} elsif ($self->{command}{remove_rra}) {
		for my $rra_id(sort keys %rra) {
			my $prop     = $rra{$rra_id};
			if ($pdp_per_row == $prop->{pdp_per_row}) {
				$cmd .= "\tDELRRA:${rra_id} \\\n";
			}
		}

	} else {
		LOG->error("Unkown command : $rrd_path");
		return;
	}
	$cmd =~s/\\$//g;
	print $cmd . "\n";
	if (system($cmd) != 0) {
		die "rrdtool create command error : $!";
	}

	return 1;
}

1;
