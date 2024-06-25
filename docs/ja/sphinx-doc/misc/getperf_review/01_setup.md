etenforce コマンドで SELinux の動作状況を調べます。

getenforce
setenforce 0

vi /etc/selinux/config
SELINUX=disabled

sudo systemctl is-enabled firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

vi /etc/hosts
192.168.0.102 alma87.getperf3

useradd psadmin
passwd psadmin

visudo
Default secure_pathの行を探して行の最後に、/usr/local/bin:/usr/local/sbinを追加します

Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
#Defaults   !visiblepw
psadmin        ALL=(ALL)       NOPASSWD: ALL

su - psadmin
chmod a+rx $HOME

sudo -E yum -y groupinstall "Development Tools"
sudo -E yum -y install kernel-devel kernel-headers
sudo -E yum -y install expat expat-devel libxml2-devel
sudo -E yum -y install perl-XML-Parser perl-XML-Simple
sudo -E yum -y update

git clone http://root:goliath1@192.168.0.100:8081/git/root/getperf.git

Perlライブラリのインストール
cd ~/getperf
source script/profile.sh
echo source $GETPERF_HOME/script/profile.sh >> ~/.bash_profile

sudo -E yum -y install perl-devel
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
sudo -E cpanm --installdeps --notest .

設定ファイルの作成

perl script/cre_config.pl
vi config/getperf_site.json
vi config/getperf_zabbix.json
"GETPERF_USE_ZABBIX_SEND": 0,
"GETPERF_AGENT_USE_ZABBIX": 0
"ZABBIX_ADMIN_PASSWORD":     "getperf",

rex install_ssh_key
rex create_ca        # ルート認証局作成
rex create_inter_ca  # 中間認証局作成
rex server_cert
EDITOR=vi crontab -e
# 改行を追加して、Cron設定を終了する。
sudo EDITOR=vi crontab -e
# 改行を追加して、Cron設定を終了する。

sudo rex run_client_cert_update
