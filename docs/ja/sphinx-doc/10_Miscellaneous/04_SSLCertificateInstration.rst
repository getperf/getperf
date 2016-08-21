
複数サーバでのSSLルート認証局共有
=========================

監視サーバが複数台あり、ルート認証局を各サーバ間で共有する構成が可能です。監視サーバ1台でルート認証局を作成し、それ以外のサーバは作成したルート認証局をコピーして中間認証局から作成をします。ルート認証局を共有化することによりエージェントに配布する認証局証明書を各サーバごとに作成する必要がなくなります。ここでは既にルート認証局を作成したサーバのコピーをして中間認証局を作成する手順を記します。

既存のSSLルート認証局のコピー
--------------------------

既にSSL認証局を構築積みの監視サーバでプライベートルート認証局のディレクトリのバックアップを取ります。/etc/getperf/ssl/ca 下のファイルを $GETPERF_HOME/var/ssl/ca.tar.gz にアーカイブします。

::

	ssladmin.pl archive_ca

アーカイブファイルを新たに作成する監視サーバにコピーします。

::

	scp $GETPERF_HOME/var/ssl/ca.tar.gz {getperfユーザ}@{監視サーバ}:/tmp/ca.tar.gz

SSL中間認証局の作成
--------------------------

新規に作成する監視サーバでコピーした認証局をルート認証局にして中間認証局から作成します。

初めにSSL認証局用ディレクトリを作成します。

::

	sudo mkdir -p /etc/getperf/ssl
	sudo chown -R {getperfユーザ} /etc/getperf

コピーしたルート認証局アーカイブを/etc/getperf/ssl の下に解凍します。

::

	cd /etc/getperf/ssl
	tar xvf /tmp/ca.tar.gz

中間認証局を作成します。

::

	cd $GETPERF_HOME
	rex create_inter_ca 

以上で中間認証局が/etc/getperf/ssl/interの下に作成されます。
作成した証明書は以下のコマンドで確認します。

::

	openssl x509 -text -in /etc/getperf/ssl/inter/ca.crt

実行結果のIssuer:がコピーしたルート認証局、Subject:が作成した中間認証局の名前になっていることを確認します。

