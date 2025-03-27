package Getperf::Command::Site::AIX::ListNmonHourly;
use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::AIX;

sub new {bless{},+shift}

my $DEBUG = 0;

my $HONBAN_K2_FLAG_FILE = '/home/psadmin/honban_k2';

my %MONTH = (
	'JAN', '01', 'FEB', '02', 'MAR', '03', 'APR', '04', 'MAY', '05', 'JUN', '06', 
	'JUL', '07', 'AUG', '08', 'SEP', '09', 'OCT', '10', 'NOV', '11', 'DEC', '12');

my %DATAITEM = (
	'CPU_ALL', 'Single',
	'MEM',     'Single',
	'MEMNEW',  'Single',
	'MEMUSE',  'Single',
	'PAGE',    'Single',
	'PROC',    'Single',

	'NET',       'NETWORK',
	'NETERROR',  'NETWORK',
	'DISKBUSY',  'DISK',
	'DISKREAD',  'DISK',
	'DISKWRITE', 'DISK',
	'DISKRIO',   'DISK',
	'DISKWIO',   'DISK',
	'DISKXFER',  'DISK',
#	'JFSFILE',   'JSF',
);

sub parse_nmon {
	my ($self, $data_info, $nmon_file, $results) = @_;

	my $host = $data_info->host;
	return if ($host=~/^k2pi/);
	print "HOST:$host\n";
	# K2 稼働系の場合、k1pi～の集計を無効化し、ホスト名をサービスホスト名に変更する
	# if (-f $HONBAN_K2_FLAG_FILE) {
	# 	print "HONBAN_K2: $host\n";
	# 	return if ($host=~/^(k1)(.+)$/);
	# 	$host =~s/k2/k0/g;
	# 	print "HOST: $host\n";
	# } else {
	# 	print "HONBAN_K1: $host\n";
	# 	return if ($host=~/^(k2)(.+)$/);
	# 	$host =~s/k1/k0/g;
	# 	print "HOST: $host\n";
	# }
	
	if (my $node_path = alias_node_path($host)) {
		$data_info->regist_node($host, 'AIX', 'info/node_path', {node_path => $node_path } );
	} else {
		return;
	}
	my $sec  = $data_info->start_time_sec;
	# my $nmon_path = file($data_info->input_dir, 'nmon_hourly', $nmon_file);
	my $nmon_path = file($data_info->input_dir, $nmon_file);
	# print "$nmon_path\n";
	open (my $in, $nmon_path) || die "@!";
	my (%headers, %device_headers, %device_columns, %info);
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;

		my @items = split(/,/, $line);
		my $metric = shift(@items);
		my $idx  = shift(@items);

		# システムプロパティチェック [eg] AAA,AIX,7.1.3.45
		if ($metric eq 'AAA') {
			if ($idx eq 'AIX') {
				$info{os} = 'AIX' . join(' ', @items);
			} elsif ($idx eq 'interval') {
				$data_info->step(shift(@items));
			} elsif ($idx eq 'hardware') {
				my $hardware = join(' ', @items);
				$hardware =~s/Architecture PowerPC Implementation //g;
				$info{hardware} = $hardware;
			} elsif ($idx eq 'cpus') {
				$info{cpus} = join('/', @items);
			} elsif ($idx eq 'MachineType') {
				$info{MachineType} = join(' ', @items);
			}

		# 日付フォーマットのチェック [eg] 23:01:13,11-MAY-2016
		} elsif ($metric eq 'ZZZZ') {
			print "Time  [$idx] " . join(",", @items) . "\n" if ($DEBUG);
			my $tm = shift(@items);
			my $dt = shift(@items);
			$sec = localtime(Time::Piece->strptime("$dt $tm", '%d-%b-%Y %H:%M:%S'))->epoch;
		}

		# HW基本リソースのデータ以外は取り除く
		next if (!defined($DATAITEM{$metric}));
		# ヘッダ部の抽出
		if ($idx !~ /T\d+/) {
			# 文字列から"%","(",")",スペースを取り除く
			map { s/[\%|\s|\(|\)]//g } @items;
			# 先頭の"/"を除き、"/"を"_"に置換する
			map { s/^\/$/root/g } @items;
			map { s/^\///g } @items;
			map { s/\//_/g } @items;
			if (defined(my $cat = $DATAITEM{$metric})) {
				# 縦持ちデータの場合はそのままヘッダーを登録
				if ($cat eq 'Single') {
					map { s/-/_/g } @items;
					$headers{$metric} = \@items;
				# 横持データ(デバイス)の場合は、デバイス、ヘッダ名をキーに登録
				} else {
					my $idx = 0;
					my %header;
					map {
						my ($device, $item) = ($_, $metric);
						if ($cat=~/^NET/ && $device=~/^(.+?)-(.+)$/) {
							($device, $item) = ($1, $2);
						}
						$item=~s/-/_/g;
						$device_columns{$metric}{$cat}{$idx} = [$device, $item];
						$device_headers{$cat}{$metric} = 1;
						$header{$item} = $idx;
						$idx ++;
					} @items;

					if (!defined($headers{$metric})) {
						my @header2 = sort {$header{$a} <=> $header{$b}} keys %header;
						$headers{$metric} = \@header2;
					}
				}
			}

		# データ部の抽出
		} else {
			map { s/^$/0/g } @items;
			if (defined(my $cat = $DATAITEM{$metric})) {
				# 縦持ちデータの場合はそのままヘッダーを登録
				if ($cat eq 'Single') {
					$results->{$metric}{$sec} = join(' ', @items);
				# 横持データ(デバイス)の場合は、デバイス、ヘッダ名をキーに登録
				} else {
					my $idx = 0;
					map {
						my $device_items = $device_columns{$metric}{$cat}{$idx};
						my ($device, $item) = @$device_items;
						$results->{$cat}{$device}{$sec}{$item} = $_;
						$idx ++;
					} @items;
				}
			}
		}
	}
	# print Dumper \%device_columns;
	for my $metric(keys %$results) {
		my $lc_metric = lc($metric);
		# 縦持ちデータ
		if (defined(my $cat = $DATAITEM{$metric})) {
			my $header = $headers{$metric};
			$data_info->regist_metric($host, 'AIX', $lc_metric, $header);
			$data_info->simple_report("${lc_metric}.txt", $results->{$metric}, $header);
		# 横持データ
		} else {
			for my $device(keys %{$results->{$metric}}) {
				my @header;
				for my $cat(keys %{$device_headers{$metric}}) {
					if (defined($headers{$cat})) {
						push(@header, @{$headers{$cat}});
					} else {
						push(@header, $cat);
					}
				}
				$data_info->regist_device($host, 'AIX', $lc_metric, $device, undef, \@header);
				my $output_file = "device/${lc_metric}__$device.txt";
				$data_info->pivot_report($output_file, $results->{$metric}{$device}, \@header);
			}
		}
	}

	$data_info->regist_node($host, 'AIX', 'info/nmon', \%info);
}

sub parse {
    my ($self, $data_info) = @_;
	# 短周期のnmon ログ集計にスイッチするため、既存のnmonログ集計をスキップ。
	return 1;

	my %results;
	my $step = 5;
#	my @headers = qw/col1 col2 col3/;

	$data_info->step($step);
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
#	$data_info->skip_header( $in );
	# yisvdb01_160511_2300.nmon
	while (my $nmon_file = <$in>) {
		$nmon_file=~s/(\r|\n)*//g;			# trim return code
		parse_nmon($self, $data_info, $nmon_file, \%results);
	}
	close($in);
#	$data_info->regist_metric($host, 'AIX', 'list_nmon_hourly', \@headers);
#	$data_info->simple_report('list_nmon_hourly.txt', \%results, \@headers);
	return 1;
}

1;
