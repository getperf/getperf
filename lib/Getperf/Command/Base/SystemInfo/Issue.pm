package Getperf::Command::Base::SystemInfo::Issue;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

# Ubuntu 14.04.2 LTS \n \l
# CentOS release 6.6 (Final)
# Kernel \r on an \m

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;

	my %cpu_infos = ();
	open( IN, $data_info->input_file ) || die "@!";
	my $line = <IN>;
	$line=~s/(\r|\n)*//g;	# trim return code
	$line=~s/\s*(\\r|\\m|\\n).*//g;	# trim right special char
	close(IN);

	my %stat = (
		issue   => $line,
	);
	$data_info->regist_node($host, 'Linux', 'info/os', \%stat);

	return 1;
}
1;