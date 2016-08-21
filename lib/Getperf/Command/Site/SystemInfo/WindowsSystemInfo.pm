package Getperf::Command::Site::SystemInfo::WindowsSystemInfo;
use warnings;
use Log::Handler app => "LOG";
use FindBin;
use Time::Piece;
use Data::Dumper;
use lib $FindBin::Bin;
use base qw(Getperf::Container);

# wmic_get::model
# Name
# Intel(R) Core(TM) i3 CPU         540  @ 3.07GHz
# wmic_get::logical_cpu
# NumberOfLogicalProcessors
# 4
# wmic_get::core_cpu
# NumberOfCores
# 2
# wmic_get::os
# Name
# Microsoft Windows 7 Home Premium |C:\Windows|
# wmic_get::MemTotal
# TotalPhysicalMemory
# 3706707968
# wmic_get::SwapTotal
# TotalVirtualMemorySize
# 7237916

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host   = $data_info->host;
	my $infile = $data_info->input_file;
	# Windows の場合はUTF,改行コードを変更する
#	my $cmd = "nkf -w -Lu --overwrite $infile";
#	if (system($cmd) != 0) {
#		die "nkf error: $cmd\n";
#	} 

	my %system_infos = ();
	open( IN, $infile ) || die "@!";
	my ($item, $value);
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		# wmic実行結果は各文字コードの後に\0が入る。\0が入ったままだと正規表現が
		# 使えないため取り除く。 例) "Name" = 0x23075d0 "N\0a\0m\0e\0\n"\0
		# UCS-2-LITTLE-ENDIAN エンコード
		$line=~s/\x0//g;
		if ($line=~/^wmic_get::(.+?)$/) {
			$item = $1;
			<IN>;
 		} elsif ($line=~/^(.+)$/) {
			$value = $1;
			$value=~s/\|.+?\|//g;
			$value=~s/\s\s+/ /g;
			$value=~s/\s+$//g;
			$value=~s/\s+\\.+$//g;
 			$system_infos{$item} = $value;
		}
	}
	close(IN);

	$data_info->regist_node($host, 'Windows', 'info/system', \%system_infos);

	return 1;
}
1;