採取コマンドの定義
==================

エージェントの処理フロー
------------------------

エージェントは以下のフローでデータ採取をします。

1. 各カテゴリの採取コマンド設定ファイルの読込
2. 指定したインターバルで定期的に各カテゴリのコマンドリストを実行
3. カテゴリ内の全てのコマンドが終了するまで待ち、全コマンドが終了したら実行結果を
   zip 圧縮して監視サーバに転送
4. 過去の実行結果のログを削除

上記設定は {エージェントホーム}/conf 下のカテゴリファイルで行います。

採取コマンドの設定
------------------

エージェントホームディレクトリの conf の下に採取コマンド設定ファイルを配置します。
エージェントは起動時に、conf の下にある全ての.iniファイルを読みこみます。
原則、設定ファイル名は '{カテゴリ名}.ini' としますが、カテゴリ名はファイル内で定義するので別名でも構いません。
また、1つのファイルに複数のカテゴリを設定することも可能です。設定例を以下に記します。

例 : Linux HWリソース情報採取コマンド設定

::

    ;Collecting enable (true or false)
    STAT_ENABLE.Linux = true

    ;Interval sec (> 300)
    STAT_INTERVAL.Linux = 300

    ;Timeout sec
    STAT_TIMEOUT.Linux = 340

    ;Run mode( concurrent or serial)
    STAT_MODE.Linux = concurrent

    ; Collecting command list (Windows)
    ;  STAT_CMD.{category} = '{command}', [{outfile}], [{interval}], [{cnt}]
    ;    category ... category name
    ;    command  ... command file name
    ;       (_script_ : script directory、_odir_ : output directory)
    ;    outfile  ... output file name
    ;    interval ... interval sec [option]
    ;    cnt      ... execute times [option]
    ;  ex)
    ;   STAT_CMD.Windows = '/usr/bin/vmstat 5 61', vmstat.txt
    ;   STAT_CMD.Windows = '/bin/df -k -l', df_k.txt, 60, 10

    STAT_CMD.Linux = '/usr/bin/vmstat -a 5 61',   vmstat.txt
    STAT_CMD.Linux = '/usr/bin/free -s 30 -c 12', memfree.txt
    STAT_CMD.Linux = '/usr/bin/iostat -xk 30 12', iostat.txt
    STAT_CMD.Linux = '/bin/cat /proc/net/dev',    net_dev.txt, 30, 10
    STAT_CMD.Linux = '/bin/df -k -l',             df_k.txt
    STAT_CMD.Linux = '/bin/cat /proc/loadavg',    loadavg.txt, 30, 10

パラメータは '項目.カテゴリ' の形式で記述します。パラメータの定義はコメントの記述の通りです。
STAT_MODE は コマンドリストのコマンドを並列に実行する場合は、 concurrent、シリアルに実行する場合は、 serial とします。STAT_CMD がコマンドリストの定義で以下ルールとなります。

-  コマンドは、''(シングルコーテーション)、""(ダブルコーテーション)のどちらで括る必要が有ります。

   例 : 'コマンド', 実行結果.txt

-  リダイレクションでの記述は以下となります。

   例 : 'コマンド > 実行結果.txt'

-  実行結果.txt の後ろに、インターバル、実行回数を追加すると、繰り返しコマンドを実行し、実行結果をアペンドします。

   例 : 'コマンド', 実行結果.txt, インターバル(秒), 実行回数

-  マクロとして、スクリプトディレクトリの '_script_' と、出力ディレクトリの '_odir_' があります。以下例の様に使用します。

   例 : '_script_/get_cpu_stat.sh > _odir_/get_cpu_stat.txt'

設定の反映
----------

設定の反映させるには　getperfctl　コマンドを用いてエージェントを再起動させます。$HOME/ptune　をエージェントホームディレクトリとした場合の例を以下に記します。

::

    ~/ptune/bin/getperfctl stop
    ~/ptune/bin/getperfctl start

コマンドの実行結果は、'{エージェントホーム}/log/{カテゴリ}/{日付}/{時刻}'　の下に保存されます。
'stat_{カテゴリ}.log' はエージェント本体の実行ログで、各コマンドの開始時刻、終了時刻、プロセスID、終了コード、エラーが発生した場合のエラーメッセージを記録します。

その他の設定ファイル
--------------------

その他の設定ファイルを以下に記します。

{エージェントホーム}/getperf.ini
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

エージェント本体の設定ファイルで、各パラメータの定義は以下となります。

.. csv-table::
    :header: 項目名, 規定値, 定義
    :widths: 10, 5, 30

    DISK_CAPACITY    ,0      ,ディスクの閾値[%]。指定値を下回る場合はエラーとなりデーモンを終了します
    SAVE_HOUR        ,24     ,LOG保存時間
    RECOVERY_HOUR    ,3      ,データ転送障害時にログ再送の遡り時間
    MAX_ERROR_LOG    ,5      ,コマンド実行エラーのログ出力の最大行数。エラーログはエージェント本体の実行ログに記録されます
    LOG_LEVEL        ,5      ,ログレベル。なし 0、FATAL 1、CRIT 2、ERR 3、WARN 4、NOTICE 5、INFO 6、DBG 7
    DEBUG_CONSOLE    ,false  ,コンソールログ出力の有効化
    LOG_SIZE         ,100000 ,ログファイルサイズ[Byte]
    LOG_ROTATION     ,5      ,ログローテーション世代数
    LOG_LOCALIZE     ,true   ,コンソールログ出力の日本語の有効化。falseにすると英語出力になります
    HANODE_ENABLE    ,false  ,有効化した場合は監視サーバへの転送をホスト名ではなくHANODE_CMDの実行結果をサービス名として転送します
    HANODE_CMD       ,''     ,クラスター構成のサービス名チェックスクリプト。script/の下に配置する。スクリプト実行結果をサービスホスト名としてホスト名の代わりに監視サーバに転送します
    POST_ENABLE      ,false  ,zip圧縮後の転送処理の有効化。trueの場合は、エージェントWebサービスの転送はせずに、POST_CMD で定義したコマンドを用いてデータ転送をします
    POST_CMD         ,''     ,転送コマンドを記述します。マクロ *zip* が zip ファイルパスとなります
    PROXY_ENABLE     ,false  ,プロキシーサーバの有効化
    PROXY_HOST       ,''     ,プロキシーサーバアドレス。指定がない場合は環境変数のHTTP_PROXYの値を使用します
    PROXY_PORT       ,''     ,プロキシーサーバポート。指定がない場合は環境変数のHTTP_PROXYの値を使用します
    SOAP_TIMEOUT     ,300    ,エージェントWebサービスのタイムアウト時間

{エージェントホーム}/network/ 下のファイル
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

{エージェントホーム}/network/の下に、監視サーバとの通信設定ファイルを配置します。'getperfctl　setup' コマンド実行後、各ファイルが自動生成されます。

-  License.txt

   エージェントセットアップ時に、監視サーバから取得するライセンスファイルとなります。
   getperfctl setup を再実行する場合は、一旦このライセンスファイルを削除してから実行してください。ライセンスの有効期限の設定があり、後述の SSL 証明書の有効期限と同期しています。監視サーバは有効期限が切れる1日前にライセンスファイルの自動更新をし、エージェントは有効期限が切れたタイミングで自動でダウンロードします。有効期限は GETPERF_SSL_EXPIRATION_DAY に指定します。

-  getperf_ws.ini

   監視サーバのエージェント　Web　サービスの接続設定となります。データ転送を無効にする場合は、REMHOST_ENABLE を false にしてください。それ以外のパラメータは getperfctl setup コマンド実行時に自動生成されます。

-  ca.crt, client.crt, client.csr, client.key, client.pem

   SSL証明書一式となります。何れも、監視サーバ側で自動生成されるファイルとなります。SSL 証明書には有効期限があり、有効期限が切れるタイミングで、エージェントは新しいSSL証明書一式を監視サーバから自動ダウンロードします。
