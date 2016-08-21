#!/bin/bash
#
# Cacti graph template creation (Windows)

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
export COLOR_DEFAULT="--color-scheme $COLOR_CONFIG/default.json    --color-style gradation"
export GRADATION_003="--color-scheme $COLOR_CONFIG/gradation4.json --color-style gradation"
export COLOR_CPUUTIL="--color-scheme $COLOR_CONFIG/cpu_util.json   --color-style gradation"

cacti-cli -f -g $GRAPH_CONFIG/Windows/LogicalDisk.json    $COLOR_DEFAULT
cacti-cli -f -g $GRAPH_CONFIG/Windows/Memory.json         $COLOR_DEFAULT
cacti-cli -f -g $GRAPH_CONFIG/Windows/Network.json        $COLOR_DEFAULT
cacti-cli -f -g $GRAPH_CONFIG/Windows/PhysicalDisk.json   $COLOR_DEFAULT
cacti-cli -f -g $GRAPH_CONFIG/Windows/Processor.json      $COLOR_DEFAULT
cacti-cli -f -g $GRAPH_CONFIG/Windows/ProcessorTotal.json $COLOR_CPUUTIL
