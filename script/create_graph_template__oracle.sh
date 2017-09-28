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
export GRADATION_10="--color-scheme $COLOR_CONFIG/gradation3.json --color-style gradation"
export GRADATION_16="--color-scheme $COLOR_CONFIG/gradation2.json --color-style gradation"
export GRADATION_30="--color-scheme $COLOR_CONFIG/gradation.json  --color-style gradation"

cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_event.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_hit.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_load.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_tbs.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_seg_etc.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_seg_index.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_seg_table.json

cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_sql_top_by_buffer_gets.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_sql_top_by_cpu_time.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_sql_top_by_disk_reads.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_obj_top_by_buffer_gets.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_obj_top_by_disk_reads.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_obj_top_by_logical_reads.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_obj_top_by_physical_reads.json
cacti-cli -f -g $GRAPH_CONFIG/Oracle/ora_obj_top_by_physical_writes.json
