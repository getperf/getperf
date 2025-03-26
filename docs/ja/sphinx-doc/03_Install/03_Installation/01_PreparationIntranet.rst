イントラネット環境での設定
==========================

.. note:: インストールには外部インターネット接続が必要です。イントラネット環境でプロキシー経由でのアクセスが必要な場合は、以下のプロキシー設定が必要になります。

.. note:: プロキシー設定が不要な場合は本セクションの設定はスキップしてください。

.. note::

    プロキシーの設定は使用環境に合わせて実施してください。
    以下にプロキシーの設定例を記します。

    .. 旧インストールガイドの、 :doc:`../03_Installation.v2/01_PreparationIntranet` 
    .. に設定例がありますので詳細はそちらを参照してください。



プロキシー設定
--------------

以下の設定は前述の psadmin ユーザで作成したGetperf管理用ユーザで行います。

プロキシー環境の設定
~~~~~~~~~~~~~~~~~~~~

これからの作業はGetperf管理ユーザで行います。プロキシーサーバを
proxy.your.company.co.jp、接続ポートを 8080　を例にして設定手順を記します。

.. note:: 

   TeraTerm のポート転送を用いてプロキシ経由で外部インターネットにアクセスする場合は、
   本ページに記載のポート番号は 8080 から 18080 に変更して Teraterm に以下の設定をしてください。

   * TeraTerm の SSH転送設定にて、リモートサーバのポートを、18080、ローカル側ホスト
     をプロキシーサーバホスト名、またはIPアドレス、ポートを 8080 に指定してください。

   * インストール先で、以下 /etc/hosts のIPアドレスを、127.0.0.1 に設定してください。

    ::

        sudo vi /etc/hosts

    最終行に以下例の通りプロキシーサーバを追加します。

    ::

        127.0.0.1  proxy.your.company.co.jp


/etc/hosts 編集
~~~~~~~~~~~~~~~

/etc/hosts にプロキシーサーバを追加

::

    sudo vi /etc/hosts

最終行に以下例の通りプロキシーサーバを追加します。

::

    xxx.xxx.xxx.xxx  proxy.your.company.co.jp

ネームサーバが有効になっていない環境の場合、自身のサーバのアドレスと、プロキシーサーバのアドレス設定が必要な場合があります。

::

    sudo vi /etc/hosts

以下の行を追加します。

::

    XX.XX.XX.XX    自身のサーバのホスト名


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


社内認証局の証明書インポート
----------------------------

セキュリティ対策で、ウェブサイトのアクセスで認証局による SSL　認証が必要な場合は、社外用認証局証明書をインストールします。

OpenSSLセットアップ
~~~~~~~~~~~~~~~~~~~

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

    keytool が入っていない場合は、以下で JDK をインストールしてください

    ::

        sudo -E yum -y yum search java-latest-openjdk-devel
