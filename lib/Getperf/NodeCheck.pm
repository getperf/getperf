use strict;
use warnings;
package Getperf::NodeCheck;

# Cacti 集計処理の更新チェックスクリプト
#
# ノード定義ファイルのタイムスタンプを読んで、当日の更新有無をチェックする
#
# 注意
# Perl ライブラリ List::Util のインストールが必要
# sudo -E cpanm List::Util

# 使用例

## サイトディレクトリに移動
# cd ~/kit1
## 詳細の更新チェック
# check_node --detail --append

# 実行オプション

# 	Usage : check_node: 
# 		[--detail] 
# 		[--append-log] 
# 		[--config=[.node_config.pl]] 
# 		[--config-delay-limit=[.delay_limit.pl]]

use Cwd;
use FindBin;
use Getopt::Long;
use Time::HiRes  qw( usleep gettimeofday tv_interval );
use Path::Class;
use List::Util;
use Time::Piece;
use Time::Seconds;
use Getperf::Config 'config';
use Getperf::Data::SiteInfo;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";

sub new {
	my ($class, $sitekey) = @_;
	config('base')->add_screen_log;

	if  (!$sitekey) {
		if (my $site_home_dir = dir($ENV{'SITEHOME'})) {
			$sitekey = pop(@{$site_home_dir->{dirs}});
		}
		die "Invalid 'SITEHOME' env." if (!$sitekey);
	}
	my $site_info   = Getperf::Data::SiteInfo->instance($sitekey);
	my $site_home   = $site_info->{home};
	my $node_config = "$site_home/.node_config.pl";
	my $delay_limit = "$site_home/.delay_limit.pl";
	# my $logging     = init_log($site_info, 'node_check.log');
	bless {
		sitekey       => $sitekey,
		site          => $site_info,
		node_config   => $node_config,
		delay_limit   => $delay_limit,
		node_dir      => $site_info->{node},
		log_dir       => $site_info->{storage},
		append_log    => 0,
		detail        => 0,
	}, $class;
}

sub init_log {
	my ($self) = @_;

	my $log_name = 'node_check.log';
	if ($self->{detail}) {
		$log_name = 'node_check_detail.log';
	}
	my $log_path = $self->{log_dir} . '/' . $log_name;
	if (-f $log_path) {
		unlink($log_path);
	}
	my $logging = Log::Handler->new();
	$logging->add(file => +{
		# logFileMode    => '>', 
		filename       => $log_path,
		permissions    => "0664",
		timeformat     => "%Y/%m/%d %H:%M:%S",
		message_layout => "%T [%L] %m",
		maxlevel       => 'notice',
	});
	$self->{logging} = $logging;
	return $logging;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = "Usage : check_node: " .
				"[--detail] " .
				"[--append-log] " .
				"[--config=[.node_config.pl]] " .
				"[--config-delay-limit=[.delay_limit.pl]] \n";

	my ($status_on, $status_off, $show_status, $lastzip, $ziplist);
	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--config=s'             => \$self->{node_config},
		'--config-delay-limit=s' => \$self->{delay_limit},
		'--detail'               => \$self->{detail},
		'--append-log'           => \$self->{append_log},
	) || die $usage;
	return 1;
}

sub write_node_config {
	my ($self) = @_;

	my $config_file = file($self->{node_config});
	my $writer = file($config_file)->open('w') || die "$! : $config_file";
	my $buf = <<'EOS';
# Cacti集計処理の更新チェック設定ファイル
use utf8;
{
	# 更新チェック除外リスト
	# 除外するには、nodeディレクトリ下の対象プラットフォーム、ノードを
	# 直接削除するか、本除外リストに登録をする
	WhiteList => {
		# 更新チェックを除外するプラットフォーム
		Platform => [
			# 'Db2',
		],
		# 更新チェックを除外するノード
		# 正規表現の利用する場合は、'centos7\.+'など、Perl の正規表現を記述
		Node => {
			Linux => [
				# 'testhost1',
			],
			Oracle => [
				# 'ORATEST1',
			],
		}
	}
}
EOS
	$writer->print($buf);
	$writer->close;
	return 1;
}

sub write_delay_limit {
	my ($self) = @_;

	my $config_file = file($self->{delay_limit});
	my $writer = file($config_file)->open('w') || die "$! : $config_file";
	my $buf = <<'EOS';
# Cacti集計処理の更新チェック詳細設定ファイル
use utf8;
{
	# 更新遅れの許容時間、指定時間以上の遅れが発生した場合にアラーム通知する
	DelayLimit => {
		Platform => {
			Linux => 1,
			Solaris => 1,
			Windows => 1,
			Jvmstat => 1,
			Oracle => 3,
			AIX => 3,
		},
		Default => 24,
	},
}
EOS
	$writer->print($buf);
	$writer->close;
	return 1;
}

sub extract_node_list_timestamps {
	my ($self) = @_;
	my $node_dir = $self->{node_dir};

	my $cmd = "find ${node_dir} -name \"*.json\"";
	my $results;
	open (my $in, "$cmd |") || die "$!";
	while (my $node_file = <$in>) {
		chomp($node_file);
		my @filestat = stat $node_file;
		my $mtime = $filestat[9];
		if ($node_file=~m|$node_dir/(.+)$|) {
			$node_file = $1;
		}
		my ($platform, $host, @paths) = split(/\//, $node_file);
		my $fname = pop(@paths);
		$results->{$platform}{$host}{$fname} = $mtime;
	}
	return $results;
}

sub prepare_node_check_config {
	my ($self) = @_;
	my $node_config = $self->{node_config};
	if (!-f $node_config) {
		$self->write_node_config();
	}
	my $config = do $node_config or die "$!$@ : $node_config";

	my $delay_limit = $self->{delay_limit};
	if (!-f $delay_limit) {
		$self->write_delay_limit();
	}
	my $config2 = do $delay_limit or die "$!$@ : $delay_limit";
	%{$config} = (%{$config}, %{$config2});
	# print Dumper $config; exit;

	my $wlists = $config->{WhiteList};
	my %wlist_platforms = ();
	for my $platform(@{$wlists->{Platform}}) {
		$wlist_platforms{$platform} = 1;
	}
	# print Dumper \%wlist_platforms;
	$self->{wlist_platforms} = \%wlist_platforms;

	my %wlist_nodes = ();
	for my $platform(keys %{$wlists->{Node}}) {
		for my $node(@{$wlists->{Node}{$platform}}) {
			$wlist_nodes{$platform}{$node} = 1;
		}
	}
	# print Dumper \%wlist_nodes;
	$self->{wlist_nodes} = \%wlist_nodes;

	return $config;
}

sub check_wlist_platform {
	my ($self, $platform) = @_;
	if (!$self->{wlist_platforms}) {
		return;
	}
	return $self->{wlist_platforms}{$platform};
}

sub check_wlist_node {
	my ($self, $platform, $node) = @_;
	if (my $wlist_nodes = $self->{wlist_nodes}{$platform}) {
		my $checked = 0;
		for my $wlist_node(keys %{$wlist_nodes}) {
			$wlist_node = "^" . $wlist_node . "\$";
			if ($node =~/${wlist_node}/) {
				$checked = 1;
			}
		}
		return $checked;
	}
	return;
}

sub check_node_updated_detail {
	my ($self, $results, $config) = @_;
	my $logging = $self->{logging};
	my $current = POSIX::strftime("%y/%m/%d", localtime());
	my $node_count = 0;
	my $error_count = 0;


	my $default_delay_limit = $config->{DelayLimit}{Default};
	$default_delay_limit = 1 if (!$default_delay_limit);

	for my $platform(keys %{$results}) {
		my $delay_limit = $config->{DelayLimit}{Platform}{$platform};
		$delay_limit = $default_delay_limit if (!$delay_limit);
		my $limit_time = (localtime) - ONE_HOUR * $delay_limit;
		my $limit_itme_str = $limit_time->strftime("%y/%m/%d %H:%M:%S");
		print "LIMIT: ${limit_itme_str}\n";
		if ($self->check_wlist_platform($platform)) {
			$logging->info("skip white list platform ${platform}");
			next;
		}
		for my $node(keys %{$results->{$platform}}) {
			if ($self->check_wlist_node($platform, $node)) {
				$logging->info("skip white list node ${platform}/${node}");
				next;
			}
			my $not_update = 0;
			for my $fname(keys %{$results->{$platform}{$node}}) {
				my $mtime = $results->{$platform}{$node}{$fname};
				my $mtime_str = POSIX::strftime("%y/%m/%d %H:%M:%S", localtime($mtime));
				if ($mtime < $limit_time) {
					$not_update = 1;
					$logging->error("$platform,$node,$fname update is delayed : ${mtime_str}");
				}
			}
			$node_count ++;
			if ($not_update) {
				$error_count ++;
			}
		}
	}
	my $error_rate = 100.0 * $error_count / $node_count;
	my $message = sprintf("total node : %d, delayed : %d, error rate : %0.4f %%", 
			$node_count,
			$error_count,
			$error_rate);
	$logging->notice($message);
}

sub check_node_updated {
	my ($self, $results, $config) = @_;
	my $logging = $self->{logging};
	my $current = POSIX::strftime("%y/%m/%d", localtime());
	my $node_count = 0;
	my $error_count = 0;
	for my $platform(keys %{$results}) {
		if ($self->check_wlist_platform($platform)) {
			$logging->info("skip white list platform ${platform}");
			next;
		}
		for my $node(keys %{$results->{$platform}}) {
			if ($self->check_wlist_node($platform, $node)) {
				$logging->info("skip white list node ${platform}/${node}");
				next;
			}
			my @mtimes = ();
			for my $fname(keys %{$results->{$platform}{$node}}) {
				my $mtime = $results->{$platform}{$node}{$fname};
				push @mtimes, $mtime;
			}
			my $mtime_min = List::Util::min(@mtimes);
			my $mtime_max = List::Util::max(@mtimes);
			my $mtime_min_str = POSIX::strftime("%y/%m/%d %H:%M:%S", localtime($mtime_min));
			my $mtime_max_str = POSIX::strftime("%y/%m/%d %H:%M:%S", localtime($mtime_max));
			my $not_update = 1;
			if ($mtime_min_str =~/$current/ || $mtime_max_str =~/$current/) {
				$not_update = 0;
			}
			$node_count ++;
			if ($not_update) {
				$error_count ++;
				$logging->error("$platform,$node update is delayed, oldest : ${mtime_min_str}, latest : ${mtime_max_str}");
			}
		}
	}
	my $error_rate = 100.0 * $error_count / $node_count;
	my $message = sprintf("total node : %d, delayed : %d, error rate : %0.4f %%", 
			$node_count,
			$error_count,
			$error_rate);
	$logging->notice($message);
}

sub run {
	my ($self) = @_;

	$self->init_log();
	my $config =$self->prepare_node_check_config();
	my $results = $self->extract_node_list_timestamps();
	# print Dumper $config;
	if ($self->{detail}) {
		$self->check_node_updated_detail($results, $config);
	}else {
		$self->check_node_updated($results, $config);
	}
}

1;
