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

    sudo /etc/rc.d/init.d/iptables stop 
    sudo chkconfig iptables off 
    sudo chkconfig ip6tables off 

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

最終行にユーザ登録の行を追加します。インストールスクリプトを用いてバッチで実行するため、sudo
ユーザは NOPASSWD のパスワードなしの設定にしてください。

::

    (最終行に追加)
    psadmin        ALL=(ALL)       NOPASSWD: ALL

インストールするApacheプロセスがホームディレクトリ下をアクセスできるよう、ホームディレクトリのアクセス権限を変更します

::

    su - psadmin
    chmod a+rx $HOME

プロキシー設定
--------------

　インストールは外部インターネットから各種オープンソースをダウンロードして行います。イントラネット環境でプロキシー経由でのアクセスが必要な場合は、以下のプロキシー設定が必要になります。これら設定は上記ユーザで作成したGetperf管理用ユーザで行います。

プロキシー環境の設定
~~~~~~~~~~~~~~~~~~~~

これからの作業はGetperf管理ユーザで行います。プロキシーサーバを
proxy.your.company.co.jp、接続ポートを 8080　を例にして設定手順を記します。

/etc/hosts にプロキシーサーバを追加
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    sudo vi /etc/hosts

最終行に以下例の通りプロキシーサーバを追加します。

::

    xxx.xxx.xxx.xxx  proxy.your.company.co.jp

管理ユーザの環境変数設定
^^^^^^^^^^^^^^^^^^^^^^^^

::

    vi $HOME/.bash_profile

最終行にプロキシーの環境変数を追加します。ついでに PATH の設定に /usr/local/bin を追加します。

::

    PATH=$PATH:$HOME/bin:/usr/local/bin

    export PATH

    export http_proxy=http://proxy.your.company.co.jp:8080
    export HTTP_PROXY=http://proxy.your.company.co.jp:8080
    export https_proxy=http://proxy.your.company.co.jp:8080
    export HTTPS_PROXY=http://proxy.your.company.co.jp:8080
    export ftp_proxy=http://proxy.your.company.co.jp:8080

環境変数設定読込

::

    source ~/.bash_profile

wgetのプロキシー設定
^^^^^^^^^^^^^^^^^^^^

::

    vi ~/.wgetrc

設定例

::

    http_proxy=http://proxy.your.company.co.jp:8080

curlのプロキシー設定
^^^^^^^^^^^^^^^^^^^^

::

    vi ~/.curlrc

設定例

::

    proxy=http://proxy.your.company.co.jp:8080/

Gradleのプロキシー設定
~~~~~~~~~~~~~~~~~~~~~~

::

    mkdir -p ~/.gradle/
    vi ~/.gradle/gradle.properties

設定例

::

    systemProp.http.proxyHost=proxy.your.company.co.jp
    systemProp.http.proxyPort=8080
    systemProp.http.proxyUser=
    systemProp.http.proxyPassword=

    systemProp.https.proxyHost=proxy.your.company.co.jp
    systemProp.https.proxyPort=8080
    systemProp.https.proxyUser=
    systemProp.https.proxyPassword=

    org.gradle.daemon=true

Mavenのプロキシー設定
~~~~~~~~~~~~~~~~~~~~~

::

    mkdir ~/.m2
    vi ~/.m2/settings.xml

設定例

::

    <settings>
      <proxies>
        <proxy>
          <active>true</active>
          <protocol>http</protocol>
          <host>proxy.your.company.co.jp</host>
          <port>8080</port>
          <nonProxyHosts>www.google.com|*.somewhere.com</nonProxyHosts>
        </proxy>
      </proxies>
    </settings>

オートインデントでテキストレイアウトが崩れる場合は、貼り付け前に以下のviコマンドを実行します。

::

    :set paste

rootユーザでの実行も必要なため、/root/.m2 にも同様の設定をします。

::

    sudo mkdir /root/.m2
    sudo vi /root/.m2/settings.xml

sudo実行時のgitのプロキシー設定
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Couldn't resolve host 'github.com' エラーが発生した場合の対処**

プロキシー経由の場合、rootのgit設定にプロキシーを追加する必要があります。

::

    sudo vi /root/.gitconfig

設定例

::

    [http]
            proxy = http://proxy.your.company.co.jp:8080

/etc/hosts 編集
~~~~~~~~~~~~~~~

ネームサーバが有効になっていない環境の場合、自身のサーバのアドレスと、プロキシーサーバのアドレス設定が必要な場合があります。

::

    sudo vi /etc/hosts

以下の行を追加します。

::

    XX.XX.XX.XX    自身のサーバのホスト名
    YY.YY.YY.YY    プロキシーサーバ名

社内認証局の証明書インポート
----------------------------

セキュリティ対策で、ウェブサイトのアクセスで認証局による SSL　認証が必要な場合は、社外用認証局証明書をインストールします。

OpenSSLセットアップ
^^^^^^^^^^^^^^^^^^^

社内 IS　部門サイトから、認証局証明書保存ディレクトリに証明書をダウンロードします。
以下作業は全てrootで実行します。以下例では、intra_ssl_cert.zip　という証明書アーカイブファイルをダウンロードして、
intra_ssl_cert.cer　をインポートする例を記します。

root にスイッチユーザします。

::

    sudo su -

SSL証明書保存ディレクトリに移動して、証明書をダウンロード・解凍します。

::

    cd /etc/pki/tls/certs/
    wget http://xx.xx.xxx.xxx/YYY/intra_ssl_cert.zip --no-proxy

    unzip intra_ssl_cert.zip
    rm -f intra_ssl_cert.zip

ca-bundle.crt のバックアップを取ります。

::

    cp -p ca-bundle.crt ca-bundle.crt.bak

解凍した社外の証明書をca-bundle.crt に登録(アペンド)します。

::

    cat intra_ssl_cert.cer >> ca-bundle.crt

Java SSLセットアップ
^^^^^^^^^^^^^^^^^^^^

keytool を用いて、上記でダウンロードした証明書をJavaにインストールします。

::

    keytool -import -alias IntraRootCA -keystore /etc/pki/java/cacerts -file /etc/pki/tls/certs/intra_ssl_cert.cer

Enter keystore password:と聞かれる場合は、CentOS
JDKデフォルトの"changeit"を入力します

.. note::

    keytool が入っていない場合は、 sudo -E yum -y install
    java-1.7.0-openjdk-devel で JDK をインストールしてください

