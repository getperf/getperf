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

エージェントのセットアップ
-------------

監視対象の Windows サーバに administrator ユーザでリモートデスクトップ接続します。

エージェントモジュールの配布
^^^^^^^^^^^^^^

監視サーバからエージェントモジュールアーカイブを C:\\ にダウンロードします。
ダウンロードサイトから該当するOS、アーキテクチャのモジュールをダウンロードします。

Windowsの場合、各OSバージョン/アーキテクチャ共通で以下のアーカイブファイルとなります。

+-------------------------+-------------------------------------------+
| OS / アーキテクチャ     | モジュール                                |
+=========================+===========================================+
| Windows / 32 bit,36 bit | getperf-zabbix-Build4-Windows-MSWin32.zip |
+-------------------------+-------------------------------------------+

スタートアップメニューからコマンドプロンプトを選択し、右クリック管理者権限で起動します。

::

   cd /d c:\

Webブラウザから監視サーバのダウンロードサイトを開きます。

::

   http://{監視サーバアドレス}/docs/download/ 

以下パッケージをc: の直下に保存します。
エクスプローラを開き、 ダウンロードしたパッケージファイルを右クリックして解凍を選択し、解凍先を c:\\ にして解凍してください。

Getperfエージェントのセットアップ
^^^^^^^^^^^^^^^^^^^^

解凍すると、c:\\ptune の下に実行モジュール、各設定ファイルが配置されます。c:\\ptune\\bin に移動し、以下のセットアップコマンドを実行します。

::

    cd \ptune\bin
    .\getperfctl.exe setup --url=https://{監視サーバ}:57443/

サイトキー、アクセスキーを入力し、'更新しますか?' の確認で y を入力して設定を完了します。

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
   HOST    : cat
   OSNAME  : Windows

   ホストを登録します。よろしいですか(y/n) ?:y
   c:\ptune\ptune 下の構成ファイルを c:\ptune\ptune\_bk にバックアップしました
   構成ファイル [network] を更新しました

.. note:: 既に登録済みのサーバを再登録する場合、一旦、c:\\ptune\\network\\Lincese.txt ファイルを削除してから実行してください。


サービス起動の設定をします。
getperfctl install コマンドで Windowsサービスへ Getperf エージェントの登録をします。

::

    .\getperfctl.exe install

Windows サービスから Getperf エージェントの起動をします。

::

   .\getperfctl.exe start

エージェントの起動確認をします。
c:\\ptune\\log の下に採取コマンドの実行結果が保存されるので起動した時刻のディレクトリが生成されているかを確認します。

.. note:: プロセスが起動されていない場合は、c:\\ptune\\_log\\getperf.log からエラーの内容を確認してください。

Zabbixエージェントのセットアップ
^^^^^^^^^^^^^^^^^^^
C:の下の Zabbix エージェント設定ファイル作成スクリプトを実行します。

::

   cd C:\ptune\script\zabbix
   update_config.bat

ptuneの下に zabbix\_agentd.conf ファイルが生成されます。
続けて以下のスクリプトでWindowsサービスの登録を行い、Zabbix エージェントを起動します。

::

   setup_agent.bat

Zabbix エージェントが起動されると、c: の直下に、 zabbix_agent.log が生成されます。
メモ帳などでログを開いて、 'agent # started' というメッセージが出力されてることを確認して起動を確認します。
Windows の場合は、各エージェントのサービス起動設定を合わせて行うので、OS起動時の自動起動設定を別途行う必要はありません。

以上でエージェント設定は完了です。

採取データの集計確認
---------

以降は集計サーバ側の設定を行います。
各サイトの監視サーバに psadmin ユーザでssh接続し、サイトホームディレクトリに移動します。

::

   ssh -l psadmin {監視サーバ}
   cd /home/psadmin/{サイトキー}

以下コマンドで登録したサーバのノード定義情報を確認します。

::

   find node/Windows/{サーバ名}

.. note:: エージェントを起動して5分後に監視サーバに採取データが転送され、データ集計を開始します。
   エージェント起動直後にノード定義ファイルが存在しない場合はしばらく待ってから確認してください。

.. note:: ノード定義ファイルが存在しない場合は、"sumup status"コマンドでデータ集計デーモンが起動されているか確認してください。
   また、/usr/local/tomcat-data/logs の下のTomcat Webサービスログにエラーがないか確認してください。

ノード定義ファイルにノードパス node_path パラメータがあるか確認してください。
値が、"{システム名}/{サーバ名}" となっていることを確認します。

::

   grep node_path node/Windows/{サーバ名}/info/system.json
   node/Windows/{サーバ名}/info/system.json:   "node_path" : "/tantai/{サーバ名}"

ない場合は、Cacti 、Zabbix 登録時に手動で node_path を指定します。
以降の手順では手動での指定手順を記します。
若しくは、後のセクションのマスター定義スクリプトの編集をし、新サーバのマスター登録をします。

Cactiグラフ設定
^^^^^^^^^^

以下コマンドで、Cactiサイトのグラフ登録をします。

::

   cacti-cli node/Windows/{監視サーバ}/ --node-dir {ノードディレクトリ}

ノードディレクトリには、ディレクトリ形式でシステム名、用途などを指定してください。例：'/ASystem/DB'。

WebブラウザからCactiサイトに接続して、グラフが登録されていることを確認します。
メニュー _default -> HW -> {システム名} の下に、各HWリソースのグラフが配置されていることを確認します。

Zabbixホスト設定
^^^^^^^^^^^

zabbix-cli コマンドで、Zabbixサイトのホスト登録をします。

.. note:: 前セクションのCactiグラフ登録と同様に、サイトホームディレクトリ下で実行します。

初めに.hosts ファイルに登録するサーバのIPアドレスを登録します。
"{IPアドレス} {監視サーバ名}" の形式で登録します。

::

   echo "192.168.10.15 {監視サーバ}" >> .hosts

zabbix-cli --info コマンドで登録情報を確認します。

::

   zabbix-cli --info node/Windows/{監視サーバ}/ --node-dir {ノードディレクトリ}

以下例の様に登録情報が出力されます。

.. code-block:: perl

   host => {
     'interfaces' => [
       {
         'dns' => '',
         'useip' => 1,
         'ip' => '192.168.0.15',
         'type' => 1,
         'port' => '10050',
         'main' => 1
       }
     ],
     'ip' => '192.168.0.15',
     'host_name' => 'cat',
     'is_physical_device' => 1,
     'host_visible_name' => 'Windows - cat',
     'host_groups' => [
       'Windows Servers',
       'Windows Servers - aaa'
     ],
     'templates' => [
       'Template OS Windows',
       'Template OS Windows - aaa'
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

   +-------------+------------------------+
   | Item        | Value                  |
   +=============+========================+
   | Name        | System log             |
   +-------------+------------------------+
   | Type        | Zabbix Agent(active)   |
   +-------------+------------------------+
   | Key         | eventlog[system,Error] |
   +-------------+------------------------+
   | Type        | log                    |
   +-------------+------------------------+
   | Application | OS                     |
   +-------------+------------------------+

4. Triggers メニューを選択して、Create Trigger をクリックして以下のトリガーを登録します

   +------------+---------------------------------------------------------------+
   | Item       | Value                                                         |
   +============+===============================================================+
   | Name       | SystemLog Error                                               |
   +------------+---------------------------------------------------------------+
   | Expression | {Template OS Windows:eventlog[system,Error].iregexp(Error)}=1 |
   +------------+---------------------------------------------------------------+
   | Severity   | Average                                                       |
   +------------+---------------------------------------------------------------+

マスター定義スクリプトの編集
^^^^^^^^^^^^^^

.. note:: 

   監視対象サーバのノードディレクトリの識別を自動で行いたい場合は以下のマスター定義スクリプトを編集します。
   各Cacti, Zabbix 管理コマンドに --node-dir オプションを追加して、手動でノードディレクトリを追加する場合は、
   以下設定は不要です。

サイトディレクトリに移動し、マスター定義スクリプトを編集します。

::

   cd {サイトディレクトリ}
   vi lib/Getperf/Command/Master/SystemInfo.pm

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

   sumup -l analysis/{監視サーバ}/SystemInfo/

以下コマンドで登録したサーバのノード定義情報を確認します。

::

   grep node_path node/Windows/{サーバ名}/info/system.json

設定を反映させるため、データ集計デーモンを再起動します。

::

   sumup restat
