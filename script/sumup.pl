#!/usr/bin/perl
#
# Sumup CLI 
#

use strict;
use FindBin;
use Daemon::Control;
use Path::Class;
BEGIN { push(@INC, $FindBin::Bin . '/../lib'); }
use Getperf::SumUp;

if (!exists $ENV{SITEHOME} || !-d $ENV{SITEHOME}) {
	die "Invalid environment variables 'SITEHOME'";
}
my $home = $ENV{SITEHOME};

if ($ARGV[0]=~/^(start|stop|restart|status)$/) {
	exit Daemon::Control->new(
	    name         => "Getperf Sumup daemon",
	    path         => $FindBin::Bin . "/sumup.pl",
	 
	    program      => 'perl',
	    program_args => [
			"-I$home/lib",
			$FindBin::Bin . "/sumup.pl",
			"--daemon",
	    ],
	 
	    pid_file     => "$home/.pid",
        stderr_file  => "$home/.stderr",
        stdout_file  => "$home/.stdout",
	)->run;

} else {
	eval {
		my $calculator = new Getperf::SumUp();
		$calculator->parse_command_option();
	};
	if ($@) {
	  print "Error!\n$@";
	  exit 1;
	}

}

