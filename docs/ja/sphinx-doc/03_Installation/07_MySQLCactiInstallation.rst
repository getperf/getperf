MySQL, Cacti インストール
=========================

MySQLとCactiを設定します。はじめに、MySQL　の root
パスワードの設定を行います。

::

    rex prepare_mysql

my.cnfにutf8の設定を追加します。

::

   sudo vi /etc/my.cnf

[mysqld]の箇所

::

   character-set-server=utf8

.. note::

   既定のMySQL設定だと、Cacti 周りで多数エラーが発生するため、
   MySQL の sql_mode を変更します。

   ::

      mysql -u root -pgetperf

   ::

       SHOW VARIABLES LIKE "%sql_mode%";
       +---------------+--------------------------------------------+
       | Variable_name | Value                                      |
       +---------------+--------------------------------------------+
       | sql_mode      | STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION |
       +---------------+--------------------------------------------+

   オンラインでの設定変更。

   ::

       SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION';

   /etc/my.cnf の sql_mode も変更します。

   ::

       sudo vi /etc/my.cnf

   ::

       # Recommended in standard MySQL setup
       #sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
       sql_mode=NO_ENGINE_SUBSTITUTION


   DBD::mysql をインストールします。

   ::

       sudo -E cpanm DBD::mysql 


PHP ライブラリ構成管理ツール composer を用いて PHP
ライブラリをインストールします。

.. note::

   RHEL8 の場合、事前に以下パッケージを追加します。

   ::

      sudo dnf install php php-cli php-zip php-json

::

    rex prepare_composer

Cacti モジュールアーカイブをダウンロードします。

::

    rex prepare_cacti

Cacti
実体のインストールは後述の監視サイト初期化作業で行います。詳細は、 サイト初期化コマンド :doc:`../10_AdminCommand/01_SiteInitialization` を参照してください。

.. note::

   時刻の期間表示の変更ができなくなる問題があるため、Cacti スクリプトを
   修正します。

   `BUG3798`_ 

   .. _BUG3798: https://github.com/Cacti/cacti/issues/3798

   ::

      cd ~/getperf/var/cacti/
      tar xvf cacti-0.8.8g.tar.gz

   Cacti スクリプトディレクトリに移動し、変更箇所を確認します。

   ::

      cd cacti-0.8.8g
      grep 160 *.php
      graph_image.php:if (!empty($_GET["graph_start"]) && $_GET["graph_start"] < 1600000000) {
      graph_image.php:if (!empty($_GET["graph_end"]) && $_GET["graph_end"] < 1600000000) {
      graph_xport.php:if (!empty($_GET["graph_start"]) && is_numeric($_GET["graph_start"]) && $_GET["graph_start"] < 1600000000) {
      graph_xport.php:if (!empty($_GET["graph_end"]) && is_numeric($_GET["graph_end"]) && $_GET["graph_end"] < 1600000000) {

   上記スクリプトの1600000000を、2600000000に変更します。

   ::

      vi graph_image.php
      # 1600000000 を検索して、2600000000 に変える
      vi graph_xport.php
      # 1600000000 を検索して、2600000000 に変える

   変更したスクリプトを tar 圧縮します。

   ::
   
      cd ~/getperf/var/cacti/
      tar cvf - cacti-0.8.8g | gzip > cacti-0.8.8g.tar.gz

