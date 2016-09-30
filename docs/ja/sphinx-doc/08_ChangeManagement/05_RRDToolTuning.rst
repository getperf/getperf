RRDtoolバージョンアップ
=======================

監視対象の台数が増えるとRRDtoolによるデータロード処理がボトルネックになる場合があります。
パッケージインストールしたRRDtoolバージョンが古い場合がありその場合、新バージョンにバージョンアップすることでパフォーマンス改善が期待できます。
開発サイトからソースをコンパイルして最新版をインストールする手順を以下に記します。

-  yum package : v 1.3.8
-  RRDtool site : v 1.5.3

RRDtool Install
---------------

CentOS
~~~~~~

::

    sudo yum -y install cairo-devel libxml2-devel pango-devel pango libpng-devel freetype freetype-devel     libart_lgpl-devel     

    wget http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.5.5.tar.gz
    tar xvf rrdtool-1.5.5.tar.gz
    cd rrdtool-1.5.5

    export PKG_CONFIG_PATH=/usr/lib/pkgconfig/
    ./configure
    make
    sudo make install

    /opt/rrdtool-1.5.3/bin/rrdtool -v

Ubuntu
~~~~~~

::

    sudo apt-get install libcairo-dev libxml2-dev libghc-pango-dev

    wget http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.5.3.tar.gz
    tar xvf rrdtool-1.5.3.tar.gz
    cd rrdtool-1.5.3

    ./configure
    make
    sudo make install

    /opt/rrdtool-1.5.3/bin/rrdtool -v

Getperf 設定
------------

環境変数RRDTOOL\_PATHにrrdtoolパスを登録すると有効になります。

::

    echo 'export RRDTOOL_PATH=/opt/rrdtool-1.5.5/bin/rrdtool' >> ~/.bash_profile
    source ~/.bash_profile

自PCで実行した簡単なデータロードテストの結果は以下となりました。

::

    perl t/4_rrd.t
    ...
    Elapse = 8.550309     # RRDtool v1.3.8
    ...
    Elapse = 2.367747     # RRDtool v1.5.3

