gSOAPライブラリビルド手順
====================

概要
=====

gSOAP開発サイトから必要なソースをダウンロードし、gSOAP 用ソースを作成します。

**注意事項**

	gSOAP開発用パッケージは gSOAP ソースを作成する場合に使用します。これらのソースは既存の
	ソースコードにバンドルして提供しているため、既存の gSOAP ソースコードで変更が不要な場合は
	以下手順は不要です。
	また、ソースコードのパッケージングも gSOAP ソースがバンドルされた　tar ファイルを生成するため、
	その場合も以下手順は不要です。

要件
======

gSOAPライブラリで必要なソースは以下となります。

1. gSOAP開発ツールのコードジェネレータ(soapcpp2)で生成
	* src/soapClientLib.c
	* src/soapClient.c
	* src/soapC.c
	* include/soapH.c
	* include/soapStub.c
2. gSOAP開発サイトからダウンロード
	* src/stdsoap2.c
	* include/stdsoap2.h

以下に各ソースの作成、ダウンロード手順を記します。

gSOAP ソースビルド手順
===================

yumを用いてgSOAP開発用パッケージをインストールします。本モジュールのsoapcpp2を使用します

CentOSの場合

	sudo -E yum install gsoap-devel

Ubuntuの場合

	sudo -E apt-get -y install gsoap libgsoap-dev

gsoap ディレクトリに移動します

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

	**  The gSOAP code generator for C and C++, soapcpp2 release 2.8.16
	<中略>

以下、sourceforge サイトをブラウズして、バージョン情報からビルド番号を探します

	https://sourceforge.net/p/gsoap2/code/HEAD/tree/

sourceforge から、上記r2.8.16のビルドは 55 であることが分かります。該当ビルドのソースをダウンロードします。

	wget -O stdsoap2.c https://sourceforge.net/p/gsoap2/code/55/tree/gsoap/stdsoap2.c?format=raw
	wget -O stdsoap2.h https://sourceforge.net/p/gsoap2/code/55/tree/gsoap/stdsoap2.h?format=raw

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

以上、