package Getperf::Command::Base::SystemInfo::Cpuinfo;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

#model name      : Intel(R) Core(TM) i3-3220 CPU @ 3.30GHz
#cpu MHz         : 2812.439
#cache size      : 512 KB
#cpu cores       : 1

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;

	my %cpu_infos = ();
	my $num_cpu = 0;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		$num_cpu ++ if ($line=~/^processor/);
		next if ($line!~/^(.*?)\s+:\s+(.*)$/);
		$cpu_infos{$1} = $2;
	}
	close(IN);

	my %stat = (
		model   => $cpu_infos{'model name'},
		cpu_mhz => $cpu_infos{'cpu MHz'},
		cache   => $cpu_infos{'cache size'},
		cpus    => $num_cpu,
		cores   => $cpu_infos{'cpu cores'},
	);
	$data_info->regist_node($host, 'Linux', 'info/cpu', \%stat);

	return 1;
}
1;