SNMP ネットワークモニタリングテンプレート
===============================================

SNMP ネットワークモニタリング
-------------------

SNMP 統計を用いてネットワーク機器のパフォーマンス情報を採取します。採取したデータをモニタリングサーバ側で集計してグラフ登録をします。

**注意事項**

1. SNMP統計をリモートで採取する Linux 用エージェントが別途必要で、監視サーバ上で Linux エージェントを稼働します。
2. snmpwalk, snmpget コマンドを使用するため、エージェントに以下 net-snmp パッケージの追加が必要になります。

```
sudo -E yum -y install net-snmp net-snmp-utils
```

ファイル構成
-------

テンプレートに必要な設定ファイルは以下の通りです。

|              ディレクトリ             |        ファイル名        |                  用途                 |
|---------------------------------------|--------------------------|---------------------------------------|
| lib/agent/SNMPNetwork/conf/           | iniファイル              | エージェント採取設定ファイル          |
| lib/Getperf/Command/Site/SNMPNetwork/ | pmファイル               | データ集計スクリプト                  |
| lib/graph/SNMPNetwork/                | jsonファイル             | グラフテンプレート登録ルール          |
| lib/cacti/template/0.8.8g/            | xmlファイル              | Cactiテンプレートエクスポートファイル |
| script/                               | create_graph_template.sh | グラフテンプレート登録スクリプト      |

メトリック
-----------

|          Key           |                             Description                              |
|------------------------|----------------------------------------------------------------------|
| **パフォーマンス統計** | **ネットワーク  I/O 統計パフォーマンス統計グラフ**                   |
| snmp_network_port      | **ポート 別ネットワーク I/O統計**<br>MB/sec / Packet/sec / Error/sec |

Install
=====

テンプレートのビルド
-------------------

Git Hub からプロジェクトをクローンします

	(git clone してプロジェクト複製)

プロジェクトディレクトリに移動して、--template オプション付きでサイトの初期化をします

	cd t_SNMPNetwork
	initsite --template .

Cacti グラフテンプレート作成スクリプトを順に実行します

	./script//create_graph_template_SNMPNetwork.sh

Cacti グラフテンプレートをファイルにエクスポートします

	cacti-cli --export SNMPNetwork

集計スクリプト、グラフ登録ルール、Cactiグラフテンプレートエクスポートファイル一式をアーカイブします

	sumup --export=SNMPNetwork --archive=$GETPERF_HOME/var/template/archive/config-SNMPNetwork.tar.gz

テンプレートのインポート
---------------------

前述で作成した $GETPERF_HOME/var/template/archive/config-SNMPNetwork.tar.gz がSNMPNetworkテンプレートのアーカイブとなり、
監視サイト上で以下のコマンドを用いてインポートします

	cd {モニタリングサイトホーム}
	tar xvf $GETPERF_HOME/var/template/archive/config-SNMPNetwork.tar.gz

Cacti グラフテンプレートをインポートします。監視対象のストレージに合わせてテンプレートをインポートしてください

	cacti-cli --import SNMPNetwork

インポートした集計スクリプトを反映するため、集計デーモンを再起動します

	sumup restart

使用方法
=====

エージェントセットアップ
--------------------

以下のエージェント採取スクリプトを、エージェントの script ディレクトリの下(/home/{OSユーザ}/ptune/script/)にコピーします。

	{サイトホーム}/lib/agent/SNMPNetwork/script/

同様に以下の conf 下の設定ファイルを、(/home/{OSユーザ}/ptune/conf/)にコピーします。

	{サイトホーム}/lib/agent/SNMPNetwork/conf/SNMPNetwork.ini

監視対象のネットワーク機器の構成情報をチェックします。コピーしたスクリプト check_snmp.pl に -p オプションを付けて実行します。

	cd ~/ptune/script
	./check_snmp.pl -p

監視対象機器のSNMP接続情報を入力してください。実行すると、以下の結果ファイルが出力されます。

|   ファイル名    |                              定義                             |
|-----------------|---------------------------------------------------------------|
| check_snmp.yaml | 監視対象ネットワークの構成情報                                |
| check_snmp.cmd  | エージェント設定ファイル SNMPNetwork.ini のコマンド定義ひな形 |

check\_snmp.cmd　の結果を参考にして、 SNMPNetwork.ini を編集してください。 check\_snmp.cmd　は全てのネットワークポートを監視対象としているため、不要なポートを取り除くなど必要に応じて編集してください。

設定内容を反映するため、エージェントを再起動してください。

データ集計のカスタマイズ
--------------------

上記エージェントセットアップ後、データが集計されると、サイトホームディレクトリの lib/Getperf/Command/Master/ の下に SNMPNetworkConfig.pm ファイルが生成されます。
本ファイルは監視対象ネットワークのマスター定義ファイルで、ネットワーク機器、ネットワークポートの用途を記述します。
同ディレクトリ下の SNMPNetworkConfig.pm_sample を例にカスタマイズしてください。

**注意事項**

同様に、SNMPNetwork ドメインのマスター定義ファイル SNMPNetwork.pm が自動生成されますが、本スクリプトはデータ集計スクリプトからのアクセスはありません。
マスターの定義は、上記　SNMPNetworkConfig.pm　を使用して下さい。

グラフ登録
-----------------

上記エージェントセットアップ後、データ集計が実行されると、サイトホームディレクトリの node の下にノード定義ファイルが出力されます。
出力されたファイル若しくはディレクトリを指定してcacti-cli を実行します。

	cacti-cli node/SNMPNetwork/{ネットワークノード}/

AUTHOR
-----------

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
-----------

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
-----------

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
