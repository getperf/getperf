/* 
** GETPERF
** Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/

#ifndef GETPERF_LC_MESSAGE_H

#define GPF_MSG001 "メッセージテスト"
#define GPF_MSG002 "ロードエラー。エラーメッセージを確認してください。セットアップがまだの時は getperfctl setup を実行してください"
#define GPF_MSG003 "既存のプロセスPID=%dを検出しました"
#define GPF_MSG004 "プロセスが終了するまで、%d秒待ちます"
#define GPF_MSG005 "起動中のプロセス(%d)を強制停止しました"
#define GPF_MSG006 "起動中のプロセスは存在しません"
#define GPF_MSG008 "上記プロセスか、_pidファイルの有無を確認して下さい"
#define GPF_MSG011 "ホストの登録情報がありませんでした。登録を開始します"
#define GPF_MSG015 "最新のgetperfが存在します[現ビルド : %d < %d]"
#define GPF_MSG018 "以下のホスト情報を '%s' に送信し、ホストを登録します\n%s"
#define GPF_MSG029 "Windows環境のみで利用するコマンドです。詳細は readme.txt を参照して下さい"
#define GPF_MSG031 "アクセスキーを入力して下さい "
#define GPF_MSG032 "サイトキーを入力して下さい "
#define GPF_MSG034 "セットアップを終了します"
#define GPF_MSG035 "必要なライセンス数がありません"
#define GPF_MSG037 "1～%d までの数値を入力してください"
#define GPF_MSG038 "モジュールをアップデートしますか(y/n) ?"
#define GPF_MSG040 "ホストを登録します。よろしいですか(y/n) ?"
#define GPF_MSG044 "%s stop コマンドでエージェントを停止して下さい"
#define GPF_MSG045 "ユーザ認証に失敗しました。ログイン情報を再度ご確認下さい。ログイン情報を忘れた方はWEBポータルにて再発行手続きをして下さい"
#define GPF_MSG046 "ホストの登録に失敗しました"
#define GPF_MSG047 "ライセンスの有効期限が切れています : %s。ホストを再登録します"
#define GPF_MSG048 "SSLクライアント証明書発行依頼をします。よろしいですか(y/n) ?"
#define GPF_MSG049 "モジュールの更新チェックに失敗しました。継続しますか(y/n) ?"
#define GPF_MSG051 "構成ファイルをダウンロードして、デプロイします。よろしいですか(y/n) ?"
#define GPF_MSG052 "処理を継続しますか(y/n) ?"
#define GPF_MSG053 "ホストの登録情報がありません。セットアップを実行してください"
#define GPF_MSG056 "http_proxy を検出しました。本設定を適用します : %s"
#define GPF_MSG057 "%s 下の構成ファイルを %s にバックアップしました"
#define GPF_MSG058 "構成ファイル [%s] を更新しました"
#define GPF_MSG059 "削除対象としてマークされた場合はOSを再起動する必要があります(http://support.microsoft.com/kb/823942)"
#define GPF_MSG060 "SSLライセンスファイルの初期化をします"
#define GPF_MSG061 "空白文字を含むディレクトリはホームとして利用できません"
#define GPF_MSG063 "SSL接続エラーが発生したため強制停止します : %s"
#define GPF_MSG065 "既に起動しています"
#define GPF_MSG066 "接続先URLとサイトキー設定ファイルを更新します"
#define GPF_MSG067 "採取コマンドリストファイルを更新します"
#define GPF_MSG068 "SSL証明書設定ファイルを更新します"
#define GPF_MSG069 "\n監視用に以下の通りログファイルをスキャンし、モニタリングサイトへ転送します。\n\n・5分間隔で定期定期にログをスキャンし、差分ログを集計サーバに転送します。\n・集計サーバのリソース制約から1回あたりの転送行は%d行までとなり、それ以上の行が発生した場合は、過去の行から読み飛ばします。\n・ログスキャンする対象は '%s' です。\n(アップグレードにより他のログの監視も可能です。)\n"
#define GPF_MSG070 "こりよりログのアクセス検証をします。ログ監視が不要な場合は'n'を選択してください。よろしいですか(y/n) ?"
#define GPF_MSG071 "%s に読み取り権限が無いようです。\n以下手順で、%s ユーザに読み取り権限を付与してから再実行してください。\n\n\n1.ログファイルのアクセス権限を変更します\n\n\tログファイルの所有グループを確認します\n\n\tls -l %s\n\n\t出力結果の4列目が所有グループとなります\n\n\tgetperf 実行ユーザにログ所有グループを含めます\n\n\t/usr/sbin/usermod -a -G root %s\n\t(-G オプションの値はログの所有グループを指定してください)\n\n\t既存ログのパーミッションを変更します\n\n\t/bin/chmod 640 %s\n\n2.logrotateを使用している場合は、パーミッション変更の処理を追加します\n\n\t/etc/logrotate.d/syslogに以下の変更を加えます\n\n\tvi /etc/logrotate.d/syslog\n\tpostrotate\n\t\t/bin/chmod 640 %s\n"
#define GPF_MSG072 "rootユーザで上記設定をしてからログアウトし、ログインしてから再実行してください。処理を継続しますか(y/n) ?"
#define GPF_MSG073 "%s に読み取り権限が無いようです。"
#define GPF_MSG074 "読み取り権限を付与してから再実行してください。再実行しますか(y/n) ?"
#define GPF_MSG075 "Windowsイベントログを監視する場合はadministrator権限が付与されたユーザで実行してください。"
#define GPF_MSG076 "管理用Webサービス接続 %s に失敗しました"
#define GPF_MSG077 "\n%s\n\nにアップデートモジュールをダウンロードしました。以下の手順でモジュールを解凍し、再度、setup を実行してください。\n\ncd %s\nunzip %s"
#define GPF_MSG078 "再登録しますか(y/n) ?"
#define GPF_MSG079 "%s コアモジュールの確認に失敗しました"
#define GPF_MSG080 "ライセンスファイルがありません。ホストを再登録します"
#define GPF_MSG081 "既にホスト登録されています"

#endif
