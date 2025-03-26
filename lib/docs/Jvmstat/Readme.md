# JAVA 監視テンプレート

## 変更履歴

* 2025/3/21
	- モジュール標準化初版作成

## ファイル構成

* エージェント用スクリプト
lib/agent/Jvmstat/

* グラフテンプレート定義保存ディレクトリ
lib/graph/Jvmstat/

* 集計スクリプト保存ディレクトリ
lib/Getperf/Command/Site/Jvmstat/

* ドキュメント保存ディレクトリ
lib/docs/Jvmstat

## 検証方法

### テストデータ作成

サイトディレクトリ移動

```shell
cd site/site1/
```

テストデータ作成

```shell
sumup --test lib/test/Jvmstat/web01/
```

```text
2025/03/23 13:15:03 [INFO] check input test data : lib/test/Jvmstat/web01/
2025/03/23 13:15:03 [INFO] test data create: analysis/web01/Jvmstat/20250323/130000/java_vm_list.yaml
2025/03/23 13:15:03 [INFO] test data create: analysis/web01/Jvmstat/20250323/130000/jstatm.txt
2025/03/23 13:15:03 [INFO] test data create: analysis/web01/Jvmstat/20250323/130000/stat_Jvmstat.log

```

テストデータ集計

```shell
sumup analysis/web01/Jvmstat/20250323/130000/jstatm.txt
```

```text
2025/03/23 13:20:21 [INFO] command: /web01/Jvmstat/20250323/130000 Site::Jvmstat::Jstatm
TEST
CATALINA_PATH:/home/k1webusr/tomcat8.5/tomDB2_102
TEXT:Apache Tomcat - tomDB2_102
CATALINA_PATH:/home/k1webusr/tomcat8.5/tomDB2_104
...
TEXT:Apache Tomcat - tomDB2_105
2025/03/23 13:20:21 [INFO] [RRDCache] load 20250323/130000 web01/device/jstat 35
2025/03/23 13:20:21 [INFO] [RRDFlush] load row=35, error=(0/0/0)
2025/03/23 13:20:21 [INFO] sumup : files = 1, elapse = 0.203554

```

### グラフ登録

グラフテンプレート作成

```shell
cacti-cli -f -g lib/graph/Jvmstat/jstat.json
```

グラフ登録

```shell
cacti-cli node/Jvmstat/web01/
```

```text
Retrieve node '/Jvmstat/web01'.
Generate Graph : Jvmstat, web01, Jvmstat - Java VM - Heap usage
Host (Jvmstat - web01) Created - host_id: (8)
        OK
Generate Graph : Jvmstat, web01, Jvmstat - Java VM - GC
        OK
Generate Graph : Jvmstat, web01, Jvmstat - Java VM - GC Util
        OK
Elapse : 10.063364982605

```

