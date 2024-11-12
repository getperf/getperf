package Getperf::Command::Site::Oracle::AwrrptRac;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Time::Local;
use base qw(Getperf::Container);
use Getperf::Command::Site::Oracle::AwrreportHeaderRac;

sub new {bless{},+shift}

our $headers = get_headers();
our $months  = get_months();

# print Dumper \%{$headers->{_time_models}};
# print Dumper $headers->{'_time_models'};
# exit;

sub trim {
    my $val = shift;
    $val =~ s/^ *(.*?) *$/$1/;
    return $val;
}

sub norm {
    my ($value) = @_;

    my $unit = '';
    if ($value=~/^(.+)([K|M|G])/) {
        $value = $1;
        $unit = $2;
    }
    if ($unit eq 'K') {
        $value *= 1000 ;
    } elsif ($unit eq 'M') {
        $value *= 1000 * 1000;
    } elsif ($unit eq 'G') {
        $value *= 1000 * 1000 * 1000;
    }

    return $value;
}

# 表形式のレコードを先頭列だけ固定長で解析して、移行は空白区切りの可変長として解析する
sub parse_lines {
    my ($self, $ref_lines, $ref_size_columns) = @_;
    my @lines = @{$ref_lines};
    my @size_columns = @{$ref_size_columns};

    my $header_len = 0;
    my @keywords = map { $header_len += $_; "a$_";} @size_columns;
    my $keyword = join('', @keywords);
    # print "LEN:$header_len,KEYWORD:$keyword\n";

    my $left_column = '';
    my @csvs;
    for my $line(@lines) {
        my @headers = unpack $keyword, $line;
        my @csv = map { trim($_) } @headers;

        if ($csv[0] eq '') {
            $csv[0] = $left_column;
        }
        $left_column = $csv[0];

        my $body = substr($line, $header_len);
        my @body_columns = split(' ', $body);
        my @body_columns2 = map { $_=~s/,//g; $_; } @body_columns;
        push(@csv, @body_columns2);

        push(@csvs, \@csv);
        # print Dumper \@csvs;
    }
    return @csvs;
}

# Parser "Time Model" 
sub parse_time_model {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'time_models'}};

    my $events;
    for my $row(@csv) {
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        $events->{$instance} = join(' ', @{$row});
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_time_models'}};
    return ($events, \@header);
}

# Parser "Foreground Wait Classes" 
sub parse_foreground_wait {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'foreground_waits'}};

    my $events;
    for my $row(@csv) {
        # print Dumper $row;
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        $events->{$instance} = join(' ', @{$row});
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_foreground_waits'}};
    return ($events, \@header);
}

# Parser "Top Timed Events" 
sub parse_timed_event {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4, 14, 44]);
    my %header_keys = %{$headers->{'events'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;
    # print Dumper \%header_keys;
    my $events;
    for my $row(@csv) {
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        my $event = $row->[1];
        my $value = $row->[4];   # Wait time
        my $header_key = $header_reverse{$event} || 'Etc';
        # print "KEY:$instance, $event, $header_key, $value\n";
        if ($header_key) {
            $events->{$instance}{$header_key} += $value;
        }
    }
    # my @header = keys %header_keys;
    return ($events, \%header_keys);
}

# Parser "Top Timed Background Events" 
sub parse_background_event {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4, 14, 38]);
    my %header_keys = %{$headers->{'bg_events'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;

    my $events;
    for my $row(@csv) {
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        my $event = $row->[1];
        my $value = $row->[4];   # Wait time
        $value =~s/,//g;        # Trim numeric ","
        my $header_key = $header_reverse{$event} || 'Etc';
        # print "KEY:$instance, $event, $header_key, $value\n";
        if ($header_key) {
            $events->{$instance}{$header_key} += $value;
        }
    }
    return ($events, \%header_keys);
}

# Parser "System Statistics - Per Second" 
sub parse_system_stat {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'sys_statistics'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;

    my $events;
    for my $row(@csv) {
        # print Dumper $row;
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        $events->{$instance} = join(' ', @{$row});
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_sys_statistics'}};
    return ($events, \@header);
}

# Parser "Global Cache Efficiency Percentages" : CacheEfficiency
sub parse_cache_efficiency {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'cache_efficiencys'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;

    my $events;
    for my $row(@csv) {
        # print Dumper $row;
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        $events->{$instance} = join(' ', @{$row});
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_cache_efficiencys'}};
    return ($events, \@header);
}

# Parser "Ping Statistics" : PingStatistics
sub parse_ping_statistic {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'ping_statistics'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;
    
    my $events;
    for my $row(@csv) {
        # print Dumper $row;
        my $instance = shift(@{$row});
        my $device   = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        my ($col1, $col2) = ($row->[2], $row->[6]);
        $events->{$instance}{$device} = "$col1 $col2";
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_ping_statistics'}};
    return ($events, \@header);
}

# Parser "Interconnect Client Statistics (per Second)" : InterconnectTraffic
sub parse_interconnect_traffic {
    my ($self, $lines) = @_;

    my @csv = $self->parse_lines($lines, [4]);
    my %header_keys = %{$headers->{'interconnect_traffics'}};
    my %header_reverse = map { $header_keys{$_} => $_; } keys %header_keys;
    
    my $events;
    for my $row(@csv) {
        # print Dumper $row;
        my $instance = shift(@{$row});
        $instance = ($instance =~ /^\*$/) ? 'all' : "instance${instance}";
        my ($col1, $col2) = ($row->[0], $row->[6]);
        $events->{$instance} = "$col1 $col2";
    }
    # my @header = keys %header_keys;
    my @header = @{$headers->{'_interconnect_traffics'}};
    return ($events, \@header);
}


sub simple_report {
    my ($self, $data_info, $lines, $sec, $metric) = @_;
    my ($events, $header) = $self->parse_time_model($lines, $sec);
    # print Dumper $events;
    my $host = $data_info->host_suffix;
    for my $instance (keys %{$events}) {
        my $host_suffix = "${host}_${instance}";
        my $output  = "Oracle/${host_suffix}/${metric}.txt";
        my %data    = ($sec => $events->{$instance});
        # print Dumper $header;
        $data_info->regist_metric($host_suffix, 'Oracle', $metric, $header);
        $data_info->simple_report($output, \%data, $header);
    }

}

sub parse {
    my ($self, $data_info) = @_;

    my $stats;
    my $analysis_lines;
    my $read_phase = 'NOP';

	my $step = 600;
    my $localhost = $data_info->host;
    print "localhost:$localhost\n";
    if ($localhost eq 'k1fwddb001s3') {
         print "SKIP localhost:$localhost\n";
         return;
    }
    my $host = $data_info->file_suffix;
    $data_info->is_remote(1);
 	$data_info->step($step);
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;			# trim return code
        if ($line=~/^Time Model   /) {
            $read_phase = 'TimeModel';
        } elsif ($line=~/^Foreground Wait Classes \s+/) {
            $read_phase = 'ForegroundWait';
        } elsif ($line=~/^Top Timed Events \s+/) {
            $read_phase = 'TimedEvent';
        } elsif ($line=~/^Top Timed Background Events \s+/) {
            $read_phase = 'BackgroundEvent';
        } elsif ($line=~/^System Statistics - Per Second/) {
            $read_phase = 'SystemStatistics';
        } elsif ($line=~/^Global Cache Efficiency Percentages/) {
            $read_phase = 'CacheEfficiency';
        } elsif ($line=~/^Ping Statistics   /) {
            $read_phase = 'PingStatistics';
        } elsif ($line=~/^Interconnect Client Statistics \(per Second\)/) {
            $read_phase = 'InterconnectTraffic';
        }

        if ($line=~/^                          ----------------------------------/) {
            $read_phase = 'NOP';
        }
        my $check = '';
        if ($read_phase ne 'NOP' && $line =~/\d$/ && $line !~/DB\/Inst:/) {
            $check = 'HIT!';
            push(@{$analysis_lines->{$read_phase}}, $line);
        }
        # print "$read_phase:$line $check\n";
	}
	close(IN);

    # Report "Time Model"
    {
        my $lines = $analysis_lines->{'TimeModel'};
        my ($events, $header) = $self->parse_time_model($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            my $output  = "Oracle/${host_suffix}/ora_time_model_rac.txt";
            my %data    = ($sec => $events->{$instance});
            # print Dumper $header;
            $data_info->regist_metric($host_suffix, 'Oracle', 'ora_time_model_rac', $header);
            $data_info->simple_report($output, \%data, $header);
        }
    }
    # Report "Foreground Wait Classes"
    {
        my $lines = $analysis_lines->{'ForegroundWait'};
        my ($events, $header) = $self->parse_foreground_wait($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            my $output  = "Oracle/${host_suffix}/ora_foreground_wait_rac.txt";
            my %data    = ($sec => $events->{$instance});
            # print Dumper $header;
            $data_info->regist_metric($host_suffix, 'Oracle', 'ora_foreground_wait_rac', $header);
            $data_info->simple_report($output, \%data, $header);
        }
    }

    # Report "Top Timed Events"
    {
        my $lines = $analysis_lines->{'TimedEvent'};
        my ($events, $header_keys) = $self->parse_timed_event($lines, $sec);
        # print Dumper $events;
        # print Dumper $header_keys;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            for my $device (keys %{$header_keys}) {
                my $output  = "Oracle/${host_suffix}/device/ora_event_rac2__${device}.txt";
                my $value = 0;
                if ($events->{$instance}{$device}) {
                    $value = $events->{$instance}{$device};
                }
                my %data    = ($sec => $value);
                my $device_text = $header_keys->{$device};
                # print "$output:$device:$device_text:$value\n";

                $data_info->regist_device($host_suffix, 'Oracle', 'ora_event_rac2', 
                                          $device, $device_text, ['elapse']);
                $data_info->simple_report($output, \%data, ['elapse']);
            }
        }
        # for my $instance (keys %{$events}) {
        #     my $host_suffix = "${host}_${instance}";
        #     for my $device (keys %{$events->{$instance}}) {
        #         my $output  = "Oracle/${host_suffix}/device/ora_ping_rac__${device}.txt";
        #         # print "$output\n";
        #         my %data    = ($sec => $events->{$instance}{$device});
        #         # print Dumper $header;
        #         $data_info->regist_device($host_suffix, 'Oracle', 'ora_ping_rac', 
        #                                   $device, $device, $header);
        #         $data_info->simple_report($output, \%data, $header);
        #     }
        # }

    }

    # Report "Top Timed Background Events"
    {
        my $lines = $analysis_lines->{'BackgroundEvent'};
        my ($events, $header_keys) = $self->parse_background_event($lines, $sec);
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            for my $device (keys %{$header_keys}) {
                my $output  = "Oracle/${host_suffix}/device/ora_bgevent_rac2__${device}.txt";
                my $value = 0;
                if ($events->{$instance}{$device}) {
                    $value = $events->{$instance}{$device};
                }
                my %data    = ($sec => $value);
                my $device_text = $header_keys->{$device};

                $data_info->regist_device($host_suffix, 'Oracle', 'ora_bgevent_rac2', 
                                          $device, $device_text, ['elapse']);
                $data_info->simple_report($output, \%data, ['elapse']);
            }
        }
    }

    # Report "System Statistics - Per Second"
    {
        my $lines = $analysis_lines->{'SystemStatistics'};
        my ($events, $header) = $self->parse_system_stat($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            my $output  = "Oracle/${host_suffix}/ora_system_stat_rac.txt";
            my %data    = ($sec => $events->{$instance});
            # print Dumper $header;
            $data_info->regist_metric($host_suffix, 'Oracle', 'ora_system_stat_rac', $header);
            $data_info->simple_report($output, \%data, $header);
        }
    }

    # Report "Global Cache Efficiency Percentages" : CacheEfficiency
    {
        my $lines = $analysis_lines->{'CacheEfficiency'};
        my ($events, $header) = $self->parse_cache_efficiency($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            my $output  = "Oracle/${host_suffix}/ora_cache_hit_rac.txt";
            my %data    = ($sec => $events->{$instance});
            # print Dumper $header;
            $data_info->regist_metric($host_suffix, 'Oracle', 'ora_cache_hit_rac', $header);
            $data_info->simple_report($output, \%data, $header);
        }
    }

    # Report "Ping Statistics" : PingStatistics
    {
        my $lines = $analysis_lines->{'PingStatistics'};
        my ($events, $header) = $self->parse_ping_statistic($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            for my $device (keys %{$events->{$instance}}) {
                my $output  = "Oracle/${host_suffix}/device/ora_ping_rac__${device}.txt";
                # print "$output\n";
                my %data    = ($sec => $events->{$instance}{$device});
                # print Dumper $header;
                $data_info->regist_device($host_suffix, 'Oracle', 'ora_ping_rac', 
                                          $device, $device, $header);
                $data_info->simple_report($output, \%data, $header);
            }
        }
    }

    # Report "Interconnect Client Statistics (per Second)" : InterconnectTraffic
    {
        my $lines = $analysis_lines->{'InterconnectTraffic'};
        my ($events, $header) = $self->parse_interconnect_traffic($lines, $sec);
        # print Dumper $events;
        for my $instance (keys %{$events}) {
            my $host_suffix = "${host}_${instance}";
            my $output  = "Oracle/${host_suffix}/ora_interconnect_rac.txt";
            my %data    = ($sec => $events->{$instance});
            # print Dumper $header;
            $data_info->regist_metric($host_suffix, 'Oracle', 'ora_interconnect_rac', $header);
            $data_info->simple_report($output, \%data, $header);
        }
    }

	return 1;
}

1;
