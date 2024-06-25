エージェントダウンロードサイト作成

rex make_agent_src

mkdir -p ~/work/agent/src
cd ~/work/agent/src
wget http://{サーバアドレス}/docs/agent/getperf-2.x-Build5-source.zip
ソースモジュールを解凍します。

unzip /home/psadmin/getperf/var/docs/agent/getperf-2.x-Build11-source.zip

cd getperf-agent
perl make_header.pl

./configure
make

perl deploy.pl

not found : '/home/psadmin/work/agent/src/getperf-agent/var/zabbix/zabbix_agents_6.0.17.linux2_6.amd64.tar.gz' 


ptune                             # エージェントホームディレクトリ
getperf-zabbix-Buildx-xxx-xxx.tar.gz   # エージェントホームのアーカイブ
upload_var_module.zip             # エージェントホーム、アップデートモジュールのアーカイブ
注釈

下記の not found エラーが出た場合、ガイド目次:インストール＞Zabbixインストール にて保存したモジュール名を、エラーメッセージの内容に合わせてリネームしてください。

not found : '/home/psadmin/work/agent/src/getperf-agent/var/zabbix/zabbix_agents_6.0.17.linux2_6.amd64.tar.gz' at deploy.pl line 338.

vi var/zabbix/Recipe.pl  # Zabbix 0 にしてを無効化

sudo -E cpamn  DBD::mysql

mkdir ~/work
cd ~/work
initsite site2

The site key is "site1" .
The access key is "231664feb420ca7ed093467cf42e7551a5eb4f79" .

ALTER USER 'site1'@'localhost' IDENTIFIED WITH mysql_native_password BY '231664feb420ca7ed093467cf42e7551a5eb4f79';

http://192.168.0.102/site1

mysql 接続エラー

vi /var/www/html/phpinfo.php

<?php

// すべての情報を表示します。デフォルトは INFO_ALL です。
phpinfo();

// モジュール情報だけを表示します。
// phpinfo(8) としても同じです。
phpinfo(INFO_MODULES);

?>

vi /var/www/html/phptest1.php

<?php echo phpversion();


$dsn      = 'mysql:dbname=mysql;host=localhost';
$user     = 'root';
$password = 'getperf';

// DBへ接続
try{
    $dbh = new PDO($dsn, $user, $password);

    // クエリの実行
    $query = "SELECT * FROM INFORMATION_SCHEMA.SCHEMATA";
    $stmt = $dbh->query($query);

    // 表示処理
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        echo $row;
    }

}catch(PDOException $e){
    print("データベースの接続に失敗しました".$e->getMessage());
    die();
}

// 接続を閉じる
$dbh = null;


7.3.20データベースの接続に失敗しましたSQLSTATE[HY000] [2054] The server requested authentication method unknown to the client


MySQL8では、デフォルトの認証方式がcaching_sha2_passwordとなっていますが、PHPのライブラリが対応していないことでエラーとなります。PHPの認証方式はmysql_native_passwordのため、これに戻す事で解決します。
設定確認

まずはSSHで設定を確認します。
    
mysql -u root -p
SELECT user, host, plugin FROM mysql.user;
+------------------+-----------+-----------------------+
| user             | host      | plugin                |
+------------------+-----------+-----------------------+
| site1            | %         | caching_sha2_password |
| mysql.infoschema | localhost | caching_sha2_password |
| mysql.session    | localhost | caching_sha2_password |
| mysql.sys        | localhost | caching_sha2_password |
| root             | localhost | caching_sha2_password |
+------------------+-----------+-----------------------+

#認証方式がcaching_sha2_passwordとなっています。

認証方式が違うので、PHPだとエラーとなります。今回は既存ユーザーとなるので、既存ユーザーの修正コマンドをいれます。

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'getperf';
ALTER USER 'site1'@'localhost' IDENTIFIED WITH mysql_native_password BY '231664feb420ca7ed093467cf42e7551a5eb4f79';

mysql_native_password

sudo vi /etc/my.cnf

[mysqld]
default_authentication_plugin=mysql_native_password

The site key is "site2" .
The access key is "8e0f9ccd49664fa7b0d8042c93f4c61eb4f9b66b" .


Rsync セットアップ

sudo -E yum -y install rsync xinetd  rsync-daemon
mkdir $HOME/site
cd $HOME/site
initsite -f site1


# 事前に /tmp の下に getperf-Build10-CentOS7-x86_64.tar.gz を保存
cd $HOME
tar xvf /tmp/getperf-Build10-CentOS7-x86_64.tar.gz
エージェントのセットアップを行います。

cd ptune/bin/
./getperfctl setup
rsync 設定
サイトの転送データ保存ディレクトリを rsync で同期が取れる様に 設定します。rsyncd.conf ファイルを以下例の様に編集します。

sudo vi /etc/rsyncd.conf
[archive_site2]
path =  /home/psadmin/getperf/t/staging_data/site2/
hosts allow = *
hosts deny = *
list = true
uid = psadmin
gid = psadmin
read only = false
dont compress = *.gz *.tgz *.zip *.pdf *.sit *.sitx *.lzh *.bz2 *.jpg *.gif *.png

rsync 起動

sudo systemctl start rsyncd
sudo systemctl enable rsyncd

rsync疎通確認

cd ~/work/site2
sitesync rsync://192.168.0.102/archive_site2

例で作成した監視サイト site1 の場合、以下を実行します。

cd $HOME/work/site2
sitesync rsync://localhost/archive_site2
正しく実行すると、analysis 下に旧サイトの収集ファイルが保存されます。 この後のデータ集計以降の処理は従来と同じです。

ls analysis/{監視対象}
注釈

sitesync コマンドはサイトホームディレクトリに移動してから実行してください。

cronで定期起動
上記で、sitesyncスクリプトの同作確認ができたら、cron による定期起動の設定をします。

0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd {サイトディレクトリ}; {GETPERFホームディレクトリ}/script/sitesync rsync://{旧監視サーバアドレス}/archive_{サイトキー} > /dev/null 2>&1) &
例で作成した監視サイト site2 の場合、以下を実行します。

0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd /home/psadmin/work/site2; /home/psadmin/getperf/script/sitesync rsync://localhost/archive_site2 > /dev/null 2>&1) &
この後の作業は、グラフ設定となります。

cacti-cli -f -g lib/graph/Linux/diskutil.json 
cacti-cli -f -g lib/graph/Linux/iostat.json 
cacti-cli -f -g lib/graph/Linux/loadavg.json 
cacti-cli -f -g lib/graph/Linux/memfree.json 
cacti-cli -f -g lib/graph/Linux/netDev.json 
cacti-cli -f -g lib/graph/Linux/vmstat.json

cacti-cli -f node/Linux/alma82/
