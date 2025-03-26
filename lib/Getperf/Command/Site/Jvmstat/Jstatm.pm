package Getperf::Command::Site::Jvmstat::Jstatm;
use strict;
use warnings;
use Data::Dumper;
use Path::Class;
use YAML::Tiny;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Jvmstat;
use Getperf::Container qw/sumup/;

sub new {
	bless{},+shift
}

sub read_java_vm_list {
    my ($self, $data_info) = @_;

    my $input_dir = $data_info->input_dir;
	my %jvms = ();
    for my $jvms_file(qw/java_vm_list.yaml jvm.txt/) {
		my $jvms_path = file($input_dir, $jvms_file);
		# print $jvms_path . "\n";
		next if (! -f $jvms_path);
		my ($pid, $args);
		my @jvms_lines = $jvms_path->slurp;
		# print Dumper \@jvms_lines;
		for my $line(@jvms_lines) {
		# print "LN:${line}\n";
			if ($line=~/pid: (\d+)/) {
				$pid = $1;
		# print "PID:${pid}\n";
			}
			if ($line=~/hotspot\.vm\.args: (.+)$/ ||
				$line=~/java\.rt\.vmArgs: (.+)$/) {
				my $java_info = $1;
		# print "JAVA_INFO:${java_info}\n";
			    if (my $info = alias_instance($java_info)) {
			    	
				    $jvms{$pid} = $info;
			    }
			}
		}
    }
    # print Dumper \%jvms;
	return \%jvms;
}

# Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD
# 2015/07/20 18:34:18 23972  16717688     32768   4743720      4      0     24053         0      4
# 2015/07/20 18:34:18 3796   38117464  57706352  24301064     43      0    783207         0     19
# 2015/07/20 18:34:18 3745   51740896  53195592  21763680     30      0    543732         0     10

sub parse {
    my ($self, $data_info) = @_;
print "TEST\n";
	my %results;
	my $step = 60;
	my @headers = qw/eu ou pu ygc:COUNTER fgc:COUNTER ygct:COUNTER fgct:COUNTER thread/;

	my $jvms = $self->read_java_vm_list($data_info);
	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/^Date/) {
			$sec += $step;
			next;
		}
		if ($line=~/^\d/) {
			my ($dt, $tm, $pid, @csvs) = split(' ', $line);
			my $n_csvs = scalar(@csvs);
			push(@csvs, 0) if ($n_csvs == 7); # Add Thread for Java1.4
			$results{$pid}{$sec} = join(' ', @csvs);
		}
	}
	close(IN);

	for my $pid(keys %results) {
		if (defined(my $instance = $jvms->{$pid})) {
			my $device = $instance->{device};
			my $text = $instance->{device_text};
			next if ($device eq 'Etc');
			$data_info->regist_device($host, 'Jvmstat', 'jstat', $device, $text, \@headers);
			$data_info->simple_report("device/jstat__${device}.txt", $results{$pid}, \@headers);
		}
	}
	return 1;
}

1;
