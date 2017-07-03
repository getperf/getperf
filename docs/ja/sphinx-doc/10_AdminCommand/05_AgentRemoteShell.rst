エージェントのリモートシェル
============================

使用方法
--------

nodeconfig
コマンドを用いてリモートで監視対象の操作を行います。操作可能な監視対象は、ssh　経由でのアクセスが可能な Linux, UNIX サーバのみです。サイトホームディレクトリに移動し、コマンドを実行します。

リモート操作監視対象の登録例

::

    nodeconfig　--add=node/Linux/test1 --user=psadmin --pass=pass \
    --home=/home/psadmin

監視対象のリモート操作例

::

    nodeconfig --rex=node/Linux/test1 upload \
    --file=getperf-CentOS6-x86_64.tar.gz

ホスト名の名前解決が出来ない場合、予め IP アドレスを .hosts　ファイルに登録する必要が有ります。
リモート操作は `Rex <https://www.rexify.org/>`_ を使用します。サイトホームディレクトリに移動して、'rex -T'　と実行すると実行可能なタスクリストを表示します。

事前準備
--------

監視対象のssh接続設定
~~~~~~~~~~~~~~~~~~~~~

監視対象のsshログインユーザ、パスワード、ptuneホームディレクトリを登録します。リモート操作が必要なすべての監視対象のサーバで登録が必要です。

例: ssh接続ユーザ、パスワードの登録

はじめにサイトディレクトリに移動します。

::

    cd ~/work/site1
    nodeconfig --add=./node/Linux/{監視対象}/ \
        --user={OSユーザ} \
        --pass={OSパスワード} \
        --home={ptuneホームディレクトリ}

登録情報は、node/Linux/{監視対処}/info/ssh.json に記録されます。

監視対象のノードパスディレクトリ設定
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--node\_dir={ノードパスディレクトリ}
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

監視対象のノードパスディレクトリを登録します。

::

    nodeconfig --add=./node/Linux/{監視対象}/ --node_dir={パス}

登録情報は、node/Linux/{監視対処}/info/node\_info.json に記録されます。

例 : ノードパス定義 node/Linux/{監視対象}/info/node\_path.json

::

    {
       "node_path" : "{パス}/{監視対象}"
    }

オプション
----------

--rex={ノード定義パス} {タスク}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

監視対象で　Rex タスクを実行します。

確認コマンドの実行
^^^^^^^^^^^^^^^^^^

例: uptime コマンドの実行

::

    nodeconfig --rex=./node/Linux/ uptime

例: ディスク容量確認コマンドの実行

::

    nodeconfig --rex=./node/Linux/ disk_free

監視対象のGetperf エージェントの起動/停止
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

例: Getperf エージェントの停止

::

    nodeconfig --rex=./node/Linux/ agent_stop

例: Getperf エージェントの起動

::

    nodeconfig --rex=./node/Linux/ agent_start

例: Getperf エージェントの再起動

::

    nodeconfig --rex=./node/Linux/ agent_restart

監視対象の Zabbix エージェントの起動/停止
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

例: Zabbix エージェントの停止

::

    nodeconfig --rex=./node/Linux/ stop_zabbix_agent

例: Zabbix エージェントの起動

::

    nodeconfig --rex=./node/Linux/ start_zabbix_agent

監視対象の Getperf エージェント設定ファイルのバックアップ
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Getperfエージェント設定ファイルのバックアップ。監視対象で、ptune　ホームディレクトリ下の設定ファイル一式を、 /tmp/getperf_config.tar.gz　にアーカイブします。

::

    nodeconfig --rex=./node/Linux/ backup_agent

監視対象のファイルのアップロード
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

--file
オプションで指定したファイルを監視対象のptuneホームディレクトリにアップロードします。アップロード先は以下の通り　Rex タスクを変えます。

-  upload (ptune ホーム下にアップロードします)
-  upload_bin (ptune ホーム下の bin の下にアップロードします)
-  upload_conf (ptune ホーム下の conf の下にアップロードします)
-  upload_script (ptune ホーム下の script の下にアップロードします)

例: ptune ホームディレクトリへのアップロード

::

    touch Readme.txt
    nodeconfig --rex=./node/Linux/　upload　--file=Readme.txt

例: Getperf エージェントの Linux 設定ファイルのアップロード

::

    nodeconfig --rex=./node/Linux/　\
        upload_conf　\
        --file=lib/agent/Linux/conf/HW.ini
