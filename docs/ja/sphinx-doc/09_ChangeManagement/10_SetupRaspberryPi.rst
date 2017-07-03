Raspberry Pi 環境の監視サーバセットアップ
=========================================

Raspberry Pi環境に監視サーバをセットアップする手順を記します。

::

   more /etc/issue
   Raspbian GNU/Linux 8 \n \l

事前準備
--------

* SELinux の無効化

* Firewall の許可設定

   Firewall 用コマンド ufw をインストールして Firewall を無効化します。

   ::

      sudo  apt-get -y install ufw
      sudo ufw status verbose

   上記結果で、"Status: inactive" となっていればすでに無効化されています。
   無効化されていない場合は、以下で無効化します。

   ::

      sudo ufw disable

* 管理者ユーザユーザ追加

   adduser コマンドで管理用ユーザを追加します。

   ::

      sudo adduser psadmin
      sudo gpasswd -a psadmin sudo

* ディスク容量の削減

   SDカードが8GB未満の場合、ディスク容量不足が発生する可能性があります。
   ディスク使用量削減のため、不要パッケージを削除します。
   はじめに、X-Windows を無効化し、関連ライブラリを削除します。

   * raspi-config コマンドを実行します
   * "boot option"→"Console"を選択して、Xを起動しないように設定しておきます

   次に、X環境ライブラリを削除します。

   ::

      sudo apt-get install deborphan
      sudo apt-get autoremove --purge "libx11-.*" "lxde-.*" raspberrypi-artwork xkb-data omxplayer penguinspuzzle sgml-base xml-core "alsa-.*" "cifs-.*" "samba-.*" "fonts-.*" "desktop-*" "gnome-.*" 
      sudo apt-get autoremove --purge $(deborphan)
      sudo apt-get autoremove --purge
      sudo apt-get autoclean

* 基本パッケージのインストール

   設定後、:doc:`../03_Installation/02_PackageInstallation`
   の手順でセットアップを実行してください。
   基本パッケージは以下をインストールしてください。

   ::

      sudo apt-get install raspberrypi-kernel-headers build-essential
      sudo apt-get upgrade

.. note::

   上記準備が完了したら、それ以降の作業は標準セットアップ手順と同じです。
   :doc:`../03_Installation/02_PackageInstallation` の
   'Perl インストール' からセットアップを進めてください。


