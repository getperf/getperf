package Getperf::Command::Site::AIX::NmonBase;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::AIX;
use Getperf::Command::Site::AIX::ListNmonHourly;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;
    my %results;
    print "TEST1\n";
    return $self->Getperf::Command::Site::AIX::ListNmonHourly::parse_nmon(
        $data_info, 'nmon_base.csv', \%results);
    return 1;
}

1;
