package Getperf::Command::Site::Windows::Common;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use base qw(Getperf::Command::Site::Windows::WinPerf);
use Getperf::Command::Master::Windows;

sub new {bless{},+shift}

my $db = $Getperf::Command::Master::Windows::db;

sub check_instance {
	my ($self, $object, $instance) = @_;
	return alias_processor_memory($object, $instance);
}

sub parse {
    my ($self, $data_info) = @_;

	$data_info->step(5);
	my $host = $data_info->host;
	if (!defined($db->{_node_dir}{$host})) {
		$data_info->regist_node_dir( $host, $db );
	}

	my %headers = (
		Processor => [
			'Processor\% User Time'      , 'UserTime',
			'Processor\% Privileged Time', 'PrivilegedTime',
			'Processor\% Interrupt Time' , 'InterruptTime',
			'Processor\% Idle Time'      , 'IdleTime',
		],
		Memory => [
			'Memory\Available Bytes' , 'AvailableBytes',
			'Memory\Committed Bytes' , 'CommittedBytes',
			'Memory\Page Faults/sec' , 'PageFaults',
			'Memory\Pages/sec'       , 'Pages',
		],
	);

	return $self->parse_counter($data_info, \%headers);
}

1;
