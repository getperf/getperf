use strict;
use warnings;
package Getperf::Loader::RRD;
use Data::Dumper;
use Path::Class;
use Log::Handler app => "LOG";
use Time::Piece;
use Symbol qw(gensym);
use IPC::Open3 qw(open3);
use parent qw(Class::Accessor::Fast);
use File::Path::Tiny;
use Getperf::Config 'config';

__PACKAGE__->mk_accessors(qw/rrdtool path step headers summary_file load_data row errors/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my $self = bless {
		rrdtool      => $ENV{RRDTOOL_PATH} || 'rrdtool',
		chunk_size   => $ENV{RRDTOOL_CHUNK_SIZE} || 500,
		staging_size => $ENV{RRDTOOL_STAGING_SIZE} || 100000,
		site_info    => undef,
		tmpfs        => undef,
		storage      => undef,
		domain       => undef,
		status       => undef,
		@_,
	}, $class;
	if (!$self->{tmpfs} && defined($self->{site_info})) {
		$self->{tmpfs}   = $self->{site_info}->{tmpfs};
		$self->{storage} = $self->{site_info}->{storage};
	}
	return $self;
}

sub get_create_command {
	my $self = shift;

	my $path = $self->path;
	my $step = $self->step;
	my $start = localtime(Time::Piece->strptime('2014-09-01', '%Y-%m-%d'))->epoch;
	my $config = config('rrd');
	my $rra_configs = $config->{rra} || [
		{label => 'Daily',		step => 120,	save_days => 1,		},
		{label => 'Weekly',		step => 900,	save_days => 8,		},
		{label => 'Monthly',	step => 3600,	save_days => 31,	},
		{label => 'Yearly',		step => 86400,	save_days => 730,	},
	];
	my @cmds = ();
	push @cmds, $self->rrdtool . " create \\\n" 
		. "\t$path \\\n"
		. "\t--step  $step \\\n"
		. "\t--start $start \\\n";

	# DS:ds-name:GAUGE | COUNTER | DERIVE | ABSOLUTE:heartbeat:min:max
	my $count_item = 0;
	for my $header(@{$self->headers}) {
		# change rrdtool datasource alias. eg) consumed.userworlds|consumedUserworlds
		if ($header=~/\|(.*)?/) {
			$header = $1;
		}
		my @items = split(/:/, $header);
		my $name = shift(@items);
		my $type = shift(@items) || 'GAUGE';
		# heatbeatが小さいとあまり変化がないデータは欠損値として扱われるため、できるだけ大き目な値が望ましい
		my $heatbeat = shift(@items) || 100 * $step;	
		my $minimum  = shift(@items) || '0';
		my $maximum  = shift(@items) || 'U';

		if (length($name) > 19) {
			LOG->crit("DS name overflow : $name");
			return;
		}
		if ($name!~/^\w[\w|\d]*$/) {
			LOG->crit("Invalid DS name : $name");
			return;
		}
		push @cmds, sprintf( "\tDS:%s:%s:%d:%s:%s \\\n", $name, $type, $heatbeat, $minimum, $maximum);
		$count_item ++;
	}

	# RRA:AVERAGE | MIN | MAX | LAST:xff:steps:rows
	my $count_rows = 0;
	for my $rra_config(@{$rra_configs}) {
		my $rra_step      = $rra_config->{step};
		my $rra_save_days = $rra_config->{save_days};
		my $rows = int( $rra_save_days * 24 * 3600 / $rra_step );
		my $steps = ($step > $rra_step) ? 1 : int ($rra_step / $step);

		push @cmds, "\tRRA:AVERAGE:0.5:$steps:$rows \\\n";
		push @cmds, "\tRRA:MAX:0.5:$steps:$rows \\\n";
		$count_rows += $rows;
	}

	# return {
	# 	estimate_size => $count_item * $count_rows * 2 * 8,
	# 	cmd => join('', @cmds),
	# };
	return join('', @cmds);
}

sub create {
	my $self = shift;

	my $path = $self->path;
	my $step = $self->step;

	my $output_dir = file($path)->dir;
	if (!File::Path::Tiny::mk($output_dir)) {
        LOG->crit("Could not make path '$output_dir': $!");
        return;
	}

	my $command = $self->get_create_command;
	if (!$command) {
		return;
	}
	# rrdtool outputs an error to stdout, So you do not use the stderr 
	my $result = readpipe("$command 2>&1");
	if ($result=~/ERROR/) {
		LOG->crit($result);
		LOG->crit($command);
		return;
	}
	return 1;
}

sub load_chunk_data {
	my ($self, $buff, $error_count) = @_;

	my $tmpfs = $self->{tmpfs};
	my $load_path = file($tmpfs, "load_data_$$.txt");
	my $writer = $load_path->open('a');
	if (!$writer) {
		if (! -d $load_path->parent) {
			$load_path->parent->mkpath;
			$writer = $load_path->open('a') || die "$! : $load_path";
		} else {
			die "$! : $load_path";
		}
	}
  	$writer->print($buff);
	$writer->close;

	my $rc = 0;
	my $size = (stat $load_path)[7];
	if ( $size > $self->{staging_size} ) {
		$rc = $self->flush_data();
	}
	return ($rc == 0) ? 1 : 0;
}

sub flush_data {
	my ($self) = @_;

	my $tmpfs   = $self->{tmpfs};
	my $storage = $self->{storage};
	my $load_path = file($tmpfs, "load_data_$$.txt");
	if (! -f $load_path) {
		return 1;
	}
	my $rc = 0;
	my $rrdtool  = $self->{rrdtool};
	my $cmd = "cd ${storage}; cat ${load_path} | ${rrdtool} - |";
	LOG->debug($cmd);
	open( my $in, $cmd ) or die "$! : $cmd";
	my $row = 0;
	my %e = ();
    while ( my $line = <$in> ) {
		if ($line=~/ERROR/) {
			if ($line=~/illegal attempt to update using time/) {
				$e{illegal_time} ++;
			} elsif ($line=~/expected/) {
				$e{unexpected_format} ++;
				LOG->warning($line);
			} else {
				$e{other_error} ++;
				LOG->warning($line);
			}
		} 
    	$row ++;
    }
    close $in;
    $rc = $?;
	unlink($load_path);

	LOG->info(sprintf("[RRDFlush] load row=%d, error=(%d/%d/%d)", $row, 
		$e{illegal_time} || 0, $e{unexpected_format} || 0, $e{other_error} || 0
		));

	return ($rc == 0) ? 1 : 0;
}

sub load_data {
	my ($self, $load_path) = @_;

	my %error_count = ();
	my $reader = file($load_path)->openr;
	if (!$reader) {
		LOG->crit("Can't read $load_path: $!");
		return;
	}
	my $rrdfile    = $self->{rrd_path};
	my $chunk_size = $self->{chunk_size};
	my $row        = 0;
	my $buffer     = '';
	while (my $line = $reader->getline ) {
		next if ($row++ < 1 || $line =~/^\s*$/);
		my ($tm, @csvs) = split(/\s+/, $line);
		# my $local_time = localtime(Time::Piece->strptime($tm, '%Y-%m-%dT%H:%M:%S'))->epoch;
#		$tm .= 'Z';		# Format YYYY-MM-DDThh:mm:ss
		my $body = join(":", $tm, @csvs);
		$buffer .= 'update ' . $rrdfile . ' ' . $body . "\n";

		if ($row % $chunk_size == 0) {
			$self->load_chunk_data($buffer, \%error_count);
			$buffer = '';
		}
	}
	$reader->close;
	if ($buffer ne '') {
		$self->load_chunk_data($buffer, \%error_count);
	}
	# rrdtool outputs an error to stdout, So you do not use the stderr 
	
	$row -- if ($row > 0);
	LOG->debug(sprintf("update rrd row=%d, error=(%d/%d/%d), file=%s", $row, $error_count{illegal_time} || 0, $error_count{unexpected_format} || 0, $error_count{other_error} || 0, $load_path));
	$self->errors(\%error_count);
	$self->row($row);

	return 1;		# rrdtool returns 0 always
}

sub debug {
	my $self = shift;
	print "path : " . $self->{path} . "\n";
	print "step : " . $self->{step} . "\n";
	print "head : " . join(',', @{$self->{headers}}) . "\n\n";
}
1;
