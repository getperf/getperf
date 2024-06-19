sudo -E yum install openssl-devel redhat-lsb-core expat-devel
Apacheインストール
sudo -E yum -y install apr-devel apr-util apr-util-devel

Getperfホームディレクトリに移動し、Apache インストールコマンドを実行します。

sudo -E rex prepare_apache
sudo /usr/local/apache-admin/bin/apachectl restart
sudo /usr/local/apache-data/bin/apachectl restart
sudo -E rex prepare_tomcat
rex prepare_tomcat_lib

Axis2 管理画面のアクセスが確認できたら、Getperf Web サービスをデプロイします。

sudo -E perl ./script/deploy-ws.pl config_axis2 --suffix=admin
sudo -E perl ./script/deploy-ws.pl config_axis2 --suffix=data
sh $GETPERF_HOME/script/axis2-install-ws.sh /usr/local/tomcat-admin
sh $GETPERF_HOME/script/axis2-install-ws.sh /usr/local/tomcat-data
rex restart_ws_admin
rex restart_ws_data

ls -l       module/getperf-ws/build/libs/getperf-ws-1.0.0-all.jar
./script/../module/getperf-ws/build/libs/getperf-ws-1.0.0-all.jar

sudo cp -p ./script/../module/getperf-ws/build/libs/getperf-ws-1.0.0-all.jar /usr/local/tomcat-admin/webapps/axis2/WEB-INF/services

Axis2 管理用 http://{監視サーバIPアドレス}:57000/axis2/
Axis2 データ受信用 http://{監視サーバIPアドレス}:58000/axis2/

sudo -E rex svc_auto

[2023-06-16 19:29:39] INFO - OS (AlmaLinux) not supported

自動起動が利かない。保留にする

rex svc_start

