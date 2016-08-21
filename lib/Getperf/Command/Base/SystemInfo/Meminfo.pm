package Getperf::Command::Base::SystemInfo::Meminfo;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

# MemTotal:        7875684 kB
# MemFree:          175644 kB
# Buffers:          680528 kB
# Cached:          3999904 kB
# SwapCached:         2264 kB
# Active:          2801252 kB
# Inactive:        2742660 kB
# Active(anon):     502036 kB
# Inactive(anon):   656520 kB
# Active(file):    2299216 kB
# Inactive(file):  2086140 kB
# Unevictable:          20 kB
# Mlocked:              20 kB
# SwapTotal:       8085500 kB

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;


	my %mem_infos = ();
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		next if ($line!~/^(.*?)\s*:\s+(.*)$/);
		my ($item, $val) = ($1, $2);
		$val=~s/ kB//g;
		if ($item eq 'MemTotal') {
			$mem_infos{mem_total} = 1024 * $val;
		}	elsif ($item eq 'SwapTotal') {
			$mem_infos{swap_total} = 1024 * $val;
		}
	}
	close(IN);

	my %stat = (
		total   => $mem_infos{'mem_total'},
		swap    => $mem_infos{'swap_total'},
	);
	$data_info->regist_node($host, 'Linux', 'info/mem', \%stat);

	return 1;
}
1;