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

PHP ライブラリ構成管理ツール composer を用いて PHP
ライブラリをインストールします。

::

    rex prepare_composer

Cacti モジュールアーカイブをダウンロードします。

::

    rex prepare_cacti

Cacti
実体のインストールは後述の監視サイト初期化作業で行います。詳細は、 サイト初期化コマンド :doc:`../10_AdminCommand/01_SiteInitialization` を参照してください。
