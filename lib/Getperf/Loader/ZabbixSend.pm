use strict;
use warnings;
package Getperf::Loader::ZabbixSend;
use strict;
use warnings;
use Cwd;
use Path::Class;
use Data::Dumper;
use Log::Handler app => "LOG";
use Time::Piece;
use File::Path::Tiny;
use Getperf::Config 'config';
use base qw(Getperf::Container);

our $VERSION = '0.01';

sub new {
	my ($class, $data_info) = @_;

	my $zabbix_config = config('zabbix');
	my $host = $zabbix_config->{ZABBIX_SERVER_IP} || '127.0.0.1';
	my $port = $zabbix_config->{ZABBIX_SERVER_PORT} || 10051;

	my $self = bless {
		chunk_size   => $ENV{ZABBIX_SENDER_CHUNK_SIZE} || 100,
		staging_size => $ENV{ZABBIX_SENDER_STAGING_SIZE} || 100000,
		site_info    => undef,
		tmpfs        => undef,
		storage      => undef,
		command      => undef,
		row          => 0,
	}, $class;

	if (!defined($data_info->{site_info})) {
		LOG->crit("[ZabbixSender] Not found site_info object");
		return;
	}
	if (!-x '/usr/bin/zabbix_sender') {
		LOG->crit("[ZabbixSender] Not found '/usr/bin/zabbix_sender'");
		return;
	}
	$self->{tmpfs}   = $data_info->{site_info}->{tmpfs};
	$self->{storage} = $data_info->{site_info}->{storage};
	# zabbix_sender -vv -z 192.168.10.1 -p 10051 -T -i /tmp/sender_data.txt
	$self->{command} = "zabbix_sender -z ${host} -p ${port} -T -i";

	return $self;
}

sub load_chunk_data {
	my ($self, $buff, $error_count) = @_;

	my $tmpfs = $self->{tmpfs};
	my $load_path = file($tmpfs, "zabbix_send_data_$$.txt");
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

	my $load_path = file($self->{tmpfs}, "zabbix_send_data_$$.txt");
	if (!-f $load_path) {
		return 1;
	}
	my $command = $self->{command} . ' ' . $load_path;
	my $result = readpipe("$command 2>&1");
	if ($? == 256) {
		LOG->crit("[ZabbixSender] $result");
	} elsif ($? == 512) {
		LOG->warn("[ZabbixSender] $result");
	} else {
		LOG->info("[ZabbixSender] $result");
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

	# my $rrdfile    = $self->{rrd_path};
	my $chunk_size = $self->{chunk_size};
	while (my $line = $reader->getline ) {
		next if ($row++ < 0 || $line =~/^\s*$/);
		$buffer .= $line;
		if ($row % $chunk_size == 0) {
			$self->load_chunk_data($buffer, \%error_count);
			$buffer = '';
		}
	}
	$reader->close;
	if ($buffer ne '') {
		$self->load_chunk_data($buffer, \%error_count);
	}

	$self->{row} += $row;

	return 1;		# rrdtool returns 0 always
}

1;
