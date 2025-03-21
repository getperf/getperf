# Oracle 監視テンプレート

## 変更履歴

* 2025/3/21
	- モジュール標準化初版作成

## ファイル構成

* グラフテンプレート作成スクリプト
lib/script/Oracle/create_oracle_graph_template.sh

* グラフテンプレート定義保存ディレクトリ
lib/graph/Oracle/

* 集計スクリプト保存ディレクトリ
lib/Getperf/Command/Site/Oracle/

* ドキュメント保存ディレクトリ
lib/docs/Oracle

## 検証方法

テストデータ作成

sumup --test lib/test/Oracle/ol88ora01/  # AWR監視テストデータ
sumup --test lib/test/Oracle/ol88ora02/  # Statspack監視テストデータ

データ集計。※ 日時ディレクトリは適正な値に修正

sumup analysis/ol88ora01/Oracle/20250321/140000/
sumup analysis/ol88ora02/Oracle/20250321/140000/

グラフ登録

cacti-cli -f node/Oracle/ORAW/ --node-dir /ORAW
cacti-cli -f node/Oracle/ORSP/ --node-dir /ORSP

