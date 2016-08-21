Linux版 エージェントセットアップ
================================

Linux 版 Cacti エージェントセットアップ
---------------------------------------

Linuxのセットアップは一般ユーザで行います。
一般ユーザにログインしてホームディレクトリに移動します

cd $HOME

集計サーバのダウンロードサイトから対象プラットフォームを選択してモジュールをダウンロードします。

wget http://10.152.32.104/download/getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

> 他プラットフォームも http://10.152.32.104/download/ からダウンロードできます
> 本例では、CentOS6 の 64 bit 版を選択します

モジュール解凍

tar xvf getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

サイトキー、キーコードを指定して、セットアップ実行

~/ptune/bin/getperfctl setup --key=peyok02 --pass=62b9ae87374334d39e0dc497ebd1b59638d8449c

> (注)サイトキー、キーコードを忘れた場合は集計サーバのサイトディレクトリ下で以下のコマンドで確認できます
> cd /catai/peyok02; sumup --info

デフォルト設定として、連続して ENTER キー入力。更新しますかの確認で y を入力して設定完了

サービス起動

~/ptune/bin/getperfctl start

サービス起動確認。該当プロセスが存在するか確認します

ps -ef | grep _getperf

Linux 版 Zabbix エージェントセットアップ
----------------------------------------

zabbix設定ファイル作成スクリプト実行。ptuneの下にzabbix_agentd.confファイルが生成されます

~/ptune/script/zabbix/update_config.sh

エージェント起動

~/ptune/bin/zabbixagent start

サービス起動確認

ps -ef | grep zabbix_agent

OS起動時の自動起動設定
----------------------

root ユーザでの実行が必要。
root 権限を所有していれば、root にスイッチユーザして作業継続。
root 権限がない場合は以下は保留としてユーザに設定依頼をする。
既にサービスは起動されているため、この後の集計サーバ側の設定は継続できる。

perl (ptune ホームディレクトリ)/bin/install.pl --all

設定内容を確認して、y を入力

以上でエージェント側設定は完了し、その後に集計サーバ側設定を行います

Windows版 エージェントセットアップ
==================================

Windows 版 Cacti エージェントセットアップ
-----------------------------------------

c:\直下に設定します
スタートアップメニューからコマンドプロンプトを選択し、右クリック管理者権限で起動します

cd /d c:\

IEなどブラウザから集計サーバのダウンロードサイト http://10.152.32.104/download/ を開き、
以下モジュールを c:\ の直下に保存します。

getperf-zabbix-Build4-Windows-MSWin32.zip

> 他プラットフォームも  からダウンロードできる

モジュール解凍

エクスプローラを開き、 フォルダーを c:\ に移動し、ダウンロードしたモジュールを c:\ に解凍

> 右クリックして解凍を選択。解凍先は c:\ に修正する

サイトキー、キーコードを指定して、セットアップ実行

cd \ptune\bin
.\getperfctl setup --key=peyok02 --pass=62b9ae87374334d39e0dc497ebd1b59638d8449c

デフォルト設定として、連続して ENTER キー入力。更新しますかの確認で y を入力して設定完了

サービス起動設定(Windowsサービスへの登録)

.\getperfctl install

サービス起動

.\getperfctl start

起動の確認は、 c:\ptune\log の下に提起起動コマンドの実行結果が保存されるので起動した時刻に各ファイルが
生成されているか確認

Windows 版 Zabbix エージェントセットアップ
----------------------------------------

zabbix設定ファイル作成スクリプト実行。ptuneの下にzabbix_agentd.confファイルが生成される

cd C:\ptune\script\zabbix
update_config.bat

エージェントのサービス設定と起動確認。以下のスクリプトでWindowsサービスの登録を行い、起動の設定をします

setup_agent.bat

サービス起動確認

c:\直下に、 zabbix_agent.log が生成される。エディタでログを開いてagent #<n> started が出力されていることを確認

> Windows の場合は、各エージェントのサービス起動設定を合わせて行うので、OS起動時の自動起動設定を
> 別途行う必要はありません。

以上でエージェント側設定は完了し、その後に集計サーバ側設定を行います

以上、
