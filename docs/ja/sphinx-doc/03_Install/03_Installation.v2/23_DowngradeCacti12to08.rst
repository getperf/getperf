Cacti 0.8 ダウングレードについて
================================

RedHat 7 系のサーバで Cacti 1.2 から Cacti 0.8 へダウングレード
する手順を記します。

前提として、前節までのインストール手順で、Cacti 1.2 がインストールされた環境での手順となります。

PHP 7.3 から PHP 5.4 への変更
-----------------------------

composer を PHP 5.4 と互換性のあるバージョン 2.2 に変更します。

::

   sudo -E composer self-update --2.2

PHP パッケージを削除します。

::

   sudo -E yum remove php-*

OS 標準の PHP 5.4 パッケージをインストールします。

::

   sudo -E yum  install  --enablerepo=epel,remi,remi-safe \
      pcre-devel \
      php php-mbstring \
      php-mysqlnd php-pear php-common php-gd php-devel php-cli \
      cairo-devel libxml2-devel pango-devel pango \
      libpng-devel freetype freetype-devel  \
      curl git rrdtool zip unzip \
      mysql-devel  php php-cli php-common  php-mysqlnd  php-json


composer を実行して、PHP ライブラリをインストールします。

::

   cd ~/getperf
   rex prepare_composer

php.ini パッチを適用します。

::

   sudo -E perl $HOME/getperf/script/config-pkg.pl php

httpd サービスを再起動します。

::

   sudo service httpd restart

MySQL パッチ
------------

既定の MySQL 8.0 のパラメータ sql_mode を、Cacti 0.8 と互換性のあるモードに変更します。

::

   sudo vi /etc/my.cnf

[mysqld]のセクションに以下の行を追加します。

::

   sql_mode=NO_ENGINE_SUBSTITUTION

mysqld サービスを再起動します。

::

   sudo service mysqld restart

Cacti 設定変更
---------------

Cacti 設定ファイルを変更します。
以下のパスの設定ファイルを変更します。

::

   cd ~/getperf/config/
   cp getperf_cacti.json_0.8.8 getperf_cacti.json

または、vi で以下のテキストに編集します。

::

   vi getperf_cacti.json

::

   {
       "GETPERF_CACTI_HTML": "/var/www/html",
       "GETPERF_CACTI_ARCHIVE_DIR": "/home/psadmin/getperf/var/cacti",
       "GETPERF_CACTI_ARCHIVE": "cacti-0.8.8g.tar.gz",
       "GETPERF_CACTI_HOME": "/home/psadmin/getperf/lib/cacti",
       "GETPERF_CACTI_TEMPLATE_DIR": "template/0.8.8g",
       "GETPERF_CACTI_DUMP": "template/0.8.8g/cacti.dmp",
       "GETPERF_CACTI_DOMAIN_TEMPLATES": [
           "Linux",
           "Windows"
       ],
       "GETPERF_CACTI_CONFIG": "template/0.8.8g/config.php.tpl"
   }

Cacti ライブラリのリンクを修正します。
~/getperf/lib 下の Cacti 1.2 用のリンクを、Cacti0.8 用に修正します。

::

   cd ~/getperf/lib/
   ls -l cacti
   rm cacti
   ln -s cacti-0.8.8 cacti

以上で修正は完了です。

動作確認
--------

サイトの初期化をして作成したサイトで動作確認をします。

::

   cd ~/site/
   # initsite -f site2
   initsite -f {Cacti0.8検証用サイトキー}

作成したサイトの URL を参照して、 Cacti 0.8 画面が表示されるか確認します。

::

   # http://{監視サーバIP}/site2
   http://{監視サーバIP}/{Cacti0.8検証用サイトキー}

また、グラフ登録コマンドで 上記サイトに正しくグラフ表示されるか確認します。

