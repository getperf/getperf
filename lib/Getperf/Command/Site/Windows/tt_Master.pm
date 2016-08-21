package Getperf::Command::Master::Windows;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_processor_memory alias_disk_network alias_process/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_processor_memory {
	my ($object, $instance) = @_;
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

sub alias_disk_network {
	my ($object, $instance) = @_;

	my $label = 'Etc';
	if ($object =~ /PhysicalDisk|LogicalDisk/) {
		if ($instance eq '_Total') {
			$label = 'Total';			# トータルは集計から除外する
		} elsif ($instance =~ /(\w):/) {
			$label = "$1";
		}
	# ネットワーク関連インスタンス
	} elsif ($object =~ /Network Interface/) {
		$instance =~ s/(?:^|_|-| )(.)/\U$1/g;
    	$instance =~ s/\.{.*}//g;	# Isatap
		$label = $instance;
	}
	return $label;
}

sub alias_process {
	my ($object, $instance) = @_;

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

1;
