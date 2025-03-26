package Getperf::Command::Site::Solaris::Netstats;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/tcpIn:COUNTER:120:0:100000000 tcpOut:COUNTER:120:0:100000000 tcpDupAck:COUNTER:120:0:100000000 tcpRetran:COUNTER:120:0:100000000/;
	$data_info->step($step);
	my $host = $data_info->host;

	if ($host=~/sv/) { # Parse AIX
		return 1;
	}
	my $sec  = $data_info->start_time_sec->epoch - $step;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";

	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code

	    if ( $line =~ /^UDP/ ) {
	    	$sec += $step;
	    }
	    if ( $line =~ /tcpOutDataBytes\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpIn}     += $1;
	    }
	    elsif ( $line =~ /tcpRetransSegs\s*=\s*(\d*)\s+tcpRetransBytes\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpRetran}  = $1;
	        $results{$sec}{tcpIn}     += $2;
	    }
	    elsif ( $line =~ /tcpInAckBytes\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpOut}    += $1;
	    }
	    elsif ( $line =~ /tcpInDupAck\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpDupAck}  = $1;
	    }
	    elsif ( $line =~ /tcpInInorderBytes\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpOut}    += $1;
	    }
	    elsif ( $line =~ /tcpInUnorderBytes\s*=\s*(\d*)/ ) {
	        $results{$sec}{tcpOut}    += $1;
	    }
	}
	close($in);
	$data_info->regist_metric($host, 'Solaris', 'netstats', \@headers);
	$data_info->pivot_report('netstats.txt', \%results, \@headers);

	return 1;
}

1;
