OpenSSL v1.1 対応
=================

Windows コンパイル環境
----------------------

Cコンパイラは VisualStudio2015 が利用可能

    choco install vcbuildtools


インストール後、「VS 2015 x86 Native Tools Command Prompt」 を起動する

現状調査
--------

OpenSSL v1.1.x ではリンクエラーが発生するため、v1.0.2g を使用する必要がある

    error LNK2019: unresolved external symbol _OPENSSL_sk_num referenced 

以下記載のサイトからはすでに v1.0.2g のダウンロードができないため、
別のプロバイダを選ぶ必要がある。
過去に保存した、OpenSSL-Win32-v1.0.2g.zip を使用すればコンパイルは可能。

リファレンス

* [Shining Light Productions](http://slproweb.com/products/Win32OpenSSL.html)
* [OpenSSL Binary](https://wiki.openssl.org/index.php/Binaries)

Linux 調査
----------

CentOS8 の OpenSSL パッケージは、v1.1.1g。configure を実行すると
シンボル SSL_ibrary_init が見つからないエラーが発生する。

```
conftest.c:22: undefined reference to `SSL_library_init'
```

automake で configure を作り直す必要がありそう。

```
sudo yum install automake 
```

src/Makefile.am の lib パラメータの設定を修正

```
#common_ldadd = $(top_srcdir)/src/libgpfcommon.a 
#soap_ldadd   = $(top_srcdir)/src/libgpfsoap.a 
#zip_ldadd    = $(top_srcdir)/src/libgpfzip.a 

common_ldadd = libgpfcommon.a 
soap_ldadd   = libgpfsoap.a 
zip_ldadd    = libgpfzip.a 
```

configure.ac も諸々修正。configure_ac_cent8 に保存

make できる様になったが、型に関するコンパイルエラーが多数発生。保留とする。

```
autoheader 
aclocal 
automake --add-missing --copy 
autoconf 
```

この後、./configure && make

v1.16.1

リファレンス

* [stackoverflow](https://stackoverflow.com/questions/5593284/undefined-reference-to-ssl-library-init-and-ssl-load-error-strings)
* [automake](https://qiita.com/kagemiku/items/5aed05f7bd70d8035f54)
* [シンボルSSL_library_init](https://stackoverflow.com/questions/39285733/how-to-tell-autoconf-require-symbol-a-or-b-from-lib)
* [automake 大まかな流れを実行](https://heavywatal.github.io/dev/autotools.html)


gSOAP 移行
----------

リファレンス調査

* [issue166](https://sourceforge.net/p/gsoap2/patches/166/)
    * v2.8.98 では、 openssl1.1.1d でコンパイルできない
    * v2.8.100 で対応

yumを用いてgSOAP開発用パッケージをインストールします。本モジュールのsoapcpp2を使用

yum info gsoap-devel　の情報だと v2.8.91 がインストールされる

CentOSの場合

    sudo -E yum install gsoap-devel


https://sourceforge.net/projects/gsoap2/files/gsoap-2.8/gsoap_2.8.109.zip/download

gsoap ディレクトリに移動します

    export GETPERF_HOME=~/work/getperf
    cd $GETPERF_HOME/module/getperf-agent/gsoap

Getperf Webサービスの API 定義ファイルから gSOAP クライアントソースを作成

    soapcpp2 -c -C GetperfServiceSoapcpp2.h

生成されたソースで以下のファイルが必要となり、../src, ../include にコピーします

    cp soapClientLib.c  ./src
    cp soapClient.c     ./src
    cp soapC.c          ./src

    cp soapH.h    ./include
    cp soapStub.h ./include

sourceforgeから必要なソースをダウンロードします。
yumで入れたgSOAPとsourceforgeのバージョンを合わせる必要があり、以下の手順で合わせ込みをします

soapcpp2 -h コマンドでバージョン確認

    soapcpp2 -v

    **  The gSOAP code generator for C and C++, soapcpp2 release 2.8.91
    <中略>

以下、sourceforge サイトをブラウズして、バージョン情報からビルド番号を探します

    https://sourceforge.net/p/gsoap2/code/HEAD/tree/

sourceforge から、上記r2.8.91のビルドは 174 であることが分かります。該当ビルドのソースをダウンロードします。

https://sourceforge.net/p/gsoap2/code/174/tree/gsoap/stdsoap2.c?format=raw
    wget -O stdsoap2.c https://sourceforge.net/p/gsoap2/code/174/tree/gsoap/stdsoap2.c?format=raw
    wget -O stdsoap2.h https://sourceforge.net/p/gsoap2/code/174/tree/gsoap/stdsoap2.h?format=raw

ダウンロードしたソースを include, src ディレクトリにコピーします。

    cp stdsoap2.h ./include
    cp stdsoap2.c ./src

以上で　gSOAP ソースビルドは完了です。後は、getperf-agentホームディレクトリに移動して、ビルドを行います

    cd ..
    ./configure
    make

また、ソースコードのパッケージングファイルは上記 gSOAP 用ソースコードをバンドルしますので、パッケージングしたソースからコンパイルする場合は、上記、gSOAP のソースビルド手順は不要です。

    cd $GETPERF_HOME
    rex make_agent_src
    (中略)
    ARCHIVED: /home/psadmin/getperf/var/docs/agent/getperf-2.x-Build5-source.zip
    # getperf-2.x-Build5-source.zip に gSOAP ソースコードが含まれている

