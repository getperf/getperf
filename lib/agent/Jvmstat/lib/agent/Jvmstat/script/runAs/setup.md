# Windows で実行ユーザが「System」ユーザ以外のJavaプロセスの監視設定

　Windows JavaVM監視で、実行ユーザが「System」ユーザではない場合、
アクセス制限の制約によりデータ採取が出来ない問題があります。
その場合、以下の別ユーザに変えて採取コマンドを実行する設定を行います。

* JetBrains 社の JetBrains.runAs ツールを用いて実行ユーザの変更して採取
  コマンドを実行します
* エージェントの設定ファイルの記述に上記実行ユーザ変更のコマンドをかまして、
  実行ユーザを Java 実行ユーザに変えて採取コマンドを実行します

** JetBranis.runAs　とは**

別ユーザにスイッチして、コマンドを実行するツールとなります。
[JetBranis.runAs GitHub サイト][1] からダウンロード可能です。
OS標準の runas コマンドと同様のツールとなりますが、
OS 標準では実行できない service 実行下のプロセスでも利用できる
ツールとなります

[1]:https://github.com/JetBrains/runAs

## セットアップ方法

同ディレクトリ下に JetBrains社の JetBrains.runAs ツールを配布します

    c:\ptune\script\runAs

JetBrains runAs 開発 GitHub サイトから、ページ最下部の runAs tool for windows の x64, x86 をダウンロードします


    https://github.com/JetBrains/runAs


該当フォルダーにバイナリコピーし、ファイル名を以下に変更します。

    JetBrains.runAs.x64.exe  # 64ビット版
    JetBrains.runAs.x86.exe  # 32ビット版

同フォルダにREADME.md と Wiki ページも同様にダウンロードします。

    https://github.com/JetBrains/runAs.wiki.git

ダウンロード後は、以下のようなディレクトリ構成になります。

    dir

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       2019/04/25      8:38         492544 JetBrains.runAs.x64.exe
    -a----       2019/04/25      8:38         359936 JetBrains.runAs.x86.exe
    -a----       2019/04/24     13:24           3114 README.md
    -a----       2019/04/25      8:46           4190 runAs-tool.md

## 利用方法

通常の手順で JavaVM 監視モジュールのセットアップを行います。

エージェントのスケジュール設定で以下の変更を行います。

    cd c:\ptune
    notepad .\conf\Jvmstat.ini


最終行の以下の行を編集してください。

### 監視対象 Java 実行ユーザが 「System」の場合

以下の1行目のコメントアウトを削除して、2行目の runAs の記載がある行をコメントアウトしてください。

```
STAT_CMD.Jvmstat = '_script_\jstatm.bat -p _odir_\java_vm_list.yaml -o _odir_\jstatm.txt 60 5'
; STAT_CMD.Jvmstat = '_script_\runAs\JetBrains.runAs.x64.exe -u:.\administrator -p:P@ssw0rd _script_\jstatm.bat -p _odir_\java_vm_list.yaml -o _odir_\jstatm.txt 60 5'
```

### 監視対象の Java 実行ユーザが 「System」以外の場合

以下の1行目をコメントアウトして、次の runAs の記載のある行のコメントアウトを削除し、以下のオプションの実行ユーザの設定を変更してください。

* -u:{ドメイン名\\実行ユーザ} (既定値 : 「.\\administrator」)
* -p:{パスワード} (既定値 : 「P@ssw0rd」)

```
; STAT_CMD.Jvmstat = '_script_\jstatm.bat -p _odir_\java_vm_list.yaml -o _odir_\jstatm.txt 60 5'
STAT_CMD.Jvmstat = '_script_\runAs\JetBrains.runAs.x64.exe -u:.\administrator -p:P@ssw0rd _script_\jstatm.bat -p _odir_\java_vm_list.yaml -o _odir_\jstatm.txt 60 5'
```

設定を反映するためエージェントを再起動します。

```
c:\ptune\bin\getperfctl stop
c:\ptune\bin\getperfctl start
```

起動後、c:/ptune/log/Jvmstat/下に採取データが保存されいるか、c:/ptune/_log/getperf.log にエラーがないかを確認します。

この後の手順は従来の Java 監視手順と同じです。

