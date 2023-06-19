use Rex -base;
use Data::Dumper;
use Cwd 'getcwd';
use Rex::Template;
use Rex::Commands::Rsync;
use Rex::Pkg;
use Rex::User;
use Rex::Service;
use Rex::Commands::SCM;
use Rex::Commands::Cron;
use Getperf;
use Getperf::Config 'config';
use Getperf::SSL;
use Getperf::Container qw/command/;

pass_auth;

#$Rex::Logger::debug = 1;

BEGIN {
  my $config = config('base');
  my $user = $config->{ws_tomcat_owner};
  if (!-d '/tmp/rex') {
    mkdir '/tmp/rex' ;   # parepare temp directory
    run "chown ${user}. /tmp/rex";
  }
}

sub _run {
  my $cmd = shift;
  Rex::Logger::info($cmd);
  run $cmd, sub {
    my ($stdout, $stderr) = @_;
    Rex::Logger::info($stdout) if ($stdout);
    Rex::Logger::info($stderr, "error") if ($stderr);
  };
}

sub _sudo {
  my $cmd = shift;
  _run "sudo -E bash -c \"$cmd\"";
}

# ToDo: RHEL系Linux の外部パッケージリポジトリのインストール
# リポジトリによって手順を変える必要がある
#
# EPEL の場合、
#     1. パッケージインストール
#         yum install epel-release
#     2. ebabled=1、baseurlとmirrorurlの書換え
#
# EPEL 以外は従来通り以下でインストール

sub _install_yum_repository {
  my ($name, $repository, $gpg_key, $url) = @_;

  return if (-f "/etc/yum.repos.d/$name.repo");
  _sudo "yum localinstall $repository -y";
  _sudo "rpm --import $gpg_key";
  repository add => $name, url => $url;
  _sudo "yum -y install $name-release";
}

sub _deploy_ssl_config {
  my ($src, $dest) = @_;
  my $ssl_conf = '/etc/getperf/ssl';

  _run "mkdir -p $ssl_conf/$dest";
  _run "chmod -R 777 $ssl_conf";
  Rex::Logger::info("sync $src/* $ssl_conf/$dest/");
  sync_up $src, "$ssl_conf/$dest/";
  _run "chmod -R 660 $ssl_conf";
  _run "chown -R root:root $ssl_conf";

}

sub _download {
  my ($source, $dest) = @_;

  Rex::Logger::info("download $source");
  my $filename = $source;
  $filename=~s/^.*\///g;
  my $tempfile = "/tmp/rex/$filename";

  download $source, $tempfile if (!-f $tempfile);
  _sudo "cp $tempfile $dest";
}

sub _service_ctl {
  my $controll = shift;

  my $services = case operating_system, {
    Ubuntu  => [ qw/
      mysql apache2
    /],
    default => [ qw/
      mysqld httpd
    /],
  };
  push(@$services, ('tomcat-admin', 'apache2-admin', 'tomcat-data', 'apache2-data'));

  sudo {
    command => sub {
      my $last_service = $$services[$#$services];
      for my $service(@$services) {
        if ($controll=~/^(start|stop|restart)$/) {
          Rex::Logger::info("$controll : $service");
          _sudo("/etc/init.d/$service $controll");
        } elsif ($controll eq 'ensure') {
          Rex::Logger::info("Regist : $service");
          service $service => ensure => "started";
        }
        if ($service ne $last_service) {
          sleep 3;
        }
      }
    },
    user => 'root'
  };
}

sub _restart_ws {
  my ($ws_suffix) = @_;
  my $config = config('base');

  my $tomcat_home = $config->{ws_tomcat_dir} . '-' . $ws_suffix;
  my $apache_home = $config->{ws_apache_dir} . '-' . $ws_suffix;
   _sudo "/etc/init.d/tomcat-${ws_suffix} stop";
   sleep 5;
   _sudo "/etc/init.d/tomcat-${ws_suffix} start";
   sleep 30;
   _sudo "$apache_home/bin/apachectl restart";
}

sub _init_log {
  my $config = config('base');
  my $owner       = $config->{ws_tomcat_owner};
  my $getperf_log = $config->{log_dir} . "/getperf.log";

  _run "touch ${getperf_log}";
  _run "chmod g+rw ${getperf_log}";
  _sudo "chown ${owner}. ${getperf_log}";
}

desc "Create SSH key and add remote access for admin user";
task "install_ssh_key", sub {
  my $home = $ENV{'HOME'};
  my $host = config('base')->{ws_server_name};
  my $current_dir = getcwd;

  chdir $home;
  _run 'cat /dev/zero | ssh-keygen -q -N ""';
  chdir $home . '/.ssh';
  _run 'cat id_rsa.pub >> authorized_keys';
  _run 'chmod 600 authorized_keys';

  my $echo_opt = (operating_system eq 'CentOS') ? '-e' : '';
  _run 'echo ' . $echo_opt . ' "Host ' . $host .
    '\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile=/dev/null\n" >> config';
  _run 'chmod 600 config';

  # refresh .ssh/known_hosts
  _run "ssh-keygen -R $host";
  _run "ssh-keyscan -H $host >> ${home}/.ssh/known_hosts";
  chdir $current_dir;
};

desc "Need to run sudo. Install ant packages";
task "install_ant", sub {
      # Install Apache Ant
      unless (-f '/usr/local/bin/ant') {
        my $version  = '1.9.4';
        my $ftpsite  = 'http://ftp.tsukuba.wide.ad.jp/software/apache/ant/binaries/';

        my $check_ver = run 'curl -sSL ' . $ftpsite;
        if ($check_ver=~m|href="apache-ant-(\d.*?)-bin.tar.gz"|) {
          $version = $1;
        }
        my $module = "apache-ant-${version}";
        if (!-f "/tmp/rex/${module}-bin.tar.gz") {
          download "$ftpsite/${module}-bin.tar.gz", "/tmp/rex/${module}-bin.tar.gz";
        }
        _run "cd /tmp/rex; tar xf ${module}-bin.tar.gz";
        _sudo "mv /tmp/rex/${module} /usr/local/";
        _sudo "ln -s /usr/local/${module}/bin/ant /usr/local/bin/ant";
      }
};

desc "Need to run sudo. Install Various packages";
task "install_package", sub {
  my $config = config('base');
  _init_log;
  # Change permittion of scripts
  {
    my $deploy = $config->{home} . '/script/deploy-script.sh';
    _sudo $deploy;
  }

  my $os_type = operating_system;
  if ($os_type eq 'Raspbian') {
    $os_type = 'Ubuntu';
  }
  my $base_package = case $os_type, {
    Ubuntu  => [ qw/
      build-essential
      apache2 php5 libapache2-mod-php5
      libssl-dev libexpat1-dev
      openjdk-8-jdk
      lsb-release
      curl git rrdtool zip unzip
    /],
    default => [ qw/
      autoconf libtool
      gcc gcc-c++ make openssl-devel pcre-devel
      httpd php php-mbstring
      php-mysql php-pear php-common php-gd php-devel php-cli
      openssl-devel expat-devel
      java-1.8.0-openjdk java-1.8.0-openjdk-devel
      redhat-lsb
      cairo-devel libxml2-devel pango-devel pango
      libpng-devel freetype freetype-devel libart_lgpl-devel
      curl git rrdtool zip unzip
      mysql-devel
    /],
  };
  sudo {
    command => sub {
      if ($os_type =~/(CentOS|RedHatEnterpriseServer)/) {
        _sudo "yum -y install epel-release";
        my $yum_conf = "/etc/yum.repos.d/epel.repo";
        _sudo 'sed -i -e \"s/enabled=0/enabled=1/g;s/^#baseurl/baseurl/g;s/^mirror/#mirror/g\" '. $yum_conf;

        _install_yum_repository(
          'remi',
          "http://rpms.famillecollet.com/enterprise/remi-release-6.rpm",
          'http://rpms.famillecollet.com/RPM-GPG-KEY-remi',
          'http://rpms.famillecollet.com/enterprise/$releasever/remi/$basearch/'
        );
        say install package => $base_package;
        say install package =>  [ qw/
          mysql-server
        /];

      } elsif ($os_type eq 'Ubuntu') {
        say install package => $base_package;
        my $pass = config('base')->{mysql_passwd};
        for my $deb_config(qw/root_password root_password_again/) {
          my $conf = "mysql-server mysql-server/$deb_config password $pass";
          my $cmd  = "echo $conf | debconf-set-selections";
          _sudo $cmd;
        }
        _sudo "apt-get -y install mysql-server php5-mysql";

      } else {
        say install package => $base_package;
        say install package =>  [ qw/
          mysql-server
        /];
      }

      # Install Gradle Java build tool
      unless (is_file '/usr/local/gradle/latest/bin/gradle') {
        upload 'script/gradle-install.sh', '/tmp/rex/gradle-install.sh';
        _run '/tmp/rex/gradle-install.sh';
        _sudo 'ln -s /usr/local/gradle/latest/bin/gradle /usr/local/bin/gradle';
      }

      _sudo 'chmod a+wrx /var/www/html';

      # Install Apache Ant
      unless (-f '/usr/local/bin/ant') {
        my $version  = '1.9.4';
        my $ftpsite  = 'http://ftp.tsukuba.wide.ad.jp/software/apache/ant/binaries/';

        my $check_ver = run 'curl -sSL ' . $ftpsite;
        if ($check_ver=~m|href="apache-ant-(\d.*?)-bin.tar.gz"|) {
          $version = $1;
        }
        my $module = "apache-ant-${version}";
        if (!-f "/tmp/rex/${module}-bin.tar.gz") {
          download "$ftpsite/${module}-bin.tar.gz", "/tmp/rex/${module}-bin.tar.gz";
        }
        _run "cd /tmp/rex; tar xf ${module}-bin.tar.gz";
        _sudo "mv /tmp/rex/${module} /usr/local/";
        _sudo "ln -s /usr/local/${module}/bin/ant /usr/local/bin/ant";
      }

      # Config PHP.ini
      {
        my $deploy = $config->{home} . '/script/config-pkg.pl';
        _sudo "perl $deploy php";
      }
    },
    user => 'root'
  };
};

desc "Install Getperf Sumup service";

task "install_sumupctl", sub {
  my $config = config('base');
  my $service = 'sumupctl';
  {
    my $deploy = $config->{home} . "/script/deploy-$service.pl";
    _sudo "perl $deploy";
  }
  sudo {
    command => sub {
      Rex::Logger::info("Regist : $service");
      service $service => ensure => "started";
    },
    user => 'root'
  };
};

desc "Install PHP composer";

task "prepare_composer", sub {
  my $config = config('base');
  if (!-x '/usr/local/bin/composer') {
    _run "cd /tmp/rex; curl -sS https://getcomposer.org/installer | php";
    _sudo "mv /tmp/rex/composer.phar /usr/local/bin/composer";
  }
  my $cacti_cli_home = $config->{home} . "/lib/cacti";
  _run "cd $cacti_cli_home; composer install";
};

desc "Setup MySQL";
task "prepare_mysql", sub {
  my $config = config('base');
  {
    my $mysql_setup  = $config->{home} . '/script/mysql-setup.sh';
    my $mysql_passwd = $config->{mysql_passwd};
    _run "$mysql_setup $mysql_passwd";
  }
};

desc "Need to run sudo. Install Apache HTTPD";
task "prepare_apache", sub {
  # my $version = '2.2.34';
  # my $module  = 'httpd-2.2.34';
  # my $archive = "${module}.tar.gz";
  # my $download = 'http://ftp.riken.jp/net/apache//httpd/httpd-2.2.34.tar.gz';

  my $version = '2.4.57';
  my $module  = 'httpd-2.4.57';
  my $archive = "${module}.tar.gz";
  my $download = 'http://ftp.riken.jp/net/apache//httpd/httpd-2.4.57.tar.gz';

  # Parse Apache download page, and check version.
  # Source:
  # <a href="http://ftp.riken.jp/net/apache//httpd/httpd-2.2.29.tar.gz">
  #   httpd-2.2.29.tar.gz</a>
  my $download_page = run 'curl -sSL http://httpd.apache.org/download.cgi';
  if ($download_page=~m|Source: <a href="(.+?)/(httpd-)(2.4.\d+)(\.tar\.gz?)">|) {
  # if ($download_page=~m|Source: <a href="(.+?)/(httpd-)(2.2.\d+)(\.tar\.gz?)">|) {
    $version = $3;
    $module  = "httpd-${version}";
    $archive = "${module}.tar.gz";
    $download = "$1/${archive}";
  }

  if (!-f "/tmp/rex/${archive}") {
    _download $download, "/tmp/rex/";
    chdir('/tmp/rex');
    _run "tar xf $module.tar.gz";
  }

  my $config = config('base');
  my $apache_dir = $config->{ws_apache_dir} || die;
  my $src_dir = "/tmp/rex/${module}";

  # for my $ws_suffix($config->{ws_admin_suffix}) {
  for my $ws_suffix($config->{ws_admin_suffix}, $config->{ws_data_suffix}) {
    my $apache_home = $apache_dir . '-' . $ws_suffix;
    if (!-x "$apache_home/bin/httpd") {
      cd $src_dir;
      _run 'make distclean';
      _run './configure --prefix=' . $apache_home .
        ' -enable-modules=all --enable-mpm=event' .
        ' --enable-suexec --enable-rewrite --enable-proxy --enable-ssl';

      # CentOS7.x 環境の場合、個別に/usr/local にコンパイルインストール
      # したOpenSSL のホームを指定する。OpenSSL 1.1.1k 以上が必要。
      # _run './configure --prefix=' . $apache_home .
      #   ' -enable-modules=all --enable-mpm=event' .
      #   ' --enable-suexec --enable-rewrite --enable-proxy --enable-ssl' .
      #   ' --with-ssl=/usr/local/openssl-1.1.1k/';

      _run 'make';
      _sudo 'make install';
    }

    {
      my $deploy = $config->{home} . '/script/deploy-ws.pl';
      _sudo "perl $deploy config_apache --suffix=$ws_suffix";
#      _sudo "ln -s $apache_home/bin/apachectl /etc/init.d/apache2-$ws_suffix";
    }
  }
};

desc "Need to run sudo. Install Apache Tomcat";
task "prepare_tomcat", sub {

  my $version  = '8.5.88';
  my $url = 'https://archive.apache.org/dist/tomcat';
#  my $check_ver = run 'curl -sSL http://ftp.riken.jp/net/apache/tomcat/tomcat-7';
  my $check_ver = run "curl -sSL $url/tomcat-8";

#  if ($check_ver=~/href="v(7.*?)\/"/) {
#    $version = $1;
#  }
  my $download = "$url/tomcat-8";
  my $module   = "apache-tomcat-${version}";
  my $config = config('base');
  my $osname = operating_system;
  my $tomcat_dir = $config->{ws_tomcat_dir} || die;

#   my $version  = '7.0.105';
#   my $url = 'https://archive.apache.org/dist/tomcat';
# #  my $check_ver = run 'curl -sSL http://ftp.riken.jp/net/apache/tomcat/tomcat-7';
#   my $check_ver = run "curl -sSL $url/tomcat-7";

# #  if ($check_ver=~/href="v(7.*?)\/"/) {
# #    $version = $1;
# #  }
#   my $download = "$url/tomcat-7";
#   my $module   = "apache-tomcat-${version}";
#   my $config = config('base');
#   my $osname = operating_system;
#   my $tomcat_dir = $config->{ws_tomcat_dir} || die;

  # download tomcat binary
  if (!-f "/tmp/rex/${module}.tar.gz") {
    _download "$download/v${version}/bin/${module}.tar.gz", "/tmp/rex/";
  }

  for my $ws_suffix($config->{ws_admin_suffix}, $config->{ws_data_suffix}) {
    my $tomcat_owner = $config->{ws_tomcat_owner};
    my $tomcat_home = $tomcat_dir . '-' . $ws_suffix;
    if (!-d $tomcat_home) {
      _run "cd /tmp/rex; tar xf ${module}.tar.gz";
      _sudo "mv /tmp/rex/${module} ${tomcat_home}";
      _sudo "chown -R ${tomcat_owner}. ${tomcat_home}";
    }
    {
      my $deploy = $config->{home} . '/script/deploy-ws.pl';
      _sudo "perl $deploy config_tomcat --suffix=${ws_suffix}";
    }
  }

  file "/etc/logrotate.d/tomcat-ws",
    content   => template("script/template/tomcat-ws.tpl",
      ws_tomcat_owner => $config->{ws_tomcat_owner});
};

# Temporary use. Deprecated after fix "Maven" deploy migration.
desc "Need to run sudo. Install Web Service library";
task "prepare_tomcat_lib", sub {
  my $config = config('base');
  my $tomcat_dir = $config->{ws_tomcat_dir} || die;

  # Install java library
  for my $ws_suffix($config->{ws_admin_suffix}, $config->{ws_data_suffix}) {
    my $tomcat_home = $tomcat_dir . '-' . $ws_suffix;
    # Install Apache Axis2
    my $deploy = $config->{home} . '/script/axis2-install.sh';
    _sudo "$deploy $tomcat_home";
    _restart_ws $ws_suffix;
  }
};

desc "Need to run sudo. Install Zabbix";
task "prepare_zabbix", sub {
  my $config = config('base');
  my $zabbix_config = config('zabbix');
  # sudo {
  #   command => sub {
  #     if (operating_system =~/(CentOS|RedHatEnterpriseServer)/) {
  #       my $url     = $zabbix_config->{ZABBIX_REPOSITORY_URL};
  #       my $url_dir = $url;
  #       $url_dir =~s/zabbix-release.*//g;
  #       _install_yum_repository(
  #         'zabbix',
  #         $url,    # 'http://repo.zabbix.com/zabbix/2.2/rhel/6/x86_64/zabbix-release-2.2-1.el6.noarch.rpm',
  #         'http://repo.zabbix.com/RPM-GPG-KEY-ZABBIX',
  #         $url_dir # 'http://repo.zabbix.com/zabbix/2.2/rhel/6/$basearch/'
  #       );
  #     }

  #     my $base_package = case operating_system, {
  #       Ubuntu  => [ qw/
  #         language-pack-ja php5-mysql zabbix-server-mysql
  #         zabbix-frontend-php zabbix-agent fonts-vlgothic
  #       /],
  #       default => [ qw/
  #         zabbix-server zabbix-web
  #         zabbix-server-mysql zabbix-web-mysql zabbix-web-japanese
  #         zabbix-get zabbix-sender
  #       /],
  #     };
  #     if (operating_system =~/(CentOS|RedHatEnterpriseServer)/) {
  #       _sudo "yum -y install --enablerepo=zabbix,epel,remi @{$base_package}"
  #     } else {
  #       say install package => $base_package;
  #     }

  #     _sudo $config->{home} . '/script/deploy-zabbix.pl';

  #     if (-f '/etc/yum.repos.d/zabbix.repo') {
  #       _sudo 'sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/zabbix.repo';
  #     }

  #     my $mysql_passwd =     $config->{mysql_passwd};
  #     if (-f '/etc/zabbix/zabbix_server.conf') {
  #       _sudo 'sed -i -e "s/^.*DBPassword=.*$/DBPassword=' . $mysql_passwd . '/g" /etc/zabbix/zabbix_server.conf';
  #     }

  #     if (operating_system eq 'Ubuntu') {
  #       # _sudo 'service zabbix-server restart';
  #       # _sudo 'chkconfig zabbix-server on';
  #       _sudo 'sed -i -e "s/^START=no$/START=yes/g" /etc/default/zabbix-server';
  #       _sudo 'sudo service zabbix-server restart';
  #       file "/etc/apache2/conf-available/zabbix.conf",
  #         content => template("script/template/zabbix.conf.apache2.tpl");
  #       _sudo 'a2enconf zabbix';
  #       _sudo 'service apache2 restart';
  #       file "/etc/zabbix/zabbix.conf.php",
  #         content   => template("script/template/zabbix.conf.php.tpl",
  #           mysql_admin_password => $config->{mysql_passwd});
  #     } else {
  #       _sudo 'service zabbix-server restart';
  #       _sudo 'chkconfig zabbix-server on';
  #       _sudo 'service httpd restart';
  #       file "/etc/zabbix/web/zabbix.conf.php",
  #         content   => template("script/template/zabbix.conf.php.tpl",
  #           mysql_admin_password => $config->{mysql_passwd});
  #     }

  #   },
  #   user => 'root'
  # };

  # Download agent binary
  # {
  #   my $current_dir      = getcwd;
  #   my $agent_module_var = $config->{home} . '/module/getperf-agent/var';
  #   my $zabbix_agent_var = $agent_module_var . '/zabbix';
  #   my $agent_script_dir = $config->{lib_dir} . '/agent/Zabbix';
  #   my $agent_ver        = $zabbix_config->{ZABBIX_AGENT_VERSION};
  #   my $base_url         = "http://www.zabbix.com/downloads/${agent_ver}/";
  #   my $download_dir     = $zabbix_config->{ZABBIX_AGENT_DOWNLOAD_DIR};

  #   for my $target_dir($agent_module_var, $zabbix_agent_var, $download_dir) {
  #     if (!-d $target_dir) {
  #       _run "mkdir -p ${target_dir}";
  #     }
  #   }

  #   chdir $download_dir;
  #   my @md5sum_outputs = ();
  #   for my $arch(@{$zabbix_config->{DOWNLOAD_AGENT_PLATFORMS}}) {
  #     # zabbix_agents_2.2.9.linux2_4.i386.tar.gz
  #     my $suffix = ($arch eq 'win') ? 'zip' : 'tar.gz';
  #     my $base_name = "zabbix_agents_${agent_ver}.${arch}.${suffix}";
  #     if (! -f "$download_dir/$base_name" ) {
  #       _run "wget --quiet ${base_url}${base_name}";
  #     }
  #     if (! -f "${zabbix_agent_var}/${base_name}" ) {
  #       _run "cp -p ${download_dir}/${base_name} ${zabbix_agent_var}";
  #     }
  #     my $md5sum_output = `md5sum $download_dir/$base_name`;
  #     if ($? != 0) {
  #       Rex::Logger::info("md5sum check error '$base_name' : $@", "error");
  #     } else {
  #       $md5sum_output =~s/ .*(\r|\n)*//g;
  #       push (@md5sum_outputs, "$md5sum_output : $base_name");
  #     }
  #   }
  #   if (@md5sum_outputs) {
  #     print "\nZabbix Agent module files downloaded. Please check md5 in ";
  #     print "'http://www.zabbix.com/download.php'\n\n";
  #     print join("\n", @md5sum_outputs) . "\n";
  #   }
  #   # Copy zabbix script
  #   _run "cp -rp ${agent_script_dir}/* ${agent_module_var}";
  #   chdir $current_dir;
  # }

  # Create recipe file
  {
    my $recipe = $config->{home} . '/module/getperf-agent/var/zabbix/Recipe.pl';
    my $buf = '';
    $buf .= '{' . "\n";
    $buf .= '  "ZABBIX_SERVER_VERSION"    => "' . $zabbix_config->{ZABBIX_SERVER_VERSION} . '",' . "\n";
    $buf .= '  "ZABBIX_AGENT_VERSION"     => "' . $zabbix_config->{ZABBIX_AGENT_VERSION} . '",' . "\n";
    $buf .= '  "ZABBIX_SERVER_IP"         => "' . $zabbix_config->{ZABBIX_SERVER_IP} . '",' . "\n";
    $buf .= '  "ZABBIX_SERVER_ACTIVE_IP"  => "' . $zabbix_config->{ZABBIX_SERVER_ACTIVE_IP} . '",' . "\n";
    $buf .= '  "GETPERF_AGENT_USE_ZABBIX" => ' . $zabbix_config->{GETPERF_AGENT_USE_ZABBIX} . ',' . "\n";
    $buf .= '}' . "\n";
    open(OUT, ">$recipe") || die "$@";
    print OUT $buf;
    close(OUT);
    print "patch $recipe\n";
  }
};

desc "Need to run sudo. Install Graphite";
task "prepare_graphite", sub {
  my $config = config('base');
  my $graphite_config = config('graphite');

  sudo {
    command => sub {
      if (operating_system =~/(CentOS|RedHatEnterpriseServer)/) {
        _sudo 'yum -y install --enablerepo=epel graphite-web graphite-web-selinux mysql mysql-server MySQL-python';
        _sudo 'yum -y install --enablerepo=epel python-carbon python-whisper';
      } else {
        die "Operating system is not 'CentOS'";
      }

      _sudo $config->{home} . '/script/deploy-graphite.pl';

      if (-f '/etc/httpd/conf.d/graphite-web.conf') {
        my $port = $graphite_config->{GRAPHITE_WEB_PORT};
        my $command = "s/<VirtualHost \\\*:80>/<VirtualHost \\\*:${port}>/g";
        _sudo "sed -i -e \\\"${command}\\\" /etc/httpd/conf.d/graphite-web.conf";
        _sudo "grep 'Listen ${port}' /etc/httpd/conf/httpd.conf || echo 'Listen ${port}' >> /etc/httpd/conf/httpd.conf";
      }

      my $var_lib_carbon = $graphite_config->{GRAPHITE_VAR_LIB_CARBON} || '/var/lib/carbon';
      for my $target('/etc/carbon/carbon.conf', '/etc/graphite-web/local_settings.py') {
        if (-f $target) {
          _sudo "sed -i -e \\\"s|/var/lib/carbon|$var_lib_carbon|g\\\" $target";
        }
      }

      _sudo 'service carbon-cache restart';
      _sudo 'chkconfig carbon-cache on';

      _sudo 'service httpd restart';

    },
    user => 'root'
  };
};

desc "Install InfluxDB";
task "prepare_influxdb", sub {
  my $config = config('base');
  my $influx_config = config('influx');
  sudo {
    command => sub {
      if (operating_system eq 'Ubuntu') {
        _run $config->{home} . '/script/ubuntu/influxdb-install.sh';
      } else {
        _run $config->{home} . '/script/influxdb-install.sh';
      }
      my $conf = '/etc/influxdb/influxdb.conf';
      if (-f $conf) {
        my $port = $influx_config->{INFLUX_PORT} || 8086;
        my $var_lib_influxdb = $influx_config->{VAR_LIB_INFLUXDB} || '/var/lib/influxdb';
          _sudo "sed -i -e \\\"s|bind-address = \":8086\"|bind-address = \":${port}\"|g\\\" $conf";
          _sudo "sed -i -e \\\"s|/var/lib/influxdb|$var_lib_influxdb|g\\\" $conf";
      }

      _sudo 'service influxdb restart';
      if (operating_system ne 'Ubuntu') {
        _sudo 'chkconfig influxdb on';
      }
    },
    user => 'root'
  };
};

desc "Build agent source module";
task "make_agent_src", sub {
  my $config = config('base');
  my $script = $config->{home} . '/script/deploy-agent-source-module.pl';
  _run $script;
};

desc "Build agent module download site";
task "prepare_agent_download_site", sub {
  my $config = config('base');

  if (operating_system eq 'Ubuntu') {
    file "/etc/apache2/conf-available/agent_download_site.conf",
      content   => template("script/template/agent_download_site/conf-apache-2.4.tpl",
        home => $config->{home});
    _sudo 'sudo a2enconf agent_download_site';
    _sudo 'service apache2 restart';

  } else {
    file "/etc/httpd/conf.d/agent_download_site.conf",
      content   => template("script/template/agent_download_site/conf.tpl",
        home => $config->{home});
    _sudo 'service httpd restart';
  }
};

desc "Download Cacti source";
task "prepare_cacti", sub {
  my $cacti_config = config('cacti');
  my $archive = $cacti_config->{GETPERF_CACTI_ARCHIVE};

  my $version  = '0.8.8e';
  $version = $1 if ($archive=~/cacti-(.+?)\.tar\.gz/);
  my $download = 'http://www.cacti.net/downloads';
  my $archive  = "cacti-${version}.tar.gz";
  my $config = config('base');
  my $cacti_dir = $config->{home} . '/var/cacti' || die;
  my $archive_path = "$cacti_dir/$archive";
  print $archive_path . "\n";
  if (!-f $archive_path) {
    download "$download/${archive}", $archive_path;
  }
};

desc "Axis2 Web Service";
task "prepare_ws", sub {
  my $config = config('base');
  my $tomcat_dir = $config->{ws_tomcat_dir} || die;
  for my $ws_suffix($config->{ws_admin_suffix}, $config->{ws_data_suffix}) {
    my $tomcat_home = $tomcat_dir . '-' . $ws_suffix;
    my $script  = $config->{home} . '/script/deploy-ws.pl';
    _sudo "perl $script config_axis2 --suffix=$ws_suffix";
    my $script2 = $config->{home} . '/script/axis2-install-ws.sh';
    _run "$script2 $tomcat_home";
    _restart_ws $ws_suffix;
  }
};

desc "Restart WebService - admin";
task "restart_ws_admin", sub {
  _restart_ws 'admin';
};

desc "Restart WebService - data";
task "restart_ws_data", sub {
  _restart_ws 'data';
};


desc "Need to run sudo. Create private SSL CA";
task "create_ca", sub {
  my $config = config('base');
  my $ssl_admin_dir = $config->{ssl_admin_dir};
  my $tomcat_owner = $config->{ws_tomcat_owner};
  if (!-d $ssl_admin_dir) {
    _sudo "mkdir -p ${ssl_admin_dir}";
    _sudo "chown -R ${tomcat_owner}. ${ssl_admin_dir}";
  }

  my $script = $config->{home} . '/script/ssladmin.pl';
  _run "perl $script create_ca";
};

desc "Need to run sudo. Create inter SSL CA";
task "create_inter_ca", sub {
  my $config = config('base');
  my $script = $config->{home} . '/script/ssladmin.pl';
  _run "perl $script create_inter_ca";
};

desc "Need to run sudo. Create server certificate";
task "server_cert", sub {
  my $config = config('base');
  my $script = $config->{home} . '/script/ssladmin.pl';
  _run "perl $script server_cert";
};

desc "Periodic update of the client certificate";
task "run_client_cert_update", sub {
  my $config = config('base');
  my $script = $config->{home} . '/script/ssladmin.pl';

  cron_entry "client_cert_update",
   ensure       => "present",
   command      => "(perl $script update_client_cert > /dev/null 2>&1) &",
   minute       => "15",
   hour         => "0",
   month        => "*",
   day_of_week  => "*",
   day_of_month => "*",
   user         => $config->{ws_tomcat_owner},
   on_change    => sub { say "cron added"; };
};

desc "Periodic check of the site daemon";
task "run_monitor_sumup", sub {
  my $config = config('base');
  my $script = $config->{home} . '/script/monitor-sumup';

  cron_entry "monitor_sumup",
   ensure       => "present",
   command      => "($script > /dev/null 2>&1) &",
   minute       => "0,5,10,15,20,25,30,35,40,45,50,55",
   hour         => "*",
   month        => "*",
   day_of_week  => "*",
   day_of_month => "*",
   user         => 'root',
   on_change    => sub { say "cron added"; };
};


desc "Need to run sudo. Start service";
task "svc_start", sub {
  _service_ctl('start');
};

desc "Need to run sudo. Stop service";
task "svc_stop", sub {
  _service_ctl('stop');
};

desc "Need to run sudo. Restart service";
task "svc_restart", sub {
  _service_ctl('restart');
};

desc "Need to run sudo. Regist service";
task "svc_auto", sub {
  _service_ctl('ensure');
};

# desc "Deploy frontend http service";
# task deploy_web, sub {
#   needs "prepare";
#   needs "create_ca";
#   needs "server_cert";
# };

1;
