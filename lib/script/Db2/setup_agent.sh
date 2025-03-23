# /etc/ntp.conf, managed by Rex
PTUNE_HOME=<%= $home %>; export PTUNE_HOME

cd $PTUNE_HOME
if   [ -f "$PTUNE_HOME/getperf.ini" ]; then
	tar cvf - getperf.ini script conf network | gzip > /tmp/getperf_config.tar.gz
elif [ -f "$PTUNE_HOME/Param.ini" ]; then
	tar cvf - Param.ini script bin            | gzip > /tmp/getperf_config.tar.gz
else
	echo "ERROR: Parameter file not found"
	exit -1
fi
