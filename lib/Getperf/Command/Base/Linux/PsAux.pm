package Getperf::Command::Base::Linux::PsAux;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub check_process {
	my ($user, $command) = @_;

	my $category = 'etc';
	if ($user=~/(git|psadmin|mysql|postgres)/) {
		$category = $1;
	}
	if  ($command=~/(perl|tomcat)/) {
		$category .= '_' . $1;
	}
	return $category;
}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %summary);
	my $step = 30;
	my @headers = qw/cpu mem vsz rss/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		if ($line=~/^USER /) {
			$sec += $step;	# skip header
			next;
		}
		$line=~s/(\r|\n)*//g;			# trim return code
		my @columns = split(" ", $line);
		my %values = ();
		for my $item (qw/user pid cpu mem vsz rss tty stat start time/) {
			$values{$item} = shift(@columns);
		}
		my $command = join(" ", @columns);
		my $category = check_process($values{user}, $command);
		my $output_file = "device/ps__${category}.txt";
		for my $item (qw/cpu mem vsz rss/) {
			$results{$output_file}{$sec}{$item} += $values{$item};
			$summary{$item}{"$category\t$command"} += $values{$item};
		}
		$data_info->regist_device($host, 'Linux', 'ps', $category, undef, \@headers);
	}
	close(IN);
	for my $output_file(keys %results) {
		$data_info->pivot_report($output_file, $results{$output_file}, \@headers);
	}
	for my $item (qw/cpu mem vsz rss/) {
		my %values = %{$summary{$item}};
		my $buffers = '';
		for my $key (sort {$values{$b} <=> $values{$a}} keys %values) {
			my $value = $values{$key};
			$buffers .= "$key\t$value\n";
		}
		my $output_file = "process_summary__${item}.txt";
		$data_info->standard_report($output_file, $buffers);
	}

	return 1;
}

1;
