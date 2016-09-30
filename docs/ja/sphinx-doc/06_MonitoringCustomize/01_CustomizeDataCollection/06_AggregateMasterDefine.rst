集計定義マスター
================

集計スクリプトでサイト固有の定義は集計定義マスターにまとめ、汎用的な集計処理とサイト固有の情報を分離します。そのディレクトリ構成は以下の通りです。

ディレクトリ構成
--------------------------

* lib/Command/Site/{ドメイン}/tt_Master.pm

  ドメインの集計定義マスターテンプレート。初回の集計処理で本ファイルを集計定義マスターとして登録します。

* lib/Command/Site/{ドメイン}/{メトリック}.pm

  各メトリックの集計スクリプト。
  集計スクリプトは集計定義マスターのメソッドをコールしてサイト固有の情報を取得します。

* lib/Command/Site/Master/{ドメイン}.pm

  ドメインの集計定義マスター。ドメインのサイト固有の情報は本スクリプトに記述します。

集計定義マスター登録の確認
--------------------------

例として標準ドメインの Linux の集計定義マスターを使用して、動作を確認します。
集計定義マスタは、初回の集計処理で tt_Master.pm をコピーして作成します。
一時的に集計定義マスターを退避して、その動作確認をします。

::

	mv lib/Getperf/Command/Master/Linux.pm \
	   lib/Getperf/Command/Master/Linux.pm.bak

集計定義マスターがない状態で、集計処理を実行します。

::

	sumup analysis/{監視対象}/Linux/{日付}/{時刻}/iostat.txt

集計処理の前処理で、以下を対象に集計定義マスターのコピーが実行されます。

::

	コピー元 : lib/Getperf/Command/Site/Linux/tt_Master.pm
	コピー先 : lib/Getperf/Command/Master/Linux.pm

.. note::

	監視対象や採取ファイル(iostat.txt)は任意の値で構いません。
	集計定義マスターが存在ない場合、どの様なファイルでも初回の集計処理で集計定義マスターのコピーが実行されます。

コピーされた集計定義マスターを確認します。

::

	cat lib/Getperf/Command/Master/Linux.pm

集計定義マスターはサイト固有のカスタマイズ処理を記述します。
例えば以下の alias_iostat() メソッドは iostat.txt 集計で集計するデバイスのフィルター処理を記述します。

::

	our @EXPORT = qw/alias_iostat alias_diskutil/;
	(中略)
	sub alias_iostat {
	  my ($host, $device) = @_;
	  if ($device=~/^sd[a-z]$/ || $device=~/^dm-/) {
	    return $device;
	  }
	  return;
	}

alias_iostat() は、以下の iostat.txt 集計処理スクリプトからコールされており、デバイス登録の判別処理に使用します。

::

	more lib/Getperf/Command/Site/Linux/Iostat.pm
	(中略)
	for my $device(keys %results) {
	  my $device_info = alias_iostat($host, $device);
	  if ($device_info) {
	    my $output_file = "device/iostat__${device}.txt";
	    $data_info->regist_device($host, 'Linux', 'iostat', $device,
	                              $device_info, \@headers);
	    $data_info->pivot_report($output_file, $results{$device},
	                             \@headers);
	  }
	}

集計定義マスターの編集
--------------------------

カスタマイズ例として、Linux.pm 集計定義マスターの alias_iostat() メソッドの編集をします。

::

	vi lib/Getperf/Command/Master/Linux.pm

alias_iostat()　メソッド内を以下の通り変更してください。変更により、'sd[a-z]' のデバイスのみを抽出する処理になります。

::

	変更前 : if ($device=~/^sd[a-z]$/ || $device=~/^dm-/) {
	変更後 : if ($device=~/^sd[a-z]$/) {

再度、手動で iostat.txt を集計すると、集計後のノード定義ファイルは以下の通り変更されます。

::

	# 集計定義マスター変更前：
	cat node/Linux/{監視対象}/device/iostat.json
	{
	   "device_texts" : [
	      "sda",
	      "dm-0",
	      "dm-1"
	   ],
	   "devices" : [
	      "sda",
	      "dm-0",
	      "dm-1"
	   ],
	   "rrd" : "Linux/{監視対象}/device/iostat__*.rrd"
	}

::

	# 集計定義マスター変更後：
	cat node/Linux/{監視対象}/device/iostat.json
	{
	   "device_texts" : [
	      "sda"
	   ],
	   "devices" : [
	      "sda"
	   ],
	   "rrd" : "Linux/{監視対象}/device/iostat__*.rrd"
	}
