package Getperf::Command::Site::Oracle::Awrreport;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Time::Local;
use base qw(Getperf::Container);
use Getperf::Command::Site::Oracle::AwrreportHeader;

sub new {bless{},+shift}

our $headers = get_headers();
our $months  = get_months();

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

sub parse_loadprof {
    my ($str) = @_;
    my %loadprof = ();
    for my $key(keys %{$headers->{load_profiles}}) {
        my $keyword = $headers->{load_profiles}{$key};
        if ($str=~/$keyword:(.*)$/ || $str=~/${keyword}\s*\(\S+\):(.*)$/) {
            my @vals = split(' ', $1);
            my $val = shift(@vals);
            $val=~s/,//g;
            $loadprof{$key} = norm($val);
        } else {
            $loadprof{$key} = 0;
        }
    }
    return %loadprof;
}

sub parse_hit {
    my ($str) = @_;

    my %hit = ();
    for my $key(keys %{$headers->{hits}}) {
        my $keyword = $headers->{hits}{$key};
        if ($str=~/$keyword:(.*)$/) {
            my @vals = split(' ', $1);
            $hit{$key} = shift(@vals);
        } else {
            $hit{$key} = 0;
        }
    }
    return %hit;
}

sub parse_event {
    my ($str, $bg_event_str) = @_;

    my %event = ();
    for my $key(keys %{$headers->{events}}) {
        my $keyword = $headers->{events}{$key};
        if ($str=~/$keyword\s+(\d.*)$/) {
            my $val_str = $1;
            $val_str=~s/,//g;
            my @vals = split(/\s+/, $val_str);
            if ($keyword eq 'CPU time' || $keyword eq 'DB CPU') {
                $event{$key} = norm(shift(@vals));
            } else {
                my $val = $vals[1];
                $event{$key} += norm($val);
            }
        } else {
            $event{$key} = 0;
        }
    }
    print Dumper \%event;
    for my $key(keys %{$headers->{events}}) {
        my $keyword = $headers->{events}{$key};
        if ($bg_event_str=~/($keyword)\s+(\d.*)$/) {
            my $item = $1;
            my @vals = split(/\s+/, $2);
            my $val = undef;
            if ($key eq 'CPUTime' || $key eq 'DB CPU') {
                $val = shift(@vals);
            } else {
                $val = norm($vals[2]);
            } 
            if (defined($val)) {
                $val=~s/,//g;
                $event{$key} += norm($val);
            }
        }
    }
    return %event;
}

sub parse {
    my ($self, $data_info) = @_;

    my $tm_flg = 0;
    my $tm_str;
    my $loadprof_flg = 0;
    my $loadprof_str;
    my $hit_flg = 0;
    my $hit_str;
    my $event_flg = 0;
    my $event_str;
    my $bgevent_flg = 0;
    my $bgevent_str;

    my $step = 3600;

    $data_info->step($step);
    my $sec  = $data_info->start_time_sec->epoch;
    if (!$sec) {
        return;
    }
    open( IN, $data_info->input_file ) || die "@!";
    while (my $line = <IN>) {
        $line=~s/(\r|\n)*//g;           # trim return code

        # 日付読込
        if ($line=~/^\s+End Snap:/) {
            $tm_flg = 1;
        } elsif ($line=~/^\s+Elapsed:/) {
            $tm_flg = 0;
        }
        if ($tm_flg == 1) {
            $tm_str .= ' '. $line;
        }

        # ロードプロファイル読込
        if ($line=~/^Load Profile/) {
            $loadprof_flg = 1;
        } elsif ($line=~/Instance Efficiency Percentages/) {
            $loadprof_flg = 0;
        }
        if ($loadprof_flg == 1) {
            $loadprof_str .= ' '. $line;
        }

        # ヒット率読込
        if ($line=~/^Instance Efficiency Percentages/) {
            $hit_flg = 1;
        } elsif ($line=~/Foreground Events by Total Wait Time/) {
            $hit_flg = 0;
        }
        if ($hit_flg == 1) {
            $hit_str .= ' '. $line;
        }

        # Top5イベント読込
        if ($line=~/Foreground Events/) {
            $event_flg = 1;
        } elsif ($line=~/(Wait Classes by Total Wait Time|Memory Statistics)/) {
            $event_flg = 0;
        }
        if ($event_flg == 1) {
            $event_str .= ' '. $line;
        }
        # Top5バックグラウンドイベント読込
        if ($line=~/Background Wait Events/) {
            $bgevent_flg = 1;
        } elsif ($line=~/^\s+-------------/) {
            $bgevent_flg = 0;
        }
        if ($bgevent_flg == 1) {
 # print "BG:$line\n";
            $bgevent_str .= ' '. $line;
        }
    }
    close(IN);

    if ($tm_str=~/(\d\d)-\s*(.*?)\s*-(\d\d) (\d\d):(\d\d):(\d\d)/) {
        my ($DD, $MM, $YY, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
        if (defined($months->{$MM})) {
            $MM  = $months->{$MM} - 1;
            $sec = timelocal($ss, $mm, $hh, $DD, $MM, $YY-1900+2000);
        }
    }

    # 各ブロックのレポートをデータに変換
    my %loadprof = parse_loadprof($loadprof_str);
    my %hit = parse_hit($hit_str);
    my %event = parse_event($event_str, $bgevent_str);

    # # ロードプロファイルの出力
    $data_info->is_remote(1);
    my $host = $data_info->file_name;
    $host=~s/^.+_//g;
    {
        my @header = keys %{$headers->{load_profiles}};
        my $output  = "Oracle/${host}/ora_load.txt";
        my %data    = ($sec => \%loadprof);
        $data_info->regist_metric($host, 'Oracle', 'ora_load', \@header);
        $data_info->pivot_report($output, \%data, \@header);
    }
    {
        my @header = keys %{$headers->{hits}};
        my $output  = "Oracle/${host}/ora_hit.txt";
        my %data    = ($sec => \%hit);
        $data_info->regist_metric($host, 'Oracle', 'ora_hit', \@header);
        $data_info->pivot_report($output, \%data, \@header);
    }
    {
        my @header = keys %{$headers->{events}};
        my $output  = "Oracle/${host}/ora_event.txt";
        my %data    = ($sec => \%event);
        $data_info->regist_metric($host, 'Oracle', 'ora_event', \@header);
        $data_info->pivot_report($output, \%data, \@header);
    }

    return 1;
}

1;
