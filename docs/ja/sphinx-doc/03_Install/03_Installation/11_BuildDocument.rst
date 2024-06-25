ドキュメント作成
================

.. note::

   オンラインドキュメントを利用する場合は、本手順でドキュメントを作成ます。
   不要な場合は本ページはスキップしてください。

Python のドキュメント作成ツール Sphinx を用いて HTML ドキュメントを作成します。

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

Python pip パッケージをインストールします

::

   sudo -E dnf install python3-pip

以下 pip コマンドを使用して Sphinx をインストールします。

::

   sudo -E pip3 install sphinx


HTMLドキュメントの生成
----------------------

.. note::

   エージェントコンパイル作業を省略し、エージェント用ダウンロードサイトを作成していない場合は以下を実行してください

   ::

      sudo -E rex prepare_agent_download_site

以下のコマンドでビルドします。

::

   cd $GETPERF_HOME/docs/ja/sphinx-doc
   make html

該当ディレクトリの下の、_build/html を /var/www/html の下にリンクします。
絶対パスでの指定が必要なため、カレントディレクトリを確認して、ln -s コマンド
に指定します。

::

   # 絶対パス指定で、/var/www/html/getperfにリンク作成 
   ln -s /home/psadmin/getperf/docs/ja/sphinx-doc/_build/html/ \
   /var/www/html/getperf


ビルドしたHTMLをブラウザから確認します。

::

   http://{監視サーバ}/getperf/

