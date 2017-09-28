#!/bin/bash
#
# Cacti graph template creation (ArrayFort)
# 1.初めにグラデーショングラフを作成してエクスポートする
# 2.次に全グラフをグラデーションなしで作成して、エクスポートしたテンプレートをインポートする

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`

export SITEHOME="$(git rev-parse --show-toplevel)"

if [ ! -d "$SITEHOME/lib/Getperf/Command/Site" ]; then
	echo "Invalid site home directory '$SITEHOME'"
	exit -1
fi
export GRAPH_CONFIG="$SITEHOME/lib/graph"
export COLOR_CONFIG="$GRAPH_CONFIG/color"
export GRADATION_10="--color-scheme $COLOR_CONFIG/gradation3.json --color-style gradation"
export GRADATION_16="--color-scheme $COLOR_CONFIG/gradation2.json --color-style gradation"
export GRADATION_30="--color-scheme $COLOR_CONFIG/gradation.json  --color-style gradation"

cacti-cli -g $GRAPH_CONFIG/SNMPNetwork/snmp_network_port_alias.json
cacti-cli -g $GRAPH_CONFIG/SNMPNetwork/snmp_network_main_port_alias.json
