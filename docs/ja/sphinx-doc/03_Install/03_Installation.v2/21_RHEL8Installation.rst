RHEL8 Getperf インストール留意点
================================

概要
----

Cacti 0.8.x の PHP 対応バージョンは 5.3 となり、RHEL8 標準の
PHP7 で実行すると、DB周りの API でエラーが発生します。
また、CentOS7 まは、 PHP 5.4 パッケージをサポートしていましたが、
RHEL8 では、PHP5 の提供はない様です。

パッケージ管理をせずに、Apache, PHP をソースコンパイルして、
/usr/local の下に配置する構成を取ります。

Apache のインストール
---------------------

Rex 用にダウンロードしたソースからコンパイルします。

::

    # コンパイルしてインストール
    cd /tmp/rex
    cd httpd-2.2.34
    ./configure \
      --prefix=/usr/local/apache \
      --enable-so \
      --enable-rewrite \
      --enable-auth-digest \
      --enable-dav \
      --enable-proxy \
      --enable-proxy-ajp \
      --enable-setenvif
    make
    sudo make install

.. note::

    OpenSSL ライブラリで互換性エラーが発生するため、
    SSL は無効にします。

コンパイル、インストール後、設定ファイルを編集します。

::

    cd /usr/local/apache/
    vi conf/httpd.conf

::

    # リッスンポートを8081 に変更します。
    Listen 8081

    # 
    DocumentRoot "/var/www/html"
    <Directory "/var/www/html">

PHP コンパイル
--------------

コンパイルに必要なパッケージをインストールします。

::

    sudo dnf install php php-cli php-zip php-json
    sudo dnf install libxml2-devel
    sudo dnf install openssl-devel
    sudo dnf install curl-devel
    sudo dnf install gmp-devel
    sudo dnf install libjpeg-devel
    sudo dnf install libc-client-devel
    sudo yum install libmcrypt-devel

PHP バージョンの確認をします。

::

    https://aulta.co.jp/archives/7950

リストから、5.6を選択し、/home/psadmin/work/sfw にダウンロードします。

::

    mkdir -p /home/psadmin/work/sfw
    cd /home/psadmin/work/sfw
    wget https://www.php.net/distributions/php-5.6.40.tar.gz

環境変数を設定してインストールします。以降は root で実行します。

::

    sudo su -
    DIR_SOURCE=/home/psadmin/work/sfw
    PHP_VERSION=5.6.40
    MYSQL_TITLE=mysqlnd
    MYSQL_CLIENT=mysqlnd
    MYSQLI_CLIENT=mysqlnd
    MYSQLPDO_CLIENT=mysqlnd

    # /usr/local/src にディレクトリを作る
    mkdir /usr/local/src/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE

    # ↑で作ったディレクトリに移動
    cd /usr/local/src/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE

    # /tmp にアップしておいた tar.gz を移動
    cp $DIR_SOURCE/php-$PHP_VERSION.tar.gz /usr/local/src/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php-$PHP_VERSION.tar.gz

    # 解凍
    tar xzf php-$PHP_VERSION.tar.gz

    # 解凍先に移動
    cd php-$PHP_VERSION

コンパイルします。

::

    ./configure \
    --prefix=/usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE \
    --program-suffix=-$PHP_VERSION-mysqlc-$MYSQL_TITLE \
    --with-config-file-path=/usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE \
    --with-apxs2=/usr/local/apache/bin/apxs \
    --with-libdir=lib64 \
    --with-pic \
    --with-curl \
    --with-freetype-dir=/usr \
    --with-png-dir=/usr \
    --with-jpeg-dir=/usr \
    --with-gettext \
    --with-gmp \
    --with-iconv \
    --with-layout=GNU \
    --with-kerberos \
    --with-gd \
    --with-zlib \
    --with-mysql=$MYSQL_CLIENT \
    --with-mysqli=$MYSQL_CLIENT \
    --with-mysql-sock=$MYSQL_SOCKET_PATH \
    --with-pdo-mysql=$MYSQL_CLIENT \
    --with-system-ciphers \
    --without-pear \
    --enable-cgi \
    --enable-mbstring \
    --enable-cli \
    --enable-gd-native-ttf \
    --enable-exif \
    --enable-ftp \
    --enable-sockets \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-sysvmsg \
    --enable-wddx \
    --enable-shmop \
    --enable-zip \
    --enable-calendar \
    --enable-fpm \
    --with-imap=/usr \
    --with-imap-ssl \
    --with-mcrypt

    make
    make install

パスを通します。

    echo 'PATH=$PATH:'"/usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE"/bin >> /etc/profile.d/php.sh
    echo "export PATH" >> /etc/profile.d/php.sh
    cat /etc/profile.d/php.sh

パスを反映させます。

    chmod a+x /etc/profile.d/php.sh
    source /etc/profile.d/php.sh

php.iniを設定します。

::

    # php.ini-development を php.ini としてコピーして配置
    cp /usr/local/src/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php-$PHP_VERSION/php.ini-development /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini

    # タイムゾーンを Asia/Tokyo に変更
    sed -i -e "s/^;date\.timezone =[^A-Za-z]*$/date.timezone =/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^date\.timezone =[^A-Za-z]*$/date.timezone = Asia\/Tokyo/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini

    # 次の３つの .sock は yum でMySQLをインストールした場合の位置
    sed -i -e "s/^mysql\.default_socket =$/mysql.default_socket = \/var\/lib\/mysql\/mysql.sock/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^mysqli\.default_socket =$/mysqli.default_socket = \/var\/lib\/mysql\/mysql.sock/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^pdo_mysql\.default_socket=$/pdo_mysql.default_socket = \/var\/lib\/mysql\/mysql.sock/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini

    # OPcacheの設定 （公式のデフォルトで設定）
    # http://php.net/manual/ja/opcache.installation.php
    sed -i -e "s/^;opcache.memory_consumption=/opcache.memory_consumption=/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^;opcache.interned_strings_buffer=/opcache.interned_strings_buffer=/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^;opcache.max_accelerated_files=/opcache.max_accelerated_files=/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^;opcache.revalidate_freq=/opcache.revalidate_freq=/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini
    sed -i -e "s/^;opcache.enable_cli=/opcache.enable_cli=/g" /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini


viで php.ini を開き、opcache.fast_shutdown=1 が無いと思うので [curl] の上あたりに追記する

::

    vi /usr/local/lib/php-$PHP_VERSION-mysqlc-$MYSQL_TITLE/php.ini

php/bin の下のバイナリにリンクを作成します。

::

    cd /usr/local/lib/php-5.6.40-mysqlc-mysqlnd/bin

    ln -s php-5.6.40-mysqlc-mysqlnd php
    ln -s php-cgi-5.6.40-mysqlc-mysqlnd php-cgi
    ln -s php-config-5.6.40-mysqlc-mysqlnd php-config
    ln -s phpize-5.6.40-mysqlc-mysqlnd phpize

設定を確認します。

::

    # php.iniのタイムゾーン
    grep -E 'date.timezone|default_socket' /usr/local/lib/php-5.6.40-mysqlc-mysqlnd/php.ini

    # php.ini
    vi /usr/local/lib/php-5.6.40-mysqlc-mysqlnd/php.ini

    # バージョン
    php-5.6.40-mysqlc-mysqlnd -v
    php -v


PHP コンパイル後のApache 設定
-----------------------------

::

    cd /usr/local/apache/
    vi conf/httpd.conf

LoadModule php5_moduleの下に以下の行を追加します。

::

    LoadModule php5_module        modules/libphp5.so の下に追加

    DirectoryIndex index.php index.html main.html

    PHPIniDir /usr/local/lib/php-5.6.40-mysqlc-mysqlnd

     <FilesMatch \.php$>
        SetHandler application/x-httpd-php
     </FilesMatch>

Apache を再起動します。

::

    /usr/local/apache/bin/apachectl restart

OS 自動起動設定。


