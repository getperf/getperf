SSL設定
-------

各種SSL証明書の作成を行います。証明書は /etc/getperf/ssl の下に作成されます。

SSHキーの作成
^^^^^^^^^^^^^

Git 通信用に管理者ユーザの $HOME/.ssh ディレクトリ下に SSH キーファイルを作成します。 
Git を用いて、外部の Getperf サイトを複製する場合は、作成した.ssh/id_rsa.pub ファイルを公開鍵ファイルとして使用します。詳細は、 :doc:`../08_ChangeManagement/07_SiteCloning` を参照してください。

::

    cd $GETPERF_HOME
    rex install_ssh_key

SSL証明書の作成
^^^^^^^^^^^^^^^

エージェント Web サービスの HTTPS 通信用にプライベート認証局を作成します。/etc/getperf/ssl/ca の下に各証明書を保存します。

::

   rex create_ca        # ルート認証局作成

.. note::

   Getperfはプラベートルート認証局と中間認証局の2段構成の認証局で構成します。
   1台の監視サーバでルート認証局を作成し、それ以外のサーバは作成したルート認証局をコピーしてルート認証局を共有することが可能です。
   複数監視サーバでの認証局構築手順については、
   その他の :doc:`../08_ChangeManagement/06_SSLCertificateInstration` を参照してください。
   ここでは、ルート認証局を共有せずに1台にルート認証局と中間認証局を作成する手順を記します。

中間認証局を作成します。

::

    rex create_inter_ca  # 中間認証局作成

サーバ証明書の作成
^^^^^^^^^^^^^^^^^^

エージェント Web サービスの Apache サーバ用のSSL証明書を作成します。/etc/getperf/ssl/server の下に各証明書を保存します。後述の Apache HTTP サーバのインストールで本証明書を設定します。

::

    rex server_cert

.. note::

   `CentOS6.9リリースノート`_ には、"Support for insecure cryptographic protocols
   and algorithms has been dropped. This affects usage of MD5, SHA0, RC4 and DH
   parameters shorter than 1024 bits." の記述があり、以降のバージョンから SHA-1 の
   サポートが終了します。
   現在、証明書が SHA-1 の場合、中間証明書、サーバ証明書を SHA-2 に移行する必要が
   あります。ルート証明書はそのままにして、
   上記コマンド rex create_inter_ca、 rex server_cert を再実行してください。
   実行後の、認証アルゴリズムは以下となります。

   ::

      openssl req -in /etc/getperf/ssl/ca/ca.csr -text | grep Signature
          Signature Algorithm: sha1WithRSAEncryption
      openssl req -in /etc/getperf/ssl/inter/ca.csr -text | grep Signature
          Signature Algorithm: sha256WithRSAEncryption
      openssl req -in /etc/getperf/ssl/server/server.csr -text | grep Signature
          Signature Algorithm: sha256WithRSAEncryption

   .. _CentOS6.9リリースノート: https://wiki.centos.org/Manuals/ReleaseNotes/CentOS6.9


クライアント証明書の自動更新スケジュール登録
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

監視対象のクライアント証明書は、getperf_site.json 設定ファイルに指定した値 GETPERF_SSL_EXPIRATION_DAY(デフォルトは365日) を有効期限として設定します。以下のスケジュール登録で、
定期的にクライアント証明書の自動更新をします。本スクリプトは登録した監視対象のクライアント証明書の
有効期限が 1 週間前になった場合に証明書の有効期限の更新をします。

.. note::

   Rex 1.4 の不具合で、Cron 登録がない状態で後述の Rex コマンドを実行すると、
   "ERROR - Rex::Helper::Run::i_run" のエラーメッセージが表示され登録に失敗します。
   ワークアラウンドとして事前に以下の手順で空の Cron を登録してください。

   ::

      EDITOR=vi crontab -e
      # 改行を追加して、Cron設定を終了する。

    root の cron についても同様の設定をします

   ::

      sudo EDITOR=vi crontab -e
      # 改行を追加して、Cron設定を終了する。

Rex コマンドを実行します。

::

    sudo rex run_client_cert_update

.. note::

	監視対象のエージェントは有効期限が切れるタイミングで新規証明書をダウンロードして自動更新を行います。

