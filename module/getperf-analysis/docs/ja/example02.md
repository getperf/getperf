VMWare ESXiホスト毎の相関分析(libgraphite版)
=========================

アプローチ
=======

* 前述の分析例と同じで、libgraphite ライブラリを使用する

手順
=====

ライブラリインポート

	# はじめに Python ライブラリの読み込み。初期設定。
	# iPython notebook のプロファイル機能を用いてサービス起動時に自動読込することも可能

	import matplotlib
	import numpy as np
	import pandas as pd
	import matplotlib.pyplot as plt
	import libgraphite as lg

	# グラフのインライン表示有効化とサイズの設定
	%matplotlib inline  
	plt.rcParams['figure.figsize'] = (14, 8)

Graphiteデータロード

Cactiサーバ上のGraphite蓄積データを検索して、pandas データフレームにロード libgraphiteというパッケージを使用。Graphite には REST API でアクセスする

	# Graphite 接続先
	graphite = 'http://ostrich:8081'

	# 過去3日間の ESXi ホストの cpu.coreUtilization を取得
	df = lg.Query(graphite) \
	        .target('aliasByNode(Linux.*.loadavg.load1m, 1)') \
	        .pfrom('-3d') \
	        .execute()
	df.head()

データの整形。分析し易い様にデータの整形をしていく。

	# index が UNIXタイムスタンプのepoch値になるので、文字列に変換
	df.index = pd.to_datetime(df.index,unit='s')
	_ = df.plot()

統計値の計算。float型にするとより色々な統計値が出る

	df2 = df.astype(float)
	df2.describe()

ヒストグラムの描画

	_ = df2.hist( sharex=True, sharey=False)

相関分析

	df = lg.Query(graphite) \
	        .target('aliasByNode(Host.m124-ccus-0*.cpu.coreUtilization, 1)') \
	        .pfrom('-14d') \
	        .execute()
	df.head()
	df = df.astype(float)
	df.corr()

より複雑なグラフ。各サーバ毎の散布図

	from pandas.tools.plotting import scatter_matrix
	_ = scatter_matrix(df2)

今後の展開
==============

1. pandas データ操作
    * スライシング
    * ピボットテーブル
    * ダウンサンプリング、アップサンプリング
    * 欠損値の補間
2. 分析ライブラリ
    * 相関分析
    * 回帰分析
3. グラフ描画ライブラリ
    * sparkline
    * heatmap
