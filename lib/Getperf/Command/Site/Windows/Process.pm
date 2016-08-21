package Getperf::Command::Site::Windows::Process;
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
	return alias_process($object, $instance);
}

sub parse {
    my ($self, $data_info) = @_;

	$data_info->step(30);

	my %headers = (
		Process => [
			'Process\% Processor Time', 'ProcessorTime',
			'Process\Handle Count',     'HandleCount',
			'Process\Working Set' ,     'WorkingSet',
			'Process\Thread Count' ,    'ThreadCount',
		],
	);

	return $self->parse_counter($data_info, \%headers);
}

1;
