package Getperf::Command::Site::Windows::Common;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use base qw(Getperf::Command::Site::Windows::WinPerf);

sub new {bless{},+shift}

sub check_instance {
	my ($self, $object, $instance) = @_;
	my $label = '';
	
	# 共通インスタンス
	if ($instance eq '') {
		$label = '';
	} elsif ($object eq 'Processor') {
		if ($instance eq '_Total') {
			$label = 'Total';
		# プロセッサID毎の利用率をとりたい場合は以下コメントアウトを外す
		} elsif ($instance =~ /(\d+)/) {
			$label = $1;
		}
	} else {
		$label = 'Etc';
	}
	return $label;
}

sub parse {
    my ($self, $data_info) = @_;

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
