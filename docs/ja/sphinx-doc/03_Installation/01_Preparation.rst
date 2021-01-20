=====================
インストール
=====================

事前準備
========

インストール前に CentOS 環境で以下の設定が必要となります。設定済みの場合は本節をスキップしてください。また、Getperf
のインストールは、sudo 権限のある一般ユーザを用いて監視サーバのインストールを行います。事前にユーザを作成をし、Getperf
管理ユーザとしてインストールを行います。

-  SELinux の無効化
-  Firewall の許可設定
-  Getperf 管理用ユーザ作成
-  プロキシー設定
-  社内認証局の証明書インポート

SELinux の無効化
----------------

インストールするソフトウェアの設定は SELinux が機能しない設定となっているため、SELinux を無効にしてください。 root
ユーザで以下を実行してください。

getenforce コマンドで SELinux の動作状況を調べます。

::

    getenforce

Enforcing と出力された場合は、SELinux が有効となっています。以下のコマンドで SELinux を無効化します。

::

    setenforce 0 

/etc/selinux/config を編集し、再起動時の SELinux 状態を無効にします。

::

    vi /etc/selinux/config

SELINUX の値を disabled に変更して保存します。

::

    SELINUX=disabled

Firewall の許可設定
-------------------

前節の各ソフトウェアの使用ポートは外部アクセス許可設定が必要となります。
Firewall の設定がされている場合は、これらポートのアクセス許可設定をします。
設定は iptables の設定ファイルを編集して行いますが、ここでは簡略化のため、
iptables 自体を停止して全ポートのアクセス許可設定をします。

::

    sudo systemctl is-enabled firewalld
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld

また、DNSなどでホストの名前解決ができない場合は、/etc/hosts にホストのIPアドレスと登録してください。

::

    vi /etc/hosts

IPアドレスと監視サーバホスト名を追加します。

::

    (最終行に追加)
    XXX.XXX.XX.XX 監視サーバホスト名

Getperf管理用ユーザ作成
-----------------------

Getperf管理用ユーザを作成し、root権限を追加します。作業は root ユーザで実行してください。 
ここでは例としてユーザ名を、 psadmin としていますが適宜変更してください。

::

    useradd psadmin

パスワードを設定します

::

    passwd psadmin

visudoで設定ファイルを編集します。

::

    visudo

Default
secure_pathの行を探して行の最後に、/usr/local/bin:/usr/local/sbinを追加します

::

    Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

Cron の sudo 実行許可設定をするため、以下の行をコメントアウトします

::

    #Defaults   !visiblepw

最終行にユーザ登録の行を追加します。インストールスクリプトを用いてバッチで実行するため、sudo
ユーザは NOPASSWD のパスワードなしの設定にしてください。

::

    (最終行に追加)
    psadmin        ALL=(ALL)       NOPASSWD: ALL

インストールするApacheプロセスがホームディレクトリ下をアクセスできるよう、ホームディレクトリのアクセス権限を変更します

::

    su - psadmin
    chmod a+rx $HOME

