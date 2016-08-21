VMWare ESXiホスト毎の相関分析
=========================

アプローチ
=======

* 各ESXiホストのCPU使用率の相関分析を行う
* iPython notebook使用。 ipython_notebook.sh を起動し、メッセージ出力された URL から　Webアクセス
* ソースにGraphiteを使用
* 分析モデルが単純すぎてあまり有効な分析とならないが、グラフによる確認ができる

手順
=====

パッケージ読み込み。Graphite データ取得関数定義

	# プロキシーの設定を無効化してIPython Notebook を起動する必要がある
	# unset HTTP_PROXY
	# unset HTTPS_PROXY
	# unset http_proxy
	# unset https_proxy
	#
	# ipython notebook --no-browser --ip=0.0.0.0 --port=8888 --profile=nbserver

	%matplotlib inline
	import urllib2, pickle
	import pandas as pd
	import numpy as np
	import matplotlib.pyplot as plt

	# Graphite データ取得
	class GraphiteCollector:
		def __init__(self, host, target):
			self.cache_file = '/tmp/tmp.pickle'
			self.url = 'http://%s:8081/render?target=%s&format=pickle' % (host, target) 

		def store_data(self):
			response = urllib2.urlopen(self.url)
			with open(self.cache_file, 'wb') as file:
				file.write(response.read())

		def read_data(self):
			with open(self.cache_file) as file:
				data = pickle.load(file)
				return data

ESXi ホストの情報取得(Host.*.cpu.coreUtilization)

	#host        = 'ostrich'
	#temp_file   = '/tmp/tmp.pickle'
	#target      = 'Linux.*.vmstat.us'
	host        = '10.45.213.198'
	target      = 'Host.*.cpu.coreUtilization'

	res = GraphiteCollector(host, target)
	res.store_data()
	lists = res.read_data()

ホストリスト出力。'Host.*.cpu.coreUtilization' から、2列目の '**'の箇所を抽出

	hosts = [list['name'] for list in lists]
	hosts = map(lambda x:x.split(".")[1], hosts)
	print(hosts)

各ホストのCPU使用率統計値(count, mean, std, min, 25%, 50%, 75%, max) 出力

	datas = np.array([map(lambda x:0 if x is None else x, list['values']) for list in lists])
	df = pd.DataFrame(datas.T, columns=hosts)
	print df.describe()

相関図作成

	from pandas.tools.plotting import scatter_matrix
	host2 = hosts[0:5]
	data2 = datas[0:5]
	df = pd.DataFrame(data2.T, columns=host2)
	_ = scatter_matrix(df, alpha=0.2, figsize=(12, 12))
