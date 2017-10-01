package Getperf::Command::Site::SystemInfo::PrtconfP;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

# System Configuration:  Oracle Corporation  i86pc
# Memory size: 3072 Megabytes
# System Peripherals (PROM Nodes):

# Node 'i86pc'

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;


	my ($mem_total);
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		# Memory size: 3072 Megabytes
		if ($line=~/^Memory size: (\d+) Megabytes$/) {
			$mem_total = 1024 * 1024 * $1;
		}
	}
	close(IN);

	my %stat = (
		total   => $mem_total,
	);
	$data_info->regist_node($host, 'Solaris', 'info/mem', \%stat);

	return 1;
}
1;