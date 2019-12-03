SOAP-WSDL 作成
===============

リファレンス
------------

WSDL2Go code generation as well as its SOAP proxy

```
https://github.com/hooklift/gowsdl
```

WSDLセットアップ
----------------

WSDL2Go リポジトリ作成

```
git clone https://github.com/hooklift/gowsdl.git
```

gowsdl コマンドビルド

```
cd gowsdl
make build
ls -l build/gowsdl
```

GetperfService.wsdl を引数にソースコード生成

```
cd ..
cp ~/getperf/module/getperf-agent2/soap/GetperfService.wsdl .
./gowsdl/build/gowsdl  -o getperf.go -p getperf GetperfService.wsdl
```

getperf/getperf.go が生成される

```
cp getperf/getperf.go ~/getperf/module/getperf-agent2/soap/
```

ビルド手順
-----------

```
mkdir ~/go/src/github.com/getperf
```

