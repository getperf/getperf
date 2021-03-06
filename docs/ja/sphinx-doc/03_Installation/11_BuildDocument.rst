ドキュメント作成
================

ドキュメント作成ツール Sphinx を用いてHTMLドキュメントを作成します。


Sphinx のインストール
---------------------

::

   sudo -E yum -y --enablerepo=epel install python-pip python-setuptools
   sudo -E pip install sphinx

Ubuntuの場合は以下となります

::

   sudo -E apt-get install python-sphinx

HTMLドキュメントの生成
----------------------

.. note::

   エージェントコンパイル作業を省略し、エージェント用ダウンロードサイトを作成していない場合は以下を実行してください

   ::

      sudo -E rex prepare_agent_download_site

.. note::

   最新の Sphinxは Python2.7 以上をサポートとなるため、OS標準の Python2.6で実行すると、
   "ERROR: Sphinx requires at least Python 2.7 or 3.4 to run."のエラーが出ます。
   対処として、以下コマンドで一時的に Python2.7を実行できる環境を作ります。

   ::

      sudo -E yum -y install centos-release-scl-rh
      sudo -E yum -y install python27

   次のコマンドを実行するとテンポラリでphython2.7が使えるようになります。

   ::

      scl enable python27 bash

以下のコマンドでビルドします。

::

   cd $GETPERF_HOME/docs/ja/sphinx-doc
   make BUILDDIR=$GETPERF_HOME/var/docs/ html

ビルドしたHTMLをブラウザから確認します。

::

   http://{監視サーバ}/docs/html/

