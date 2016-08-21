IPython Notebook 環境の構築
===========================

Webブラウザを用いた対話型 Python 開発ツール IPython Notebook をインストールします。

Python 統合パッケージ Anaconda インストール
-------------------------------------------

Python 統合パッケージの Anaconda インストールします。Anaconda は一般ユーザのホームディレクトリ下に
環境を構築するため、OS環境を変更せずに Python パッケージのインストールが可能となります。
以下の開発元サイトから PYTHON 2.7 Linux 64-bit を選んでパッケージをダウンロードします。

http://www.continuum.io/

ダウンロードしたパッケージファイルを sh で起動してインストーラを起動します。デフォルトの設定でインストールを進めます。
$HOME/anaconda2 がモジュールのホームディレクトリとなります。.bash_profile を再読み込みしてAnaconda 用の環境変数を読み込みます。

::

	source ~/.bash_profile

Python のパッケージインストーラ pip をアップグレードします。

::

	pip install --upgrade pip

pip でGraphite用 Python ライブラリをインストールします。

::

	pip install influxdb

IPython Notebook セットアップ
--------------------------------

IPython Notebook は Anaconda パッケージにバンドルされており、既に利用できます。
ここでは IPython Notebook 用のプロファイラを作成して設定します。default という規定のプロファイラを作成します。

::

	ipython profile create default

作成したプロファイラの設定ファイルを編集します。

::

	vi ~/.ipython/profile_default/ipython_config.py

最終行に以下を追加して、起動時に各種ライブラリを自動でロードするようにします。

::

    c.InteractiveShellApp.exec_lines = [
        "import numpy as np",
        "import pandas as pd",
        "import matplotlib.pyplot as plt",
        "from influxdb import DataFrameClient",
        "plt.rcParams['figure.figsize'] = (14, 8)",
        "%matplotlib inline"
    ]

以上でセットアップは終了です。IPython Notebook 起動用スクリプトで動作確認をします。
起動時のカレントディレクトリが IPython Notebook のホームディレクトリになりますので開発用ディレクトリに移動してからスクリプトを起動してください。試しに ~/work/tmp ディレクトリを作成して起動します。

::

	mkdir ~/work/tmp
	cd ~/work/tmp
	ipython_notebook.sh

Web ブラウザから以下のURLをアクセスします。

::

	http://{監視サーバ}:8888/

ブラウザの画面の右上の New メニューから Python2 を選択します。


