
MySQL 8.0 インストール
----------------------

   wget https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
   sudo -E yum localinstall mysql80-community-release-el8-4.noarch.rpm
   sudo -E yum repolist all | grep mysql
   sudo yum -y install yum-utils
   sudo yum-config-manager --disable mysql57-community
   sudo yum-config-manager --enable mysql80-community
#   yum info mysql-community
   sudo yum module disable mysql
   sudo yum  install mysql-community-server
#   sudo  yum  install mysql-community
   sudo systemctl enable mysqld
   sudo systemctl start mysqld

sudo vi /etc/my.cnf

[mysqld]
default_authentication_plugin=mysql_native_password
validate_password.length=4
validate_password.mixed_case_count=0
validate_password.number_count=0
validate_password.special_char_count=0
validate_password.policy=LOW
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone='Asia/Tokyo'

 sudo systemctl restart mysqld

cat /var/log/mysqld.log | grep 'temporary password'

mysql -u root -p
lfahcezI2Q!f

USE mysql;
ALTER USER 'root'@'localhost' identified BY 'getperf';


PHP
---

sudo dnf module enable php:7.3
sudo dnf install php php-cli php-common
sudo systemctl restart httpd

sudo yum install php-mysqlnd


その他
------

sudo -E yum  install \
   pcre-devel \
   php php-mbstring \
   php-mysqlnd php-pear php-common php-gd php-devel php-cli \
   cairo-devel libxml2-devel pango-devel pango \
   libpng-devel freetype freetype-devel  \
   curl git rrdtool zip unzip \
   mysql-devel


Gradle をインストールします

インストールスクリプトを編集して、バージョンを最新 6.7.1 に変更
ダウンロードサイトのURLをhttpからhttpsに変更します

::

   cd $GETPERF_HOME
   vi ./script/gradle-install.sh
   #gradle_version=2.3
   gradle_version=6.7.1

   #wget -N http://services.gradle.org/distributions/gradle-${gradle_version}-all.zip
   wget -N https://services.gradle.org/distributions/gradle-${gradle_version}-all.zip

::

   cd $GETPERF_HOME
   sudo -E ./script/gradle-install.sh
   sudo ln -s /usr/local/gradle/latest/bin/gradle /usr/local/bin/gradle

Apache HTML ホームページのアクセス権限を変更します

::

   sudo chmod a+wrx /var/www/html

Apache Ant をインストールします

::

   sudo -E yum -y install ant

PHP設定ファイル /etc/php.ini を変更します

::

   sudo -E perl ./script/config-pkg.pl php
