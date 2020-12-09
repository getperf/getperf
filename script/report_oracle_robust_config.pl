#!/usr/bin/perl
#
# Config file creation 
#

use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use File::Basename qw(dirname);
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';

my $usage = "Usage: cre_config.pl -h --grep=s\n";

my $GREP='';
GetOptions('--grep=s' => \$GREP) || die $usage;

&main();
exit 0;

sub parseTnsNamese {
    my ($host, $inventory) = @_;
    open(IN, $inventory) || die "read error ${inventory}: $!";
    my $tnsname;
    my $configs;
    while (<IN>) {
        $_=~s/(\r|\n)*//g;   # trim return code
        next if ($_=~/^\s*#/);
        $tnsname = $1 if ($_=~/^\s*(\w.+?)\s*=/);
        $configs->{$tnsname} .= $_ if ($tnsname);
    }
    close(IN);
    my $results;
    for my $tnsname (keys %{$configs}) {
        my $body = $configs->{$tnsname};
        my ($enable_broken, $use_scan, $use_service_name) = (0, 0, 0);
        if ($body=~m|(ENABLE\s*=\s*BROKEN)|) {
            $enable_broken = 1;
        }
        if ($body=~m|\(HOST\s*=\s*(.+?)\)|) {
            my $hostname = $1;
            $results->{$tnsname}{host} = $hostname;
            if (lc($hostname) =~ /-scan/) {
                $use_scan = 1;
            }
        }
        if ($body=~m|\(SERVICE_NAME\s*=\s*(.+?)\)|) {
            $results->{$tnsname}{service_name} = $1;
            $use_service_name = 1;
        }
        $results->{$tnsname}{enable_broken} = $enable_broken;
        $results->{$tnsname}{use_scan} = $use_scan;
        $results->{$tnsname}{use_service_name} = $use_service_name;
    }
    return $results;
}

sub parseSysctl {
    my ($host, $inventory) = @_;
    my $results;
    open(IN, $inventory) || die "read error ${inventory}: $!";
    while (<IN>) {
        $_=~s/(\r|\n)*//g;   # trim return code
        if ($_ =~/(tcp_keepalive.+) = (\d+?)$/) {
            $results->{current}{$1} = $2;
        }
    }
    close(IN);
    return $results;
}


sub parseIpadmTcp {
    my ($host, $inventory) = @_;
    my $results;
    open(IN, $inventory) || die "read error ${inventory}: $!";
    while (<IN>) {
        $_=~s/(\r|\n)*//g;   # trim return code
        if ($_ =~/(ip_abort_interval|rexmit_interval_max|keepalive_interval)\s+rw\s+(\d+?)\s/) {
            $results->{current}{$1} = $2;
        }
    }
    close(IN);
    return $results;
}

sub parseIpadmTcpSolaris10 {
    my ($host, $inventory) = @_;
    my $results;
    open(IN, $inventory) || die "read error ${inventory}: $!";
    my @csv;
    while (<IN>) {
        $_=~s/(\r|\n)*//g;   # trim return code
        if ($_=~/^(\d+)$/) {
            push @csv, $1;
        }
    }
    close(IN);
    $results->{current}{tcp_keepalive_interval} = shift(@csv);
    $results->{current}{tcp_rexmit_interval_max} = shift(@csv);
    $results->{current}{tcp_ip_abort_interval} = shift(@csv);
    return $results;
}

sub parseTcpKeepAlive {
    my ($host, $inventory) = @_;
    my $results;
    open(IN, $inventory) || die "read error ${inventory}: $!";
    while (<IN>) {
        $_=~s/(\r|\n)*//g;   # trim return code
        if ($_ =~/(KeepAliveTime|KeepAliveInterval)\s+REG_DWORD\s+0x(.+?)$/) {
            $results->{current}{$1} = hex($2);
        }
    }
    close(IN);
    return $results;
}

sub filter_host {
    my ($host, $filter_hosts) = @_;
    my $ok = 0;
    for my $filter_host(@{$filter_hosts}) {
        if ($host =~ /${filter_host}/) {
            $ok = 1;
        }
    }
    return $ok;
}

sub main {
    my $find = 'find inventory  -name "tn*" -or -name sysctl.txt -or -name "ipadm_tcp*"  -or -name "TcpKeep*"';
    # print $GREP . "\n";
    my @filter_hosts = split(/,/, $GREP);
    my $reports;
    open (my $in, "$find |") || die "can't find '$find' : $!";
    while (my $inventory = <$in>) {
        if ($inventory =~ m|inventory/(.+?)/OracleConf/(.+)$|) {
            chomp $inventory;
            my ($host, $fname) = ($1, $2);
            if (@filter_hosts) {
                next if (filter_host($host, \@filter_hosts) == 0);
            }
            my $res;
            # print "($host, $fname)\n";
            if ($fname =~ /^tn/) {
                $reports->{$host}{'tns'} = parseTnsNamese($host, $inventory);

            } elsif ($fname eq 'sysctl.txt') {
                $reports->{$host}{'sysctl'} = parseSysctl($host, $inventory);

            } elsif ($fname eq 'ipadm_tcp_solaris10.txt') {
                $reports->{$host}{'ipadm_tcp'} = parseIpadmTcpSolaris10($host, $inventory);

            } elsif ($fname eq 'ipadm_tcp.txt') {
                $reports->{$host}{'ipadm_tcp'} = parseIpadmTcp($host, $inventory);

            } elsif ($fname eq 'TcpKeepAlive.txt') {
                $reports->{$host}{'keep_alive'} = parseTcpKeepAlive($host, $inventory);

            } else {
                warn "unkown input file : ${fname}\n";
            }
        }
    }
    close($in);

    print "HOST\tINVENTORY\tINSTANCE\tMETRIC\tVALUE\n";
    for my $host(sort keys %{$reports}) {
        for my $inventory(sort keys%{$reports->{$host}}) {
            for my $instance(sort keys%{$reports->{$host}{$inventory}}) {
                for my $metric(sort keys%{$reports->{$host}{$inventory}{$instance}}) {
                    my $value = $reports->{$host}{$inventory}{$instance}{$metric};
                    print "${host}\t${inventory}\t${instance}\t${metric}\t${value}\n";
                }
            }
        }
    }

    return 1;
}

