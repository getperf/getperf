use strict;
use warnings;
package Getperf::Loader::Influx;
use strict;
use warnings;
use Cwd;
use Path::Class;
use Data::Dumper;
use Log::Handler app => "LOG";
use Time::Piece;
use File::Path::Tiny;
use Getperf::Config 'config';

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my $influx_config = config('influx');
	my $host = $influx_config->{INFLUX_HOST};
	my $port = $influx_config->{INFLUX_PORT};
	my $db   = $influx_config->{INFLUX_DATABASE} || 'influx';

	my $self = bless {
		chunk_size   => $ENV{RRDTOOL_CHUNK_SIZE} || 500,
		staging_size => $ENV{RRDTOOL_STAGING_SIZE} || 100000,
		site_info    => undef,
		tmpfs        => undef,
		storage      => undef,
		url          => undef,
		row          => 0,
		@_,
	}, $class;

	if (!defined($self->{site_info})) {
		LOG->crit("[Influx] Not found site_info object");
		return;
	}
	$self->{tmpfs}   = $self->{site_info}->{tmpfs};
	$self->{storage} = $self->{site_info}->{storage};
	$db = $self->{site_info}->{sitekey};
	$self->{url} = "http://${host}:${port}/write?db=${db}";

	return $self;
}

sub load_chunk_data {
	my ($self, $buff, $error_count) = @_;

	my $tmpfs = $self->{tmpfs};
	my $load_path = file($tmpfs, "influx_data_$$.txt");
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

	my $load_path = file($self->{tmpfs}, "influx_data_$$.txt");
	if (!-f $load_path) {
		return 1;
	}
	# curl -i -XPOST 'http://localhost:8086/write?db=db' --data-binary @influx_data_$$.txt
	my $command = "curl --noproxy '*' -X POST '$self->{url}' --data-binary \@$load_path";
	my $result = readpipe("$command 2>&1");
	LOG->debug($command);
	if (lc($result)=~/(error|usage|failed|warn)/) {
		LOG->crit($result);
	} else {
		LOG->info("[InfluxDB] Flush data");
	}
	unlink($load_path);
	$self->{row} = 0;

	return 1;
}

sub load_data {
	my ($self, $load_path) = @_;

	my %error_count = ();
	my $reader = file($load_path)->openr;
	if (!$reader) {
		LOG->crit("Can't read $load_path: $!");
		return;
	}

	my $buffer     = '';
	my $row        = 0;
	my $key = $self->{metric};
	$key    =~s|/|_|g;
	$key   .= ',domain=' . $self->{domain};
	$key   .= ',node='   . $self->{node};
	$key   .= ',device=' . $self->{device} if ($self->{device});

	# my $rrdfile    = $self->{rrd_path};
	my $chunk_size = $self->{chunk_size};
	while (my $line = $reader->getline ) {
		next if ($row++ < 1 || $line =~/^\s*$/);
		my ($tm, @csvs) = split(/\s+/, $line);
		my @values = ();
		for my $item(@{$self->{headers}}) {
			my $value = shift(@csvs);
			$value = 0 if ($value eq 'NaN' || !$value);
			push(@values, $item . "=" . $value);
		}
		$buffer .= $key . ' ' . join(",", @values) . ' ' . $tm . '000000000' . "\n";
		if ($row % $chunk_size == 0) {
			$self->load_chunk_data($buffer, \%error_count);
			$buffer = '';
		}
	}
	$reader->close;
	if ($buffer ne '') {
		$self->load_chunk_data($buffer, \%error_count);
	}

	$row -- if ($row > 0);
	$self->{row} += $row;

	return 1;		# rrdtool returns 0 always
}

1;
