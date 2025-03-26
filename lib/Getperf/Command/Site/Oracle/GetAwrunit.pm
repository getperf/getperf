package Getperf::Command::Site::Oracle::GetAwrunit;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Time::Local;
# use String::CamelCase qw(camelize decamelize wordsplit);
use base qw(Getperf::Container);
# use Getperf::Command::Site::Oracle::AwrreportHeaderRac;
use Getperf::Command::Site::Oracle::GetAwrgrpt;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;
    return Getperf::Command::Site::Oracle::GetAwrgrpt::parse($self, $data_info, 0);
}

1;
