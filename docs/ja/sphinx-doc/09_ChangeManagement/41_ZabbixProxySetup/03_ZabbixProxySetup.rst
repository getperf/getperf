Zabbixプロキシセットアップ
===========================

以下をZabbixプロキシー1からプロキシー4までの各 VM で実行します。

MySQL 8.0のインストールと初期設定
----------------------------------

前頁
:doc:`/09_ChangeManagement/41_ZabbixProxySetup/02_ZabbixServerSetup`
の、「MySQL 8.0のインストールと初期設定」のセクションを実行し、
MySQL 8 をインストールします。

Zabbixリポジトリ追加とプロキシインストール
------------------------------------------

Zabbixリポジトリの追加とプロキシのインストールをします。

::

   # Zabbix6のリポジトリをインポート
   sudo rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-4.el8.noarch.rpm
   # 公開鍵が古い場合に発生するエラーを回避するため、パッケージのキャッシュをクリア
   sudo -E dnf clean all
   # Zabbixプロキシと関連パッケージをインストール
   sudo -E dnf install -y zabbix-proxy-mysql zabbix-sql-scripts zabbix-selinux-policy zabbix-get

プロキシ用データベース作成とスキーマインポート
----------------------------------------------

.. note::

   以下に、プロキシー1台目のデータベース作成手順を記します。
   データベース作成 SQL の zabbix_proxy1 の箇所を、各プロキシー VM の枝番に変更してください。

      * 1台目(kzabproxy10) : zabbix_proxy1
      * 2台目(kzabproxy11) : zabbix_proxy2
      * 3台目(kzabproxy12) : zabbix_proxy3
      * 4台目(kzabproxy13) : zabbix_proxy4

プロキシ用データベースを作成します。

::

   mysql -u root -p -e "
   DROP DATABASE zabbix_proxy1"

Zabbixデータベースを作成します。
パスワードの箇所は環境に合わせて修正してください（規定は getperf ）。

::

   mysql -u root -p -e "
   CREATE DATABASE zabbix_proxy1 CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
   CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '{パスワード}';
   GRANT ALL PRIVILEGES ON zabbix_proxy1.* TO 'zabbix'@'localhost';
   FLUSH PRIVILEGES;"


Zabbixスキーマをインポートします。

::

   cat  /usr/share/zabbix-sql-scripts/mysql/proxy.sql | mysql -u root -p zabbix_proxy1


プロキシ設定と起動
-------------------

/etc/zabbix/zabbix_proxy.confを編集します。

::

   sudo vi /etc/zabbix/zabbix_proxy.conf


以下のパラメータを設定します。

::

   ProxyMode=1    # パッシブモード
   Server=<ZabbixサーバのIP>
   Hostname=<プロキシホスト名（例: kzabproxy10, kzabproxy11）>
   DBName=zabbix_proxy1  # プロキシ2ではzabbix_proxy2
   DBUser=zabbix
   DBPassword=<データベースのパスワード、規定は、 getperf>

また、Zabbixサーバと同様に以下のパラメータを設定します。

::

   StartPollers=250
   StartIPMIPollers=10
   StartPollersUnreachable=10
   CacheSize=256M
   TrendFunctionCacheSize=16M
   ValueCacheSize=256M
   ExternalScripts=/usr/lib/zabbix/externalscripts

以下で設定内容を確認します。

::

   egrep -e '^(Server|Hostname|DB|Start|Cache|Trend|External|Proxy)' /etc/zabbix/zabbix_proxy.conf

プロキシを起動します。

::

   sudo systemctl enable --now zabbix-proxy

正常に Zabbix Server と通信しているか確認します。

::

   sudo tail -f /var/log/zabbix/zabbix_proxy.log


