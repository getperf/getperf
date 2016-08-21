package Getperf::Command::Site::Windows::Io;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use base qw(Getperf::Command::Site::Windows::WinPerf);
use Getperf::Command::Master::Windows;

sub new {bless{},+shift}

sub check_instance {
	my ($self, $object, $instance) = @_;
	my $label = 'Etc';
	
	if ($object =~ /PhysicalDisk|LogicalDisk/) {
		if ($instance eq '_Total') {
			$label = 'Total';			# トータルは集計から除外する
		} elsif ($instance =~ /(\w):/) {
			$label = "$1";
		}
	# ネットワーク関連インスタンス
	} elsif ($object =~ /Network Interface/) {
		$label = 'Total';
	}
	return $label;
}

sub parse {
    my ($self, $data_info) = @_;

	$data_info->step(30);

	my %headers = (
		Network => [
			'Network Interface\Bytes Received/sec', 'BytesRecivedSec',
			'Network Interface\Bytes Sent/sec',     'BytesSentSec',
		],
		PhysicalDisk => [
			'PhysicalDisk\Disk Reads/sec',       'DiskReadsSec',
			'PhysicalDisk\Disk Read Bytes/sec',  'DiskReadBytesSec',
			'PhysicalDisk\Disk Writes/sec',      'DiskWritesSec',
			'PhysicalDisk\Disk Write Bytes/sec', 'DiskWriteBytesSec',
			'PhysicalDisk\% Idle Time',          'DiskIdleTime',
		],
		LogicalDisk => [
			'LogicalDisk\Free Megabytes',  'FreeMegabytes',
			'LogicalDisk\% Free Space',    'PercentFree',
		],
	);

	return $self->parse_counter($data_info, \%headers);
}

1;
