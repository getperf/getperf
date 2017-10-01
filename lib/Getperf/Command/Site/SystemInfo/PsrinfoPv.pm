package Getperf::Command::Site::SystemInfo::PsrinfoPv;
use strict;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

#　The physical processor has 32 virtual processors (0-31)
#　  SPARC64-X (chipid 0, clock 2800 MHz)
#　The physical processor has 32 virtual processors (32-63)
#　  SPARC64-X (chipid 1, clock 2800 MHz)
# The physical processor has 32 virtual processors (0-31)
#   UltraSPARC-T2 (chipid 0, clock 1165 MHz)
# The physical processor has 4 virtual processors (0 2-4)
#   x86 (chipid 0x0 GenuineIntel family 6 model 23 step 6 clock 2992 MHz)
#         Intel(r) Xeon(r) CPU           E5450  @ 3.00GHz
# The physical processor has 4 virtual processors (1 5-7)
#   x86 (chipid 0x1 GenuineIntel family 6 model 23 step 6 clock 2992 MHz)
#         Intel(r) Xeon(r) CPU           E5450  @ 3.00GHz

# Node 'i86pc'

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;

	my ($cpus, $processor);
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		# The physical processor has 4 virtual processors 
		if ($line=~/^The physical processor has (\d+) /) {
			$cpus += $1;
		}
		#   UltraSPARC-T2 (chipid 0, clock 1165 MHz)
		if ($line=~/^\s+(.*SPARC.*) \((.+)\)$/) {
			$processor  = $1;
			$processor .= ($2=~/clock (\d.+)$/) ? " $1" : '';
		}
		#   Intel(r) Xeon(r) CPU           E5450  @ 3.00GHz
		if ($line=~/^\s+Intel/) {
			$processor = $line;
			$processor =~s/\(.*?\)//g;
			$processor =~s/\s+/ /g;
			$processor =~s/CPU//g;
		}
	}
	close(IN);

	my %stat = (
		cpus      => $cpus,
		processor => $processor,
	);
	$data_info->regist_node($host, 'Solaris', 'info/cpu', \%stat);

	return 1;
}
1;