各VMの初期設定
==============

各 VM 共通の設定として Zabbix サーバ, Zabbix プロキシーのすべてのVMに対して以下を実施します。

SELinuxとファイアウォールの無効化
---------------------------------

psadmin 管理者ユーザに接続します。
SELinuxとファイアウォールを無効化します。

::

   # psadmin 管理者ユーザに接続して実行
   sudo systemctl disable --now firewalld
   sudo setenforce 0
   sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


イントラネット環境設定
----------------------

イントラネット環境でプロキシー経由でのアクセスが必要な場合は、プロキシー設定が必要になります。
プロキシーの設定は使用環境に合わせて実施してください。 以下にプロキシーの設定例を記します。

:doc:`/03_Install/03_Installation/01_PreparationIntranet`

システム更新と基本パッケージのインストール
------------------------------------------

システム更新と基本パッケージのインストールをします。

::

   sudo -E dnf update -y
   sudo -E dnf install -y wget epel-release
