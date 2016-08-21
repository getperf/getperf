package Getperf::Command::Base::Windows::Process;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use base qw(Getperf::Command::Base::Windows::WinPerf);

sub new {bless{},+shift}

sub check_instance {
	my ($self, $object, $instance) = @_;
	my $label = 'Etc';
	
	# 共通インスタンス
	if ($object eq 'Process') {
		if ($instance eq '_Total') {
			$label = '';			# トータルは集計から除外する
		} elsif ($instance =~ /(System)/) {
			$label = "System";
		} elsif ($instance =~ /(tom\w+)/) {
			$label = "$1";
		} elsif ($instance =~ /(apache|Apache)/) {
			$label = "Apache";
		} elsif ($instance =~ /Idle/) {
			$label = "Idle";
		}
	}
	return $label;
}

sub parse {
    my ($self, $data_info) = @_;

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
