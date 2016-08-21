ユーザの作成
===========

sudo権限の付与
------------

rootユーザで、visudoを実行し、以下の行を追加

	{ユーザ名} ALL=(ALL)       NOPASSWD: ALL

.bash_profileファイル編集

環境変数の記述。後で書く

	JAVA_HOME
	CATALINA_HOME
	PERFSTAT_HOME

OS設定
-----------

### プロキシーサーバの設定(必要な場合のみ)
社外プロキシーの設定など必要な場合は記述

#### yum のプロキシー設定
```
sudo vi /etc/yum.conf
```
設定例
```
# Proxy Setting
proxy=http://your.proxy.server:8080
proxy_username=username
proxy_password=password
```

#### wgetのプロキシー設定
```
vi ~/.wgetrc
```
設定例
```
# Proxy Setting
http_proxy=http://your.proxy.server:8080
proxy_user=username
proxy_password=password
```

#### curlのプロキシー設定
```
vi ~/.curlrc
```
設定例
```
proxy-user = "(ユーザ名):(パスワード)"
proxy = "http://proxy.xxx.co.jp:(ポート)"
```

## Getperfインストール
### モジュールダウンロードと解凍
GitHubからダウンロード
```
tar xvf ...
```
環境変数の設定
```
cd $HOME; vi .bash_profile
```
最終行に以下を追加
```
export GETPERF_HOME=$HOME/getperf
```
環境変数読み込み
```
source .bash_profile
```

## 動作確認


```
source /etc/profile.d/maven.sh
```
 
## Perl環境のインストール

Rex 開発元サイト http://www.rexify.org/get を参考にインストール

### cpanmのインストール

perl開発ライブラリをインストール
```
sudo -E yum install perl-devel
```
cpanmを/usr/binの下にダウンロード
```
cd /usr/bin/
sudo -E curl -LOk http://xrl.us/cpanm
sudo -E chmod +x cpanm
```

### Perlライブラリのインストール
cpanfileからGetperfで必要なPerlライブラリを一括インストールする
```
sudo -E cpanm --installdeps .
```

SOAP::Liteで依存エラーがでるが、保留とする。テストフェーズで再実行する

### Rexのインストール

```
sudo -E cpanm Rex
```

### Rex動作確認

```
cd $GETPERF_HOME

rex -T
```

## M/Wのインストール

Rexで以下リストのパッケージを一括インストールする。以下のバージョンを想定している

| パッケージ | バージョン |
|--------|-----------|
|Java    |1.7        |
|gcc     |4.4        |
|Redis   |2.8        |
|MySQL   |5.1        |
|PHP     |5.3        |
|Maven   |3.2        |

### Refileの編集

インストール実行ユーザを指定する(sudo権限が必要)
```
cd $GETPERF_HOME; vi Rexfile
```
実行ユーザとパスワードを編集
```
user "vagrant";
password "vagrant";
```
Rex実行
```
sudo rex prepare
```

### 動作確認
問題なければ、Cコンパイラ、Java、Redis、MySQL、rrdtoolなどが入る。以下で各バージョン確認
```
java -version
gcc -v
redis-cli --version
mysql --version
php -v
mvn -v
```

## SSL自己署名認証局作成

### Rexで実行
Getperf設定ファイルを作成。{GETPERF_HOME}/config/getperf_site.jsonにひな形が作成される

```
cd $GETPERF_HOME
perl t/cre_config.pl
```

ディレクトリパスなど修正が必要な場合は編集する
```
vi config/getperf_site.json
```

Rexfileスクリプトで、/etc/getperf/ssl/ca下にSSL自己署名認証局の各種ファイルを作成

```
sudo rex create_ca
```

生成ファイル確認

```
sudo ls -l /etc/getperf/ssl/ca
```

ca.key が秘密鍵、ca.crt が認証局の証明書となり、後に設定するApacheに組み込む

### サーバ証明書作成

同様にRexでサーバ証明書を作成

```
sudo rex server_cert
```

生成ファイル確認

```
sudo ls -l /etc/getperf/ssl/server
```
server.key が秘密鍵、server.crt がサーバ証明書となる

## Tomcatセットアップ


## サービス起動

MySQL,Redis,Tomcat,Apacheの順にサービスを起動し、OS起動時の自動起動設定をします
```
sudo rex service --command=auto_start
```

## Apacheセットアップ


