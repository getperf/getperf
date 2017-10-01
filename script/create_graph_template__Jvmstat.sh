#!/bin/bash
#
# Cacti graph template creation (ArrayFort)

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
export COLOR_2="--color-scheme $COLOR_CONFIG/color2.json --color-style gradation"

cacti-cli -f -g $GRAPH_CONFIG/Jvmstat/jstat.json
cacti-cli -f -g $GRAPH_CONFIG/Jvmstat/jstat2.json $COLOR_2
