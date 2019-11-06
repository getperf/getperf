package Getperf::Command::Master::Windows;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_node_path alias_processor_memory alias_disk_network alias_process/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_node_path {
    my ($host) = @_;

    # return "/$fab/$app/$host";
    return "/$host";
}

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
	if ($object =~ /PhysicalDisk/) {
		if ($instance eq '_Total') {
			$label = 'Total';			# トータルは集計から除外する
		} elsif ($instance =~ /(\d+)\s(\w):/) {
			my ($seq, $disk) = ($1, $2);
			if (($disk eq 'C' and $seq == 0) or ($disk eq 'D' and $seq == 1)) {
				$label = $disk;
			} else {
				$label = "${disk}-${seq}"
			}
			# print "($seq, $disk):$label\n";
		}
	} elsif ($object =~ /LogicalDisk/) {
		if ($instance eq '_Total') {
			$label = 'Total';			# トータルは集計から除外する
		} elsif ($instance =~ /(\w):/) {
			$label = $1;
		}
		# print "LDISK:$instance:$label\n";
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
			$label = 'Etc';			# トータルは集計から除外する
		} elsif ($instance =~ /(System)/) {
			$label = "System";
		} elsif ($instance =~ /(tom\w+)/) {
			$label = "$1";
		} elsif ($instance =~ /(Tomcat_\w+)/) {
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
