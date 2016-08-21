ドキュメント作成
===============

ドキュメント作成ツール Sphinx を用いてHTMLドキュメントを作成します。


Sphinx のインストール
-----------------

::

	sudo -E yum -y --enablerepo=epel install python-pip python-setuptools
	sudo -E pip install sphinx

Ubuntuの場合は以下となります

::

	sudo -E apt-get install python-sphinx

HTMLドキュメントの生成
-----------------

エージェントコンパイル作業を省略し、エージェント用ダウンロードサイトを作成していない場合は以下を実行してください

::

	sudo -E rex prepare_agent_download_site

以下のコマンドでビルドします。

::

    cd $GETPERF_HOME/docs/ja/sphinx-doc
    make BUILDDIR=$GETPERF_HOME/var/docs/ html

ビルドしたHTMLをブラウザから確認します。

::

	http://{監視サーバ}/docs/html/

