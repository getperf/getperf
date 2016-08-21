エージェントのコンパイル
========================

Linux
-----

### 必要なパッケージのインストール

   コンパイルに必要なパッケージをインストールします。

   RedHat系Linux(yum)の場合

    sudo yum install gcc
    sudo yum install openssl-devel
    sudo yum install zlib-devel
    sudo yum install perl-File-Copy-Recursive

	Debian/Ubuntu の場合

    sudo apt-get install gcc
    sudo apt-get install libssl-dev
    sudo apt-get install zlib1g-dev
    sudo apt-get install libfile-copy-recursive-perl

### 作業ディレクトリ作成

   $HOME/work/ を作成しその下でコンパイルをする想定で手順を記します。
   
    mkdir ~/work
    cd ~/work
   
### ソースダウンロードと解凍

   [GitHub](http://github.com/) からモジュールをダウンロードします。

    cd (some_directory)
    wget http://some.site.com/docs/download/getperf-2.6.0.tar.gz

   ソースを解凍し、コンパイルします。
   
    tar xvf getperf-2.6.0.tar.gz
      
### ソースコンパイル

    cd getperf
    ./configure
    make

### ソースのデプロイ

    perl deploy.pl --dest=/home/furusawa/work/

Windows
-------

### 必要なパッケージのインストール

#### VisualStudio インストール
   
   Visual C++ を用いてコンパイルします。
   コンパイラ環境がない場合は、Microsoft 社の [Visual Studio Express](https://www.visualstudio.com/downloads/) 
   のダウンロードサイトからインストールしてください。
   
#### ライブラリ
   
   ライブラリは全てwin32にあるのでパッケージの追加は原則不要です。使用ライブラリは以下の通りです。
   
   - zlib1.2.5
   - OpenSSL 1.0.0e
   
### 作業ディレクトリ作成

   c:\work を作成しその下でコンパイルをする想定で手順を記します。
   
    mkdir c:\work
    cd c:\work
   
### ソースダウンロードと解凍

   [GitHub](http://github.com/) からモジュールを c:\work にダウンロードします。

   7zip などを用いて、解凍します。
      
### ソースコンパイル

   VisualStudio のコマンドプロンプトを開いて、コンパイルします。

    c:\work>cd getperf\module\getperf-agent
    c:\work\getperf> nmake /f Makefile.win

### ソースのデプロイ

    c:\work\getperf> perl deploy.pl --dest=c:\work

以上、
