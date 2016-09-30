Zabbix監視登録
==============

使用方法
--------

Zabbixリポジトリデータベースにノード定義(/node)下の監視対象を登録します。

::

    Usage : zabbix-cli
            [--hosts={hostsfile}] [--add|--rm|--info] {./node/{domain}/{node}}

指定したノード定義からZabbixに以下を登録します。

-  ホストグループ
-  テンプレート
-  ホスト

.hosts ファイルの作成
---------------------

zabbix-cli は監視対象のIPアドレスをZabbixに登録します。DNSなどで監視対象の名前からIPアドレスを引き当てられない場合は、サイトホームディレクトリ下に
.hosts ファイルに、IPアドレスの登録が必要となります。IP,監視対象名の順で.hostsファイルにIPアドレスを登録してください。

::

    cd ~/work/site1
    vi .hosts

    XXX.XXX.XX.XX   {監視対象}

.. note::

  * 監視対象名について

    .hosts に記述する監視対象名はノード定義パスの監視対象ディレクトリ名と同じにしてください。ノード定義パスの監視対象ディレクトリ名は実際のホスト名から以下の変換をしています。

    -  大文字は小文字に変換
    -  ドメインのサフィックス部分を取り除く(.your-company.co.jpなど)

オプション
----------

zabbix-cli コマンドは以下のルールで Zabbix　リポジトリデータベースに監視対象を登録します。

1. 監視対象ノードが登録済みの場合は以下処理をキャンセルします。
2. 以下のルールで Zabbix の **ホストグループ** を登録します。登録済みの場合は処理をスキップします。

   -  ドメインが 'Linux', 'Windows', 'Solaris' など OS名の場合は、後ろに ' Servers' を付ける

      例 : Linux Servers, Windows Servers

   -  ノードパスが登録されている場合は、'{ノードパス} - {ドメイン}'　をホストグループに追加

      例 : DB - Linux

   -  マルチサイトが有効化されている場合は、先頭に '{サイトキー} - '　を付ける

      例 : site1 - Linux Servers

3. 以下のルールで Zabbixの **テンプレート** を登録します。登録済みの場合は処理をスキップします。

   -  ドメインが 'Linux', 'Windows', 'Solaris' など OS名の場合は、先頭に 'Template OS 'を付ける

      例 : Template OS Linux, Template OS Windows

   -  ノードパスが登録されている場合は、'{ノードパス} - {ドメイン}'を登録し、'{ドメイン}' のテンプレートをリンク(継承)させる

      例 : Template OS Linux　- DB(link)

   -  マルチサイトが有効化されている場合は、先頭に '{サイトキー} - 'を付ける

      例 : site1 - Template OS Linux

4. ホストを登録します。
5. 2,3 で登録したホストグループとテンプレートをホストに所属させます。

2, 3 は複雑なルールとなりますが、Zabbix　の既定のホストグループ、テンプレートと整合を保たせるための動作となります。定義情報を確認するコマンドを例に各動作を説明します。
はじめにサイトホームディレクトリに移動します。

::

    cd ~/work/site1

--info {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~~~

Zabbix への登録情報の確認をします。実際の登録はしません。--add　オプションに変えることによりZabbixへ登録します。

例： Linux 監視対象の Zabbix 登録情報確認

::

    zabbix-cli --info ./node/Linux/{監視対象}/

    # groups と templates は以下となります。

       "groups" : [
          "Linux Servers"
       ],
       "templates" : [
          "Template OS Linux"
       ]

例 : ノードパス(DB)が追加された場合の情報確認

node/Linux/{監視対象}/info/cpu.json ファイルに "node_path"　を定義します。

::

    vi node/Linux/{監視対象}/info/cpu.json

        "node_path": "DB/{監視対象}",

    zabbix-cli --info ./node/Linux/{監視対象}/

    # groups と templates は以下となります。

       "groups" : [
          "Linux Servers",
          "DB - Linux"
       ],
       "templates" : [
          "Template OS Linux",
          "Template OS Linux - DB(link)"
       ]

例 : Zabbix のマルチサイトが有効の場合の情報確認

getperf_zabbix.json の USE_ZABBIX_MULTI_SIZE を 1 にします。

::

    vi $GETPERF_HOME/config/getperf_zabbix.json

            "USE_ZABBIX_MULTI_SIZE": 1,

    zabbix-cli --info ./node/Linux/{監視対象}/

    # groups と templates は以下となります。

       "groups" : [
          "Linux Servers",
          "{サイトキー} - DB - Linux"
       ],
       "templates" : [
          "Template OS Linux",
          "Template OS Linux - {サイトキー} - DB(link)"
       ]

--add {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~~

指定したノード定義パスを Zabbix へ登録します。

--rm {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~

指定したノード定義パスを削除します。
