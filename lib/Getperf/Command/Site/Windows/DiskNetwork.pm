package Getperf::Command::Site::Windows::DiskNetwork;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use String::CamelCase qw(camelize);
use base qw(Getperf::Container);
use base qw(Getperf::Command::Site::Windows::WinPerf);
use Getperf::Command::Master::Windows;

sub new {bless{},+shift}

sub check_instance {
	my ($self, $object, $instance) = @_;
	return alias_disk_network($object, $instance);
}

sub parse {
    my ($self, $data_info) = @_;

	$data_info->step(30);

	my %headers = (
		Network => [
			'Network Interface\Bytes Received/sec',         'BytesRecivedSec',
			'Network Interface\Bytes Sent/sec',             'BytesSentSec',
			'Network Interface\Bytes Total/sec',            'BytesTotalSec',
			'Network Interface\Packets Received/sec',       'PacketsRecivedSec',
			'Network Interface\Packets Sent/sec',           'PacketsSentSec',
			'Network Interface\Output Queue Length',	    'QueueLength',
			'Network Interface\Packets Received Discarded',	'RecievedDiscarded',
			'Network Interface\Packets Received Errors',	'RecievedErrors',
			'Network Interface\Packets Outbound Discarded',	'OutboundDiscarded',
			'Network Interface\Packets Outbound Errors',	'OutboundErrors',
		],
		PhysicalDisk => [
			'PhysicalDisk\Disk Reads/sec',          'DiskReadsSec',
			'PhysicalDisk\Disk Read Bytes/sec',     'DiskReadBytesSec',
			'PhysicalDisk\Disk Writes/sec',         'DiskWritesSec',
			'PhysicalDisk\Disk Write Bytes/sec',    'DiskWriteBytesSec',
			'PhysicalDisk\Avg. Disk sec/Read',	    'DiskReadElapse',
			'PhysicalDisk\Avg. Disk sec/Write',	    'DiskWriteElapse',
			'PhysicalDisk\Avg. Disk Queue Length',	'QueueLength',
			'PhysicalDisk\% Idle Time',             'DiskIdleTime',
		],
		LogicalDisk => [
			'LogicalDisk\Free Megabytes',  'FreeMegabytes',
			'LogicalDisk\% Free Space',    'PercentFree',
		],
	);

	return $self->parse_counter($data_info, \%headers);
}

1;
