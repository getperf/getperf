Getperf
=====

Getperf とは
--------

Getperf とはシステム監視の開発フレームワークで以下の特徴があるソフトウェアです。

* システム監視運用には障害対応と問題分析の2つのアプローチがあると考え、それぞれ別のソリューションを提供します。
* 障害対応は、障害の初動対応で、包括的な対応が必要となり、そのソリューションとして [Zabbix](www.zabbix.com) を使用します。
* 問題分析は、障害原因のエスカレーション業務で、分析のソリューションとして、[Cacti](http://www.cacti.net/) を使用します。
* システム監視運用には以下の２つの側面があると考え、それぞれに適したオープンソースを使用し、システム監視を統合します。

|            | イベント監視(Zabbix)       | 傾向監視(Cacti)                    |
| :-------   | :-------------------       | :-----------------------           |
| 手順       | アラートのメール通知       | グラフのモニタリング               |
| アプローチ | 網羅的、包括的なアプローチ | 発見的、運用しながら詳細化         |
|            | サービス管理のプロセス     | 問題管理のプロセス                 |
| 用途       | 障害の初動対応で活用       | 障害の二次解析で活用               |
|            | 既知の問題の対処           | 未知の問題の対処（知的アプローチ） |
| ニーズ     | ロバスト性が必要           | 柔軟な仕組みが必要                 |
|            | 即時性、確実性必要         | アドホックな分析、大量データの分析 |

構成
-------

システム構成は以下となります。

![Getperfシステム構成](docs/ja/sphinx-doc/image/getperf_config.png)

* Getperf エージェント
	- C言語でコーディングされたデータ収集エージェントです。
	- Web サービスとのインターフェースに [gSOAP](http://www.cs.fsu.edu/~engelen/soap.html) を使用します。
	- 内部スケジューラによりコマンドを定期実行し、実行結果(採取データ)を zip に圧縮し、監視サーバに転送します。
* データ受信 Web サービス
	- Java でコーディングされた、データ受信 Web サービスです。
	- Getperf Agent からの収集データを監視サイトに転送します。
* Perl 集計モジュール
	- 採取データの集計に Perl スクリプトを使用します。
    - スクリプトは監視サイト毎にカスタマイズ可能で、運用に合わせて集計方法、メトリックの定義を編集します。
	- 集計データの蓄積は時系列データベースの [RRDTool](http://oss.oetiker.ch/rrdtool/) を使用します。オプションでデータ分析用に[InfluxDB](https://influxdata.com/) を使用します。
* モニタリングフロントエンド
	- グラフモニタリングのフロントエンドに [Cacti](http://www.cacti.net/) を使用します。
    - イベント監視に [Zabbix](http://www.zabbix.com/) を使用します。
    - 定義したメトリックに合わせて、これら M/W の設定を自動化します。

Install
=====

CentOS 6.x 環境のインストール手順を記します。詳細の手順は[インストール](docs/ja/sphinx-doc/03_Installation/index.rst) を参照してください。

注意事項
-------

サーバのインストールは　root での実行依存度が強く、既存環境の設定を壊す恐れがあります。OSをクリアインストールした環境でのインストールを強く推奨します。

事前準備
-------

* インストール環境は、SELinux の無効化した環境が必要になります。
* イントラネット環境で yum コマンド等で外部接続する際に Proxy の設定が必要となります。
* インストール実行ユーザは sudo 実行権限が必要となります。

上記手順は詳細は、[事前準備](docs/ja/sphinx-doc/03_Installation/01_Preparation.rst) を参照してください。

パッケージインストール
---------------

基本パッケージをインストールします

```
sudo -E yum -y groupinstall "Development Tools"
sudo -E yum -y install kernel-devel kernel-headers
sudo -E yum -y install libssh2-devel expat expat-devel libxml2-devel
sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
sudo -E yum -y update
```

Getperf モジュールをダウンロードします

```
git clone https://github.com/getperf/getperf
cd getperf
```

cpanmをインストールします

```
source script/profile.sh
echo source $GETPERF_HOME/script/profile.sh >> ~/.bash_profile
sudo -E yum -y install perl-devel
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
cd $GETPERF_HOME
sudo -E cpanm --installdeps .
```

サーバインストール
-----------

ソフトウェア構成管理ツール [Rex](http://www.rexify.org/) を用いてインストールを行います

設定ファイルを作成します

```
cd $GETPERF_HOME
perl script/cre_config.pl
```

Gitリポジトリのローカルアクセス用のSSH鍵、ルート認証局、中間認証局を作成します

```
rex install_ssh_key
rex create_ca        # ルート認証局作成
rex create_inter_ca  # 中間認証局作成
rex server_cert      # サーバ証明書作成
sudo rex run_client_cert_update # クライアント証明書の定期更新
```

Webサービスをインストールします

```
sudo -E rex install_package   # パッケージインストール
sudo -E rex install_sumupctl  # 集計デーモン起動スクリプト登録
rex prepare_apache            # Apache HTTP サーバインストール
sudo -E rex prepare_tomcat    # Apache Tomcat インストール
rex prepare_tomcat_lib        # Tomcat ライブラリインストール
rex prepare_ws                # Webサービスインストール
sudo -E rex svc_auto          # サービス起動登録
rex svc_start                 # サービス起動
```

MySQLとCactiを設定します

```
rex prepare_mysql     # MySQLパスワード登録
rex prepare_composer  # PHP ライブラリインストール
rex prepare_cacti     # Cacti インストール
```

Zabbix をインストールします

```
sudo -E rex prepare_zabbix
```

エージェントコンパイル
--------------

Linux, Windows, UNIX環境に合わせて、エージェントソースをコンパイルします。ここでは監視サーバ CentOS での手順を記します。
ダウンロード用Webページを設定し、エージェントのソースモジュールを登録します。

```
cd $GETPERF_HOME
sudo -E rex prepare_agent_download_site
rex make_agent_src
```

Webブラウザで、 http://{サーバアドレス}/docs/agent/ を開きソースモジュール "getperf-2.x-Buildx-source.zip"　をダウンロード・解凍をしてコンパイルします。

```
cd /tmp
wget http://{サーバアドレス}/docs/agent/getperf-2.x-Build8-source.zip
unzip getperf-2.x-Build*-source.zip
cd getperf-agent
./configure
make
```

エージェントモジュールをビルドします。

```
perl deploy.pl
```

作成された、 getperf-zabbix-Build?-CentOS6-x86_64.tar.gz がエージェントの配布モジュールのアーカイブとなります。
Windows など他プラットフォームのコンパイルは、[各プラットフォームでのコンパイル](docs/ja/sphinx-doc/03_Installation/10_AgentCompile.rst)を参照してください。

使用方法
=====

サイトの初期化
--------

監視サーバで指定したディレクトリの下にサイトを構築します。 ここでは 'site1' というサイトを作成します。

```
cd (あるディレクトリ)
initsite site1
```

実行メッセージにサイトキー、アクセスキー、Cacti サイトURLが出力されます。
サイトキー、アクセスキーはエージェントのセットアップで使用しますのでメモしておいてください。

作成したサイトの集計デーモンを起動します。

```
cd (あるディレクトリ)/site1
sumup start
```


エージェントセットアップ
--------

ここではLinux環境の設定手順を記します。Windows の場合は、[Windows監視](docs/ja/sphinx-doc/04_Tutorial/03_WindowsResourceMonitoring.rst) を参照してください。
インストールしたエージェントの ptune/bin に移動し、セットアップを実行します。

```
cd $HOME/ptune/bin
./getperfctl setup
```

エージェントの認証の際にサイト初期化で発行されたアクセスキーの入力が必要となります。エージェント認証後、SSL証明書の更新をします。
セットアップが完了したら、エージェントを起動します。

```
./getperfctl start
```

Zabbix エージェント設定ファイル作成スクリプトを実行します。

```
cd $HOME/ptune
./script/zabbix/update_config.sh
./bin/zabbixagent start
```

/etc/init.d/ に自動起動スクリプトを配布します。

```
cd $HOME/ptune/bin
sudo perl install.pl --all
```

グラフの登録
--------

前記で構築したサイトディレクトリに移動し、cacti-cli コマンドを用いてセットアップしたエージェントのグラフ登録をします。

```
cd (サイト保存ディレクトリ)/site1
cacti-cli  node/Linux/{エージェント名}/
```

実行後、Cactiサイトにアクセスし、対象エージェントのCPU利用率などのリソースグラフが作成されていることを確認します。
グラフレイアウトのカスタマイズは、[Cactiグラフ登録](docs/ja/sphinx-doc/07_CactiGraphRegistration/index.rst)を参照してください。

Zabbix監視登録
-------------

Zabbix のホスト登録をします。初めにサイトディレクトリ下の.hostsファイルを編集し、エージェントのIPアドレスを設定します。

```
echo "{IPアドレス} {ホスト名}" >> .hosts
```

zabbix-cli コマンドを用いてZabbixのホスト登録をします。

```
zabbix-cli --add node/Linux/{ホスト名}
```

Refference
-----------

1. [gSOAP](http://www.cs.fsu.edu/~engelen/soap.html)
2. [Apache Axis2/Java](http://axis.apache.org/axis2/java/core/index.html)
3. [Rex](http://www.rexify.org/)
4. [RRDTool](http://oss.oetiker.ch/rrdtool/)
5. [Cacti](http://www.cacti.net/)
6. [Zabbix](http://www.zabbix.com)

AUTHOR
-----------

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
-----------

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
-----------

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
