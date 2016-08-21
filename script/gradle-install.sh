#!/bin/bash
# installs to /usr/local/gradle
# existing versions are not overwritten/deleted
# seamless upgrades/downgrades
# $GRADLE_HOME points to latest *installed* (not released)

gradle_version=2.3

sudo mkdir -p /usr/local/gradle
cd /tmp/rex
wget -N http://services.gradle.org/distributions/gradle-${gradle_version}-all.zip
sudo unzip gradle-${gradle_version}-all.zip -d /usr/local/gradle
sudo ln -sfn gradle-${gradle_version} /usr/local/gradle/latest
sudo printf "export GRADLE_HOME=/usr/local/gradle/latest\nexport PATH=\$PATH:\$GRADLE_HOME/bin" > /etc/profile.d/gradle.sh
. /etc/profile.d/gradle.sh

# check installation
gradle -v

