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


# sub parse_loadprof {
#     my ($lines) = @_;

# 	my %loadprof = ();
#     for my $line(@{$lines}) {
#         if ($line=~/\s(.+\d)/) {
#             my @values = split(' ', $line);
#             my $instance = shift(@values);
#             $loadprof{$instance} = join(' ', @values);
#         }
#     }
# 	return %loadprof;
# }

# sub parse_hit {
#     my ($lines) = @_;

#     my %cache_hit = ();
#     for my $line(@{$lines}) {
#         if ($line=~/\s(.+\d)/) {
#             my @values = split(' ', $line);
#             my $instance = shift(@values);
#             $cache_hit{$instance} = join(' ', @values);
#         }
#     }
#     return %cache_hit;
# }

# sub trim {
#     my $val = shift;
#     $val =~ s/^ *(.*?) *$/$1/;
#     return $val;
# }

# sub parse_event {
#     my ($lines, $ref_headers) = @_;

#     my $event;
#     my $instance0 = 'unkown';
#     my %ev;
#     my %headers = %{$ref_headers};
#     my %headers_reverse = map { $headers{$_} => $_; } keys %headers;

#     for my $line(@{$lines}) {
#         if ($line=~/^(.{4})   (.{10}) (.{40})   (.+\d)$/) {
#             # print "CK:$1,$2,$3,$4\n";
#             my $instance   = $1;
#             my $module     = $2;
#             my $event_name = $3;
#             my $csvs       = $4;
#             $instance = trim($instance);
#             if ($1!~/^\s+$/) {
#                 $instance0 = $instance;
#                 $instance0 =~s/\*/Sum/g;
#             }
#             my $event_name = trim($event_name);
#             $ev{$event_name} = 1;
#             my $header_key = $headers_reverse{$event_name};
#             my @values = split(' ', $csvs);
#             # print "EVENT:$event_name,$header_key,$values[2]\n";
#             if ($header_key) {
#                 $event->{$instance0}{$header_key} = $values[2];
#             }
#         }
#     }
#     # print Dumper $event;
#     return $event;
# }

# sub parse_global_cache {
#     my ($str) = @_;

#     my %global_cache = ();
#     if ($str=~/Estd Interconnect traffic .* ([\d|\.]+)/) {
#         $global_cache{'traffic'} = $1;
#     }
#     return %global_cache;
# }

# sub parse_interconnect_ping {
#     my ($lines) = @_;
#     my %interconnect_ping = ();
#     # if ($str=~/Estd Interconnect traffic .* ([\d|\.]+)/) {
#     #     $interconnect_ping{'interconnect_traffic'} = $1;
#     # }
#     for my $line(@{$lines}) {
#         if ($line =~/^\s*([\d\.\s]+)$/){
#             my @arr = split(' ',$line);
#             if (scalar(@arr) == 7) {
#                 # print Dumper \@arr;
#                 $interconnect_ping{$arr[0]} = $arr[5];
#             }
#             # print "LINE:$line\n";
#         }
#     }
#     return %interconnect_ping;
# }


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


sub parse {
    my ($self, $data_info) = @_;

    my $stats;
    my $read_phase = 'start';

	# my $tm_flg = 0;
	# my $tm_str = "";
	# my $loadprof_flg = 0;
	# my $loadprof_str = "";
	# my $hit_flg = 0;
	# my $hit_str = "";
	# my $event_flg = 0;
 #    my $foreground_event_flg = 0;
	# my $event_str = "";
	# my $bgevent_flg = 0;
	# my $bgevent_str = "";
 #    my $global_cache_flg = 0;
 #    my $global_cache_str = "";
 #    my $interconnect_ping_flg = 0;
 #    my @interconnect_ping_strs;

 #    my @tm_strs;
 #    my @loadprof_strs;
 #    my @hit_strs;
 #    my @event_strs;
 #    my @bgevent_strs;
 #    my @global_cache_strs;
 #    my @interconnect_ping_strs;

	my $step = 600;

    my %direct_path_event = ();

	$data_info->step($step);
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;			# trim return code
        if ($line=~/^Time Model                 /) {
            $read_phase = 'TimeModel';
        }
        if ($line=~/^                          ----------------------------------/) {
            $read_phase = 'NOP';
        }
        print "$read_phase:$line\n";
# 		# 日付読込
# 		if ($line=~ /Startup\s+Begin Snap Time\s+End Snap Time/) {
# 			$tm_flg = 1;
# 		} elsif ($line eq "") {
# 			$tm_flg = 0;
# 		}
# 		if ($tm_flg == 1) {
#             push (@tm_strs, $line);
# 		}

# 		# ロードプロファイル読込
# 		if ($line=~/^\s+SQL Exec\s+Hard Parse/) {
# 			$loadprof_flg = 1;
# 		}
# 		if ($loadprof_flg == 1 && $line eq "") {
# 			$loadprof_flg = 0;
# 		}
# 		if ($loadprof_flg == 1) {
# # print "LOAD:$line\n";
# 			# $loadprof_str .= ' '. $line;
#             push (@loadprof_strs, $line);
# 		}

# 		# ヒット率読込
# 		if ($line=~/Local %\s+Remote %\s+Disk/) {
# 			$hit_flg = 1;
#         } elsif ($line=~/^\s+---------------------------------------------------------/) {
# 			$hit_flg = 0;
# 		}
# 		if ($hit_flg == 1) {
# # print "HIT:$line\n";
# 			# $hit_str .= ' '. $line;
#            push (@hit_strs, $line);
# 		}

#         # フォアグラウンドイベント読込
#         if ($line=~/^Top Timed Foreground Events/) {
#             $event_flg = 1;
#         } elsif ($line=~/^\s+---------------------------------------------------------/) {
#             $event_flg = 0;
#         }
#         if ($event_flg == 1) {
# print "EVENT:$line\n";
#             push(@event_strs, $line);
#             # $event_str .= ' '. $line;
# # print "EVENT:$line\n";
#         }
#         # バックグラウンドイベント読込
#         if ($line=~/Top Timed Background Events/) {
#             $bgevent_flg = 1;
#         } elsif ($line=~/^\s+---------------------------------------------------------/) {
#             $bgevent_flg = 0;
#         }
#         if ($bgevent_flg == 1) {
# # print "BG:$line\n";
#             $bgevent_str .= ' '. $line;
# print "BG:$line\n";
#             push(@bgevent_strs, $line);
#         }

#         # グローバルキャッシュプロファイル読込
#         if ($line=~/^SysStat and  Global Messaging \(per Sec\)/) {
#             $global_cache_flg = 1;
#         } elsif ($line=~/^\s+---------------------------------------------------------/) {
#             $global_cache_flg = 0;
#         }
#         if ($global_cache_flg == 1) {
#  # print "Global Cache:$line\n";
#             $global_cache_str .= ' '. $line;
#         }

#         # インターコネクトPINGレイテンシー読込
#         if ($line=~/Interconnect Ping Latency Stats/) {
#             $interconnect_ping_flg = 1;
#         } elsif ($line=~/^\s*Interconnect Throughput by ClientDB/) {
#             $interconnect_ping_flg = 0;
#         }
#         if ($interconnect_ping_flg == 1) {
#  # print "BG:$line\n";
#             push (@interconnect_ping_strs, $line);
#         }

#         if ($foreground_event_flg && $line=~/^direct path (read|write) temp\s+(.+?)\s/) {
#             my ($io, $waits) = ($1, $2);
#             $waits=~s/,//g;
#             $direct_path_event{$sec}{$io} = $waits;
#         }
	}
	close(IN);

 #    # print Dumper \@interconnect_ping_strs;
	# if ($tm_str=~/(\d\d)-\s*(.*?)\s*-(\d\d) (\d\d):(\d\d):(\d\d)/) {
	# 	my ($DD, $MM, $YY, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
	# 	if (defined($months->{$MM})) {
	# 		$MM  = $months->{$MM} - 1;
	# 		$sec = timelocal($ss, $mm, $hh, $DD, $MM, $YY-1900+2000);
	# 	}
	# }

	# # 各ブロックのレポートをデータに変換
	# my %loadprof = parse_loadprof(\@loadprof_strs);
	# my %cache_hit = parse_hit(\@hit_strs);
 #    my $event = parse_event(\@event_strs, $headers->{events});
 #    my %bgevent = parse_event(\@bgevent_strs, $headers->{events});
 #    print Dumper $event;
 #    # my %event = parse_event(\@event_strs, $headers->{events});
 #    my %global_cache = parse_global_cache($global_cache_str);
 #    my %interconnect_ping = parse_interconnect_ping(\@interconnect_ping_strs);

	# # # ロードプロファイルの出力
	# $data_info->is_remote(1);
 #    my $host = $data_info->file_suffix;
 #    for my $instance (keys %loadprof) {
 #        my $host_suffix = "${host}_${instance}";
 #        my $output  = "Oracle/${host_suffix}/ora_load_rac.txt";
 #        my %data    = ($sec => $loadprof{$instance});
 #        my @header = keys %{$headers->{load_profiles}};
 #        $data_info->regist_metric($host_suffix, 'Oracle', 'ora_load_rac', \@header);
 #        $data_info->simple_report($output, \%data, \@header);
 #    }

 #    for my $instance (keys %cache_hit) {
 #        my $host_suffix = "${host}_${instance}";
 #        my $output  = "Oracle/${host_suffix}/ora_hit_rac.txt";
 #        my %data    = ($sec => $cache_hit{$instance});
 #        my @header = keys %{$headers->{hits}};
 #        $data_info->regist_metric($host_suffix, 'Oracle', 'ora_hit_rac', \@header);
 #        $data_info->simple_report($output, \%data, \@header);
 #    }

 #    for my $instance (keys %event) {
 #        my $host_suffix = "${host}_${instance}";
 #        my $output  = "Oracle/${host_suffix}/ora_event_rac.txt";
 #        my %data    = ($sec => $event{$instance});
 #        my @header = keys %{$headers->{events}};
 #        print Dumper \@header;
 #        # $data_info->regist_metric($host_suffix, 'Oracle', 'ora_event_rac', \@header);
 #        # $data_info->pivot_report($output, \%data, \@header);
 #    }

    # my %event_headers =  %{$headers->{events}};
    # my %event_headers2 = map { $event_headers{$_} => $_; } keys %event_headers;
    # print Dumper \%event_headers;
    # print Dumper \%event_headers2;
	# {
	# 	my @header = keys %{$headers->{load_profiles}};
	# 	my $output  = "Oracle/${host}/ora_load.txt";
	# 	my %data    = ($sec => \%loadprof);
	# 	$data_info->regist_metric($host, 'Oracle', 'ora_load', \@header);
	# 	$data_info->pivot_report($output, \%data, \@header);
	# }
	# {
	# 	my @header = keys %{$headers->{hits}};
	# 	my $output  = "Oracle/${host}/ora_hit.txt";
	# 	my %data    = ($sec => \%hit);
	# 	$data_info->regist_metric($host, 'Oracle', 'ora_hit', \@header);
	# 	$data_info->pivot_report($output, \%data, \@header);
	# }
	# {
	# 	my @header = keys %{$headers->{events}};
	# 	my $output  = "Oracle/${host}/ora_event.txt";
	# 	my %data    = ($sec => \%event);
	# 	$data_info->regist_metric($host, 'Oracle', 'ora_event', \@header);
	# 	$data_info->pivot_report($output, \%data, \@header);
	# }
 #    {
 #        my @header = qw/read write/;
 #        my $output  = "Oracle/${host}/ora_direct_path_io_temp.txt";
 #        $data_info->regist_metric($host, 'Oracle', 'ora_direct_path_io_temp', \@header);
 #        $data_info->pivot_report($output, \%direct_path_event, \@header);
 #    }
 #    {
 #        my @header = qw/traffic/;
 #        # print Dumper \%global_cache;
 #        my $output  = "Oracle/${host}/ora_global_cache_traffic.txt";
 #        my %data    = ($sec => \%global_cache);
 #        $data_info->regist_metric($host, 'Oracle', 'ora_global_cache_traffic', \@header);
 #        $data_info->pivot_report($output, \%data, \@header);
 #    }
 #    {
 #        my @header = qw/latency/;
 #        for my $instance(keys %interconnect_ping) {
 #            my $output  = "Oracle/${host}/device/ora_interconnect_ping__${instance}.txt";
 #            my %data    = ($sec =>  $interconnect_ping{$instance});
 #            print "INS:$instance,$output\n";
 #            print Dumper \%data;
 #            $data_info->regist_device($host, 'Oracle', 'ora_interconnect_ping',
 #                                      $instance, $instance, \@header);
 #            $data_info->simple_report($output, \%data, \@header);
 #        }

 #        # my %data    = ($sec => \%global_cache);
 #        # $data_info->regist_metric($host, 'Oracle', 'ora_global_cache_traffic', \@header);
 #        # $data_info->pivot_report($output, \%data, \@header);
 #    }

        # if ($device_info) {
        #     my $output_file = "device/iostat__${device}.txt";
        #     $data_info->regist_device($host, 'Linux', 'iostat', $device, $device_info, \@headers);
        #     $data_info->pivot_report($output_file, $results{$device}, \@headers);
        # }

	return 1;
}

1;
