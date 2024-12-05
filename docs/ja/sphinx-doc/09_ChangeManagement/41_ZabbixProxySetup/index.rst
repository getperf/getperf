Zabbixサーバ・プロキシ構築
==========================

Zabbix老朽更新作業のため、以下 Zabbix 新サーバの構築手順を記します。

* OS は Oracle Linux 8.x とします
* MySQL 8.0、 PHP7.3、Zabbix 6.0パッケージをインストールします
* Zabbix のクラスター構成である。サーバ・プロキシ構成で複数 VM で構築します
* Zabbixサーバ1台とZabbixプロキシ4台のクラスター構成とします
* プロキシの構成はパッシブモードとします
* MySQL パーティショニング設定・Oracleクライアントインストールを行います

.. toctree::
   :maxdepth: 1

   01_VMInitialSetup
   02_ZabbixServerSetup
   03_ZabbixProxySetup
   04_ZabbixProxyConfiguration
   05_ZabbixAgentSetup
   06_MySQLPartitioning
   07_OracleClientSetup
