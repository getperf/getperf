集計例
======

以下にデータ集計のカスタマイズ事例のトピックスを記します。

ノード定義に静的な情報を追加するには
-------------------------------------

ノード定義にOS名など、時系列データではない情報を登録します。
例として、監視対象の　Linux の OS 情報を登録する手順を記します。
サイト初期化時に標準の情報採取として SystemInfo というカテゴリで Linux のOS情報ファイル(/etc/issue)の採取例を示します。

例: analysis/{監視対象}/SystemInfo/20151114/180000/os\_info.txt

::

    CentOS release 6.6 (Final)
    Kernel \r on an \m

採取結果はノード定義ファイルの node/{ドメイン}/{監視対象}/info　ディレクトリの下に記録します。
そのスクリプトは以下の通りです。注意点をコメントしています。

例：
OS情報の登録スクリプト(lib/Getperf/Command/Site/SystemInfo/OsInfo.pm)

::

    package Getperf::Command::Site::SystemInfo::Issue;
    use warnings;
    use FindBin;
    use base qw(Getperf::Container);

    sub new {bless{},+shift}

    sub parse {
        my ($self, $data_info) = @_;

        open( IN, $data_info->input_file ) || die "@!";
        my $line = <IN>;
        $line=~s/(\r|\n)*//g;   # trim return code
        $line=~s/\s*(\\r|\\m|\\n).*//g; # trim right special char
        close(IN);

        my $host = $data_info->host;
        # 1. ノード定義の連想配列
        my %stat = (
            issue   => $line,
        );
        # 2. ノード定義の登録
        $data_info->regist_node($host, 'Linux', 'info/os', \%stat);

        return 1;
    }
    1;

1. 受信データから取得したOS情報を連想配列に登録します
2. ノード定義に連想配列を登録します。引数に、ノード、ドメイン、ファイルパス、連想ファイルを指定します。ファイルパスは　'info/{メトリック}'の形式で指定します。

実行すると、ノード定義ディレクトリに info/os.json　というファイルが生成されます。

例：　ノード定義情報(node/Linux/{監視対象}/info/os.json)

::

    {
       "issue" : "CentOS release 6.6 (Final)"
    }

本情報は Cacti グラフのコメントやタイトルの定義で使用します。

階層的にノードをグルーピングするには
------------------------------------

監視対象の場所、用途などでグルーピングをしたい場合にノードパスを使用します。
ノードパスはノード定義の一つで、項目名を　node_path　としてディレクトリを追加して、監視対象を指定します。
例えば、DBというカテゴリを監視対象に追加したい場合は以下のコードを追加します。

例: ノード定義登録情報の例

::

        my %stat = (
            node_path => "/DB/$host",
        );
        $data_info->regist_node($host, 'Linux', 'info/node', \%stat);

regist_node()の第三引数の info の後の名前はnode_path のベースファイル名となり任意で構いません。
上記結果は以下となります。

::

    cat node/{監視対象}/info/node.json
    {
        "node_path": "/DB/{監視対象}"
    }

本情報は Cacti　のグラフ登録のグルーピングで使用します。

ビューによるフィルタリング
------------------------------------------

特定のノードのみを絞り込む場合にビューを使用します。
view ディレクトリの下がビューの定義となり、'view/{テナント}/{ドメイン}/{ノード}.json' という構成で管理します。
テナントはビューのキー情報で、'_default' が規定値となります。
'_default' はノード登録時に自動で作成され、すべてのノードは '_default' に属します。

::

    ls view/_default/Linux/
    linux01.json   linux02.json   linux03.json
    linux11.json   linux12.json   linux13.json

ビューを作成するには、まず新たなテナントのディレクトリを作成します。
作成したディレクトリの下にそのテナントに属するノードを _default からコピーします。
以下例ではlinux01, linux02 のノードを tenant01 に属する定義となります。

::

    mkdir -p view/tenant01/Linux/
    cp view/_default/Linux/linux01.json view/tenant01/Linux/
    cp view/_default/Linux/linux02.json view/tenant01/Linux/

作成したビュー定義は後述のCactiグラフ登録で使用します。

