Windowsサーバ監視設定
===========

Windows サーバのCacti, Zabbix監視設定をします。
コミュニティ版Getperfを用いた標準的な設定手順となり、以下の順に設定を行います。

* Windowsサーバにエージェント監視設定
* Cactiグラフ設定
* Zabbixホスト登録

Windows サーバ構成確認
-------------

監視対象の Windows サーバについて以下の情報を事前に確認します。

* サーバIPアドレス
* administratorパスワード
* 監視サーバのIPアドレス、サイトキー、アクセスキー

   .. note:: 監視サーバのサイトキー、アクセスキーはサイトホームディレクトリの 'site_info.txt' に記載されています。

.. note:: note



エージェントのセットアップ
-------------

監視対象の Windows サーバに administrator ユーザでリモートデスクトップ接続します。

エージェントモジュールの配布
^^^^^^^^^^^^^^

監視サーバからエージェントモジュールアーカイブをホームディレクトリ下にダウンロードします。
ダウンロードサイトから該当するOS、アーキテクチャのモジュールをダウンロードします。
以下は、Oracle Windowsサーバ、64bit 版のダウンロード例となります。

::

   scp psadmin@{監視サーバ}:~/getperf/var/agent/getperf-zabbix-Build6-OracleServer6-x86_64.tar.gz .

各OS/アーキテクチャと、該当するアーカイブファイルは以下の通りです。

+---------------------+---------------------------------------------+
| OS / アーキテクチャ | モジュール                                  |
+=====================+=============================================+
| RHEL5系 / 32 bit    | getperf-zabbix-Build5-CentOS5-i386.tar.gz   |
+---------------------+---------------------------------------------+
| RHEL5系 / 64 bit    | getperf-zabbix-Build5-CentOS5-x86_64.tar.gz |
+---------------------+---------------------------------------------+
| RHEL6系 / 32 bit    | getperf-zabbix-Build5-CentOS6-i386.tar.gz   |
+---------------------+---------------------------------------------+
| RHEL6系 / 64 bit    | getperf-zabbix-Build5-CentOS6-x86_64.tar.gz |
+---------------------+---------------------------------------------+

アーカイブを解凍します。

::

   tar xvf getperf-zabbix-Build6-OracleServer6-x86_64.tar.gz 

解凍すると、ホームディレクトリ下に ptune というディレクトリが作成されます。
本ディレクトリ下で、収集デーモンの起動、採取データの蓄積、転送を行います。

Getperfエージェントのセットアップ
^^^^^^^^^^^^^^^^^^^^

エージェントのセットアップコマンドを実行し、サーバの登録をします。
ptune/bin ディレクトリに移動します。

::
   
   cd ptune/bin

エージェントセットアップコマンドを実行します。

::

   ./getperfctl setup --url=https://{監視サーバ}:57443/

URLの箇所は各サイトのサイト管理用URLを指定してください。
コマンド実行後、各サイトのサイトキーアクセスキーを入力してください。

実行例は以下の通りです。

.. code-block:: bash

   ./getperfctl setup
   /home/psadmin/ptune/network/License.txt : No such file or directory
   SSLライセンスファイルの初期化をします
   サイトキーを入力して下さい :xxx
   アクセスキーを入力して下さい :xxx
   ホストの登録情報がありませんでした。登録を開始します
   以下のホスト情報を 'https://xxx.xxx.xxx.xxx:57443/axis2/services/GetperfService' に送信し、ホストを登録します
   SITEKEY : xxx
   HOST    : paas
   OSNAME  : CentOS

   ホストを登録します。よろしいですか(y/n) ?:y
   /home/psadmin/ptune 下の構成ファイルを /home/psadmin/ptune/_bk にバックアップしました
   構成ファイル [network] を更新しました

.. note:: 既に登録済みのサーバを再登録する場合、一旦、ptune/network/Lincese.txt ファイルを削除してから実行してください。

startコマンドでエージェントを起動します。

::

   ./getperfctl start

"ps -ef | grep _getperf" コマンドで、_getperf プロセスがある事を確認します。

.. note:: プロセスが起動されていない場合は、~/ptune/_log/getperf.log からエラーの内容を確認してください。

Zabbixエージェントのセットアップ
^^^^^^^^^^^^^^^^^^^

監視用ユーザで ~/ptune/script/zabbix/update_config.sh を実行します。
以下スクリプトでZabbixエージェントの設定ファイル ~/ptune/zabbix_agentd.conf を作成します。

::

   ~/ptune/script/zabbix/update_config.sh

エージェントを起動します。

::

   ~/ptune/bin/zabbixagent start

"ps -ef | grep zabbix" コマンドで、zabbix プロセスがある事を確認します。

.. note:: プロセスが起動されていない場合は、/tmp/zabbix_agentd.log からエラーの内容を確認してください。

サービス起動設定
^^^^^^^^

以下の作業は root で実行します。root の使用許可がない場合は、ユーザに以下作業を依頼してください。

::

   su -
   perl (監視用ユーザホーム)/ptune/bin/install.pl --all

実行例は以下の通りです。

::

   Startup script : /etc/init.d/getperfagent,/etc/init.d/zabbixagent
   Agent home     : /home/psadmin/ptune
   Owner          : psadmin
   OK ?(y/n) [n] y

以上で、エージェントの設定作業は終了です。extiコマンドでログアウトしてください。

採取データの集計確認
---------

各サイトの監視サーバに psadmin ユーザでssh接続し、サイトホームディレクトリに移動します。

::

   ssh -l psadmin {監視サーバ}
   cd /home/psadmin/{サイトキー}

各サイトの接続情報、サイトホーム情報は以下の通りです。

以下コマンドで登録したサーバのノード定義情報を確認します。

::

   find node/Windows/{サーバ名}

.. note:: ノード定義ファイルが存在しない場合は、"sumup status"コマンドでデータ集計デーモンが起動されているか確認してください。
   また、/usr/local/tomcat-data/logs の下のTomcat Webサービスログにエラーがないか確認してください。

ノード定義ファイルにノードパス node_path パラメータがあるか確認してください。
値が、"{システム名}/{サーバ名}" となっていることを確認します。

::

   grep node_path node/Windows/{サーバ名}/info/os.json
   node/Windows/{サーバ名}/info/os.json:   "node_path" : "/tantai/{サーバ名}"

ない場合は、Cacti 、Zabbix 登録時に手動で node_path を指定します。
以降の手順では手動での指定手順を記します。
若しくは、後のセクションのマスター定義スクリプトの編集をし、新サーバのマスター登録をします。

Cactiグラフ設定
^^^^^^^^^^

以下コマンドで、Cactiサイトのグラフ登録をします。

::

   cacti-cli node/Windows/{監視サーバ}/ --node-dir {ノードディレクトリ}

ノードディレクトリには、ディレクトリ形式でシステム名、用途などを指定してください。例：'/ASystem/DB'
WebブラウザからCactiサイトに接続して、グラフが登録されていることを確認します。
メニュー _default -> HW -> {システム名} の下に、各HWリソースのグラフが配置されていることを確認します。

.. note::

   cacti-cli コマンドは幾つかのオプションの指定があり、主なオプション指定方法を以下に記します。

   * グラフを上書き更新する場合

      ::

         cacti-cli node/Windows/{監視サーバ}/ -f # -fオプションを追加

   * ツリーメニューの更新をしない場合

      既に登録済みのグラフでグラフのツリーメニュー配置を変えたくない場合は-f --skip-treeオプションを追加します。

      ::

         cacti-cli node/Windows/{監視サーバ}/ -f --skip-tree

   * 複数サーバの登録でサーバ名でソートしたい場合

      指定したオプションでサーバ名をソートして順にグラフ登録をします。
      デフォルトは登録日付順(timestamp)となります。

      ::

         cacti-cli node/Windows/ --view-sort natural

   * 複数デバイスの登録で配置をソートしたい場合

      指定したオプションでデバイス名をソートして順にグラフ登録をします。デフォルトは登録順(none)となります。

      ::

         cacti-cli node/Windows/{監視サーバ}/device/iostat.json --device-sort natural

Zabbixホスト設定
^^^^^^^^^^^

zabbix-cli コマンドで、Zabbixサイトのホスト登録をします。

.. note:: 前セクションのCactiグラフ登録と同様に、サイトホームディレクトリ下で実行します。

初めに.hosts ファイルに登録するサーバのIPアドレスを登録します。
"{IPアドレス} {監視サーバ名}" の形式で登録します。

::

   echo "192.168.10.1 {監視サーバ}" >> .hosts

zabbix-cli --info コマンドで登録情報を確認します。

::

   zabbix-cli --info node/Windows/{監視サーバ}/ --node-dir {ノードディレクトリ}

以下例の様に登録情報が出力されます。

.. code-block:: perl

   host => {
     'interfaces' => [                         # インターフェース情報
       {
         'dns' => '',
         'useip' => 1,
         'ip' => '192.168.10.1',
         'type' => 1,
         'port' => '10050',
         'main' => 1
       }
     ],
     'ip' => '192.168.10.1',                   # ホスト情報
     'host_name' => '{監視サーバ}',
     'is_physical_device' => 1,
     'host_visible_name' => 'Windows - {監視サーバ}',
     'host_groups' => [                         # ホストグループ情報
       'Windows Servers',
       'Windows Servers tantai'
     ],
     'templates' => [                           # テンプレート情報
       'Template OS Windows',
       'Template OS Windows tantai'
     ]
   };

ホストグループは 'Windows Server' と末尾にシステム名が付いた2グループに所属させます。
ホストグループがない場合は新規にホストグループを作成します。
テンプレートは以下の2つのテンプレートを適用します。

* Windows標準テンプレートの 'Template OS Windows'
* 'Template OS Windows' の末尾にシステム名が付いたテンプレート。システム固有の監視設定は本テンプレートに設定します。

zabbix-cli --add コマンドでZabbixに登録します。

::

   zabbix-cli --add node/Windows/{監視サーバ}/ --node-dir {ノードディレクトリ}


WebブラウザからZabbixサイトに接続して、ホスト登録されていることを確認します。

Zabbix Windows テンプレートのカスタマイズ
^^^^^^^^^^^^^^
.. note:: 既にZabbixのWindowsテンプレートをカスタマイズ済みの場合は以下作業は不要です。

Zabbix 標準の 'Template OS Windows' テンプレートには syslog 監視が有りません。
テンプレートに以下を設定をして syslog 監視を追加します。

**Syslog アイテム、トリガーの登録**

1. テンプレートメニューを選択して、リストから 'Template OS Windows' を選択します
2. Itemsを選択します
3. Create Item をクリックして以下のアイテムを登録します

   +-------------+------------------------------------------------+
   | Item        | Value                                          |
   +=============+================================================+
   | Name        | System log                                     |
   +-------------+------------------------------------------------+
   | Type        | Zabbix Agent(active)                           |
   +-------------+------------------------------------------------+
   | Key         | log[/var/log/messages, (error|critical|fatal)] |
   +-------------+------------------------------------------------+
   | Type        | log                                            |
   +-------------+------------------------------------------------+
   | Application | OS                                             |
   +-------------+------------------------------------------------+

4. Triggers メニューを選択して、Create Trigger をクリックして以下のトリガーを登録します

   +------------+----------------------------------------------------------------------------------------------------+
   | Item       | Value                                                                                              |
   +============+====================================================================================================+
   | Name       | SystemLog Error                                                                                    |
   +------------+----------------------------------------------------------------------------------------------------+
   | Expression | {Template OS Windows:log[/var/log/messages, (error|critical|fatal)].iregexp(error|critical|fatal)}=1 |
   +------------+----------------------------------------------------------------------------------------------------+
   | Severity   | Average                                                                                            |
   +------------+----------------------------------------------------------------------------------------------------+

マスター定義スクリプトの編集
^^^^^^^^^^^^^^

.. note:: 

   監視対象サーバのノードディレクトリの識別を自動で行いたい場合は以下のマスター定義スクリプトを編集します。
   各Cacti, Zabbix 管理コマンドに --node-dir オプションを追加して、手動でノードディレクトリを追加する場合は、
   以下設定は不要です。

サイトディレクトリに移動し、マスター定義スクリプトを編集します。

::

   cd {サイトディレクトリ}
   vi lib/Getperf/Command/Site/HW/Master/Server.pm

本スクリプト内の get_system_by_node() 関数を編集します。
if文の文字列検索ででそのホスト名がどのシステムに属するかを記述しています。
文字列検索の条件を追加して、該当サーバ名の検索条件を追加してください。

.. code-block:: perl

   sub get_system_by_node {
      my ($host) = @_;
      $host = lc($host);
      my $system = 'UNKOWN';
      if ($host=~/^(yaqdb\d+|yaqts\d+)/) {
         <中略>
      }
   }

手動で受信データのデータ集計を実行し、マスター定義スクリプトを実行します。
サーバ名、日付、時刻ディレクトリの箇所は適宜修正してください。
ファイル名は、os_info.txt となります。

::

   sumup analysis/{監視サーバ}/SystemInfo/20160901/080000/os_info.txt

以下コマンドで登録したサーバのノード定義情報を確認します。

::

   grep node_path node/Windows/{サーバ名}/info/os.json

設定を反映させるため、データ集計デーモンを再起動します。

::

   sumup restat
