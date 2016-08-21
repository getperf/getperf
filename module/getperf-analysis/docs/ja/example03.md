ストレージI/O分析
==================

アプローチ
=======

* 共有ストレージのコントローラのWriteレスポンスと各LUの以下指標との相関を分析する
  * Writeレスポンス(wrs)
  * Readレスポンス(rws)
  * Write転送量(kw_s)
  * Read転送量(kw_s)

**注意事項**
    ロケールの問題で時刻が-9時間ずれる現象が発生しています。グラフの時刻は9時間足してみてください。

手順
=====

ライブラリ読み込み

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

Graphite データロード

	# Graphite 接続先
	graphite = 'http://localhost:8081'

	# 過去1日間のWriteレスポンス
	df = lg.Query(graphite) \
	        .target('Violin.*.device.vmem_group.*.wrs, 1') \
	        .pfrom('-24h') \
	        .execute()
	df.index = pd.to_datetime(df.index,unit='s')
	df.plot()

過去1日間のコントローラI/O統計

	df = lg.Query(graphite) \
	        .target('Violin.*.device.vmem_group.*.*_s, 1') \
	        .pfrom('-24h') \
	        .execute()
	df.index = pd.to_datetime(df.index,unit='s')
	_= df.plot( subplots=True, layout=(2,2))

コントローラのWriteレスポンスとLU毎のWriteレスポンスの相関
--------------------------------------------

レスポンスデータをロードして相関分析。相関係数の高い順に出力

	# 過去1日間の書込みレスポンス
	df = lg.Query(graphite) \
	        .target('Violin.*.device.vmem_group.*.wrs, 1') \
	        .target('aliasSub(Violin.*.device.vmem_lun.*.wrs,"^.*vmem_lun(.+)","\1")') \
	        .pfrom('-24h') \
	        .execute()
	df.index = pd.to_datetime(df.index,unit='s')
	df.head()
	df2 = df.astype(float)
	df2 = df2.interpolate(method='linear')
	corr = df2.corr()
	corr2 = corr[0:1].T
	corr3 = corr2.sort_index(by=['Violin.*.device.vmem_group.*.wrs'], ascending=False)
	corr3.head()

上位10位のグラフ

	_= df2.ix[:, corr3.index[0:9]].plot( subplots=True, layout=(5,2))


コントローラのWriteレスポンスとLU毎のReadレスポンスの相関
-------------------------------------------

レスポンスデータをロードして相関分析。相関係数の高い順に出力

	# 過去1日間の読み込みレスポンス
	df = lg.Query(graphite) \
	        .target('Violin.*.device.vmem_group.*.wrs, 1') \
	        .target('aliasSub(Violin.*.device.vmem_lun.*.rrs,"^.*vmem_lun(.+)","\1")') \
	        .pfrom('-24h') \
	        .execute()
	df.index = pd.to_datetime(df.index,unit='s')
	df.head()
	df2 = df.astype(float)
	df2 = df2.interpolate(method='linear')
	corr = df2.corr()
	corr2 = corr[0:1].T
	corr3 = corr2.sort_index(by=['Violin.*.device.vmem_group.*.wrs'], ascending=False)
	corr3.head()

上位10位のグラフ

	_= df2.ix[:, corr3.index[0:9]].plot( subplots=True, layout=(5,2))

コントローラのWriteレスポンスとLU毎のWriteIO量の相関
-------------------------------------------

レスポンスデータをロードして相関分析。相関係数の高い順に出力

	# 過去1日間の読み込みレスポンス
	df = lg.Query(graphite) \
	        .target('Violin.*.device.vmem_group.*.wrs, 1') \
	        .target('aliasSub(Violin.*.device.vmem_lun.*.kw_s,"^.*vmem_lun(.+)","\1")') \
	        .pfrom('-24h') \
	        .execute()
	df.index = pd.to_datetime(df.index,unit='s')
	df.head()
	df2 = df.astype(float)
	df2 = df2.interpolate(method='linear')
	corr = df2.corr()
	corr2 = corr[0:1].T
	corr3 = corr2.sort_index(by=['Violin.*.device.vmem_group.*.wrs'], ascending=False)
	corr3.head()

上位10位のグラフ

	_= df2.ix[:, corr3.index[0:9]].plot( subplots=True, layout=(5,2))

