Windows 監視
============

Windows のエージェントインストールは administrator　ユーザで行います。
インストール先は任意ですが、ここでは C　ドライブの直下に c:というディレクトリを作成してインストールします。

.. note::

    コマンドプロンプトを用いてセットアップコマンドを実行しますが、サービスの登録で管理者権限が必要なため、 **管理者権限付きコマンドプロンプト** で実行してください。
    管理者権限付きコマンドプロンプトは、Windows　のスタートアップメニューからコマンドプロンプトを選択し、右クリックで管理者権限付きを選択して起動します。

.. note::

    Windows のパッケージは、Windows のバージョン、アーキテクチャ(32bit,64bit)の違いによりパッケージファイルが異なることはありません。
    共通で、Windows-MSWin32　というプラットフォーム名のパッケージを使用してください。

Getperf エージェントセットアップ
--------------------------------

スタートアップメニューからコマンドプロンプトを選択し、右クリック管理者権限で起動します。

::

    cd /d c:\

Webブラウザから監視サーバのダウンロードサイト
http://{監視サーバアドレス}/docs/download/ を開き、以下パッケージを
c: の直下に保存します。

::

    getperf-zabbix-Build4-Windows-MSWin32.zip

エクスプローラを開き、 ダウンロードしたパッケージファイルを右クリックして解凍を選択し、解凍先を
c:\ にして解凍してください。

解凍すると、c:\\ptune の下に実行モジュール、各設定ファイルが配置されます。c:\\ptune\\bin に移動し、以下のセットアップコマンドを実行します。
監視サーバにクライアント証明書発行を依頼し、HTTPS の通信設定をします。

::

    cd \ptune\bin
    .\getperfctl.exe setup

サイトキー、アクセスキーを入力し、'更新しますか?' の確認で y を入力して設定を完了します。
以上で通信設定は終わりです。その後、サービス起動の設定をします。
getperfctl install コマンドで Windowsサービスへ Getperf エージェントの登録をします。

::

    .\getperfctl.exe install

Windows サービスから Getperf エージェントの起動をします。

::

    .\getperfctl.exe start

エージェントの起動確認をします。
c:の下に採取コマンドの実行結果が保存されるので起動した時刻のディレクトリが生成されているかを確認します。

Zabbix エージェントセットアップ
-------------------------------

C:の下の Zabbix エージェント設定ファイル作成スクリプトを実行します。
ptuneの下に zabbix\_agentd.conf ファイルが生成されます。

::

    cd C:\ptune\script\zabbix
    update_config.bat

続けて以下のスクリプトでWindowsサービスの登録を行い、Zabbix エージェントを起動します。

::

    setup_agent.bat

Zabbix エージェントが起動されると、c: の直下に、 zabbix\_agent.log が生成されます。
メモ帳などでログを開いて、 'agent # started' というメッセージが出力されてることを確認して起動を確認します。
Windows の場合は、各エージェントのサービス起動設定を合わせて行うので、OS起動時の自動起動設定を別途行う必要はありません。

以上でエージェント設定は完了で、この後は集計サーバ側の設定を行います。

.. note::

    手動でのエージェントの起動、停止について

    以下のスクリプトで各エージェントの起動、停止が可能です。administrator ユーザで実行してください。

    Getperf エージェントの起動/停止

    ::

        C:\ptune\bin\getperfctl.exe stop    # 停止する場合
        C:\ptune\bin\getperfctl.exe start   # 起動する場合

    Zabbix エージェントの起動/停止

    ::

        C:\ptune\script\zabbix\agent_control.bat --stop     # 停止する場合
        C:\ptune\script\zabbix\agent_control.bat --start    # 起動する場合
