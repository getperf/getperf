ドキュメント作成
================

.. note::

   オンラインドキュメントを利用する場合は、本手順でドキュメントを作成ます。
   不要な場合は本ページはスキップしてください。

Python のドキュメント作成ツール Sphinx を用いてHTMLドキュメントを作成します。

Miniconda インストール
----------------------

Python ディストリビューション Miniconda をインストールします。
以下のダウンロードサイトから最新のインストールモジュールをダウンロード
して $HOME/miniconda3 下にインストールします。

::

   cd /tmp
   wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh

「accept the license terms?」 の入力を yes に、「conda init?」 の 入力を yes に変更します。それ以外の入力は既定値のままにして、 インストールを実行します。

設定を反映させるために、~/.bashrc を再読み込みします。

::

   source ~/.bashrc

Sphinx のインストール
---------------------

.. note::

   プロキシー環境下での pip コマンド実行時に、 SSL 証明書の認証エラー VERIFY_CERTIFICATE_ERROR
   が発生する場合があります。その場合は、以下の設定ファイルにサービスホストの設定をしてください。

   ::

      mkdir ~/.pip
      vi ~/.pip/pip.conf

   ::

      [global]
      trusted-host = pypi.python.org
                     pypi.org
                     files.pythonhosted.org


以下 pip コマンドを使用して Sphinx をインストールします。

::

   pip install sphinx


HTMLドキュメントの生成
----------------------

.. note::

   エージェントコンパイル作業を省略し、エージェント用ダウンロードサイトを作成していない場合は以下を実行してください

   ::

      sudo -E rex prepare_agent_download_site

.. .. note::

..    最新の Sphinxは Python2.7 以上をサポートとなるため、OS標準の Python2.6で実行すると、
..    "ERROR: Sphinx requires at least Python 2.7 or 3.4 to run."のエラーが出ます。
..    対処として、以下コマンドで一時的に Python2.7を実行できる環境を作ります。

..    ::

..       sudo -E yum -y install centos-release-scl-rh
..       sudo -E yum -y install python27

..    次のコマンドを実行するとテンポラリでphython2.7が使えるようになります。

..    ::

..       scl enable python27 bash

以下のコマンドでビルドします。

::

   cd $GETPERF_HOME/docs/ja/sphinx-doc
   make html

該当ディレクトリの下の、_build/html を /var/www/html の下にリンクします。
絶対パスでの指定が必要なため、カレントディレクトリを確認して、ln -s コマンド
に指定します。

::

   # カレントディレクトリ確認
   pwd
   /home/psadmin/getperf/docs/ja/sphinx-doc

   # 絶対パス指定で、/var/www/html/getperfにリンク作成 
   ln -s /home/psadmin/getperf/docs/ja/sphinx-doc/_build/html/ \
   /var/www/html/getperf


ビルドしたHTMLをブラウザから確認します。

::

   http://{監視サーバ}/getperf/

