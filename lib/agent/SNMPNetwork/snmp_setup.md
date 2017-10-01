SNMP+Zabbix連携
===================================

リファレンス
===================================

https://blog.apar.jp/linux/139/

パッケージインストール
===================================

NET-SNMP のインストール
-----------------------------------

	sudo -E yum -y install net-snmp net-snmp-perl

SNMPTT のインストール
-----------------------------------

EPELリポジトリの追加（SNMPTTのインストールに必用です） 

	sudo -E rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm 
	sudo -E rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6

SNMPTTのインストール（1.4-0.9.beta2）※バージョンは2015年3月11日時点のものです。

	sudo -E yum -y install snmptt


snmptrapd の設定
-----------------------------------

	sudo vi /etc/snmp/snmptrapd.conf

(下記を追加)

	authCommunity   log,execute,net s3vlyda4
	perl do "/usr/share/snmptt/snmptthandler-embedded";

authCommunity の「s3vlyda4」がSNMPのコミュニティ名です。コミュニティ名はSNMPのパスワードに該当するものですので、 ある程度複雑なものを設定することをオススメします。

起動

	sudo service snmptrapd start

自動起動設定

	sudo chkconfig snmptrapd on

SNMPTT の設定
-----------------------------------

日時の書式をZabbix用に設定します。また SNMPTT の syslog 出力はOFFにしておきます。（syslog には snmptrapd が出力します）

	sudo vi /etc/snmp/snmptt.ini

(下記を変更)

	#date_time_format = 
	　↓ 
	date_time_format = %H:%M:%S %Y/%m/%d 

	syslog_enable = 1 
	　↓ 
	syslog_enable = 0
 
オリジナルのトラップ書式をバックアップします。

	sudo mv -i /etc/snmp/snmptt.conf /etc/snmp/snmptt.conf.org

トラップの書式をZabbix用に設定します。

	sudo vi /etc/snmp/snmptt.conf

(下記を追加)

	# 
	# Zabbixテスト用
	# 
	EVENT general .* "General event" Normal 
	FORMAT ZBXTRAP $aA $ar $1

起動

	sudo service snmptt start

自動起動設定

	sudo chkconfig snmptt on

snmptrapd 起動オプションの変更

SNMPTTのドキュメントによると、snmptrapd 起動オプションを -On に変更することが推奨されています。 これは UCD-SNMP / NET-SNMPのバージョンによっては、MIBのオブジェクトIDとシンボル名が正しく変換されない場合があるためのようです。

	sudo vi /etc/rc.d/init.d/snmptrapd

(下記を変更)

	OPTIONS="-Lsd -p /var/run/snmptrapd.pid" 
	　↓ 
	OPTIONS="-On -Lsd -p /var/run/snmptrapd.pid"

「-Lsd」は syslog(-Ls) に LOG_DAEMON(-d)ファシリィティで出力するためのオプションです。

snmptrapd を再起動

	sudo service snmptrapd restart

動作確認
===================================

以上で snmptrapd と SNMPTT の設定が完了しました。Zabbix の設定をする前にSNMPトラップを受信して、正しくトラップファイルに書き込まれていることを確認します。

SNMPエージェント側
------------------------------------

SNMPトラップを送信するため、SNMPエージェントとなるサーバに snmptrap コマンドをインストールします。

	sudo -E yum -y install net-snmp-utils

SNMPトラップを送信します。（root権限で実行してください）

	sudo snmptrap -v 2c -c s3vlyda4 localhost '' .1.3.6.1.4.1.8072.9999 .1.3.6.1.4.1.8072.9999 s 'TEST'
 
・snmptrapコマンドの書式

	snmptrap -v ＜SNMPバージョン＞ -c ＜コミュニティ名＞ ＜ZabbixサーバのIPアドレス＞ '' ＜OID＞ ＜OID＞ s '＜値＞'　

Zabbixサーバ側
------------------------------------

Zabbixサーバの snmptrapd がトラップを正常に受信しているかを確認します。

	sudo tail -f /var/log/messages

(ログを確認)

	Jul 30 05:41:17 paas snmptrapd[3393]: 2015-07-30 05:41:17 localhost [UDP: [127.0.0.1]:57886->[127.0.0.1]]:#012.1.3.6.1.2.1.1.3.0 = Timeticks: (144681) 0:24:06.81#011.1.3.6.1.6.3.1.1.4.1.0 = OID: .1.3.6.1.4.1.8072.9999#011.1.3.6.1.4.1.8072.9999 = STRING: "TEST"


SNMPTT がトラップの書式を整えてトラップファイル(SNMPTTのログファイル)へ書込んでいるか確認します。

	sudo tail -f /var/log/snmptt/snmptt.log

(ログを確認)

	05:40:32 2015/03/11 .1.3.6.1.4.1.8072.9999 Normal "General event" 172.16.1.20 - ZBXTRAP 172.16.1.20 172.16.1.20 TEST

上記のようなログが出力されていればOKです。

Zabbixサーバの設定
------------------------------------

SNMPトラッパーを有効にします。

	sudo vi /etc/zabbix/zabbix_server.conf

(下記を変更)

	# StartSNMPTrapper=0 
	　↓ 
	StartSNMPTrapper=1 

・再起動

	sudo service zabbix-server restart

SNMPトラップ監視テンプレートの作成
------------------------------------

[設定]→[テンプレート]→[テンプレートの作成]をクリックします。

[テンプレート]タブを選択　下記を入力し「追加」をクリックすればテンプレートが作成されます。
テンプレート名： A_Template_SNMP_Trap 　グループ： A_Templates グループを作成する

SNMPトラップ監視アイテムの作成

[設定]→[テンプレート]　「 A_Template_SNMP_Trap 」行の「アイテム」をクリックします。

「アイテムの作成」をクリックします。

下記を入力/選択し「追加」をクリックすれば SNMPトラップ監視アイテムの作成完成です。

(設定箇所)

	名前：SNMPトラップ（テスト用）
	タイプ：SNMPトラップ
	キー：snmptrap["General"]
	データ型：文字列
	アプリケーションの作成：snmp

※キー snmptrap の引数は必ずダブルクオート「"」で括ってください。シングルクオート「'」で括ると正しく動作しません。

ホストの設定
------------------------------------

[設定]→[ホスト]　SNMPエージェントのホストをクリックします。

「ホスト」タブを選択して、SNMPインターフェースの「追加」をクリック、IPアドレスを入力します。

自ホストなので127.0.0.1とする <==== リモートでtrapする場合はローカルIP以外にする

[テンプレート]タブを選択し、[選択]をクリックします。

作成したトラップ監視テンプレートにチェックを入れて[選択]をクリックします。

[追加]をクリックします。

「テンプレートとのリンク」にトラップ監視テンプレートが表示されていることを確認し「更新」ボタンをクリックすればホストの設定完了です。

動作確認
------------------------------------

SNMPエージェントからSNMPトラップを送信します。

[監視データ]→[概要]　タイプをデータにして「SNMPトラップ（テスト用）」の値をクリック→「最新の値」を選択します。

トラップの内容がZabbixに記録されていることが確認できます。


