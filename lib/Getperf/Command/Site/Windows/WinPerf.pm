package Getperf::Command::Site::Windows::WinPerf;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;

# sub parse {
#     my ($self, $data_info) = @_;
# 	my %headers = (
# 		Processor => [
# 			'Processor\% User Time'      , 'UserTime',
# 			'Processor\% Privileged Time', 'PrivilegedTime',
# 			'Processor\% Interrupt Time' , 'InterruptTime',
# 			'Processor\% Idle Time'      , 'IdleTime',
# 		],
# 		Memory => [
# 			'Memory\Available Bytes' , 'AvailableBytes',
# 			'Memory\Committed Bytes' , 'CommittedBytes',
# 			'Memory\Page Faults/sec' , 'PageFaults',
# 			'Memory\Pages/sec'       , 'Pages',
# 		],
# 	);
# 	return $self->parse_counter($data_info, \%headers);
# }

sub new {bless{},+shift}

sub reform_headers {
	my ($self, $headers) = @_;

	my %header_keywords;
	my %output_headers;
	for my $output (keys %$headers) {
		my @items = @{$headers->{$output}};
		my $index = 1;
		while(@items) {
			my $keyword = shift(@items);
			my $column  = shift(@items);

			$header_keywords{$keyword} = { 
				output => $output,
				index  => $index, 
				column => $column,
			};
			$index ++;

			push(@{$output_headers{$output}}, $column);
		}
	}
	return { keyword => \%header_keywords, output => \%output_headers };
}

sub parse_counter {
    my ($self, $data_info, $headers) = @_;

	my %results;
	my $step = 5;
	my (@nodes, %nodes_key);
	my $row = 0;

	my $reform_headers  = $self->reform_headers($headers);
	my $header_keywords = $reform_headers->{keyword};
	my $output_headers  = $reform_headers->{output};
	my %column_indexes;

	my $host = lc($data_info->host);
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {

		my $tmp = $line;
		$tmp =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
		my @vals = map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_}
			($tmp =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g);	#"

		my $left = shift(@vals);
		# ヘッダ部 :  "(PDH-CSV 4.0) ()(-540)"
		if ($left =~ /CSV/) {
			my $index = 0;
			for my $key(@vals) {
				# Extract GALILEO from '\\GALILEO\Processor(_Total)\% Processor Time'
				if ($key=~/^\\\\(.+?)(\\.*)$/) {
					$key = $2;
				}
				my (undef, $object, $counter) = split(/\\+/, $key);
				
				# Extract _Total from 'Processor(_Total)'
				my $instance = '';
				if ($object=~/^(.+)\((.+?)\)$/) {
					($object, $instance) = ($1, $2);
				}

				# Check Header, Index keyword filter 'object\counter'
				my $keyword = $object . "\\" . $counter;
				if (defined(my $header_keyword = $header_keywords->{$keyword})) {
					$column_indexes{$index} = $header_keyword;
					my $label = $self->check_instance($object, $instance);
					$column_indexes{$index} = {
						instance => $label, 
						output   => $header_keyword->{output},
						column   => $header_keyword->{column},
					};
				}
				$index ++;
			}
		# データ部 : "11/01/2007 01:35:30.437"
		# 1行目は不定データが多いので集計しない
		} elsif ($left=~/^(\d+)\/(\d+)\/(\d+) (\d+:\d+:\d+)\.(\d+)$/ && $row > 1) {
			my ($MM, $DD, $YY, $time, $msec) = ($1, $2, $3, $4, $5);
			my $date = sprintf("%04d-%02d-%02d", $YY, $MM, $DD);
			my $tms = $date . ' ' . $time; 
			my $sec = localtime(Time::Piece->strptime($tms, '%Y-%m-%d %H:%M:%S'))->epoch;

			my $index = 0;
			for my $value(@vals) {
				if (defined(my $column_info = $column_indexes{$index})) {
					my $instance = $column_info->{instance};
					my $output   = $column_info->{output};
					my $column   = $column_info->{column};
					my $output_header = $output_headers->{$output};
					my $output_file;
					if ($instance eq '' or $instance eq 'Total') {
						$output = $output . $instance;
						$data_info->regist_metric($host, 'Windows', $output, $output_header);
						$output_file = "${output}.txt";
					} else {
						$data_info->regist_device($host, 'Windows', $output, $instance, undef, $output_header);
						$output_file = "device/${output}__${instance}.txt";
					}			
					$value = 0 if ($value=~/^\s+$/);
					$results{$output_file}{headers} = $output_header;
					$results{$output_file}{out}{$sec}{$column} += $value;
				}
				$index ++;
			}
		}
		$row ++;
	}
	close(IN);
	for my $output_file(keys %results) {
		my $headers  = $results{$output_file}{headers};
		$data_info->pivot_report($output_file, $results{$output_file}{out}, $headers);
	}
	return 1;
}

1;
