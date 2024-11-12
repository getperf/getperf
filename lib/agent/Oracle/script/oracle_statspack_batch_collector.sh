#!/bin/sh
#
# This procedure execute Oracle statspack snap and report.

LANG=C;export LANG
COLUMNS=160;export COLUMNS
#resize -s 100 160
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-l dir] [-e errfile] [-i sid] [-u userid/passwd] [-d script]"

# Set default param
CWD=`dirname $0`
DIR=.
SID=
USER=perfstat/perfstat
SCRIPT="ora12c"

# Get command option
OPT=
while getopts l:i:u:d: OPT
do
    case $OPT in
    l)  DIR=$OPTARG
        ;;
    i)  SID=$OPTARG
        ;;
    u)  USER=$OPTARG
        ;;
    d)  SCRIPT=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`
echo $SID

# Oracle Statspack 版設定 セッション、セグメント、表領域、SGA、UNDO、ASM
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_ses -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_seg -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_tbs_legacy -x

# Oracle Statspack 版設定 Statspack レポート(スナップショット無効化版)
# $CWD/sprep.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -v 0 -x
# Oracle STATSPACK 版設定 STATSPACK レポート(スナップショット有効化版)
$CWD/sprep.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -v 0 -s -n 576 -x
# Oracle STATSPACK 版設定 STATSPACK レポート(スナップショット有効化版レベル7)
# $CWD/sprep.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -v 7 -s -n 576 -x

# Oracle STATSPACK 版設定 STATSPACK イベントレポート
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f orasp_event -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f orasp_event_detail -x

# Oracle Statspack版設定 メモリ管理
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f sp_ora_mem -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f sp_ora_pga -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f sp_ora_sga -x
$CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f sp_ora_shared_pool -x

# 自動化固有監視
# $CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_latch_lib_cache -x
# $CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_ses_cnt -x
# $CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f ora_ses_ela -x
# $CWD/chcsv.sh  -u $USER -i $SID -l $DIR -d $SCRIPT -f orasize_undo -x

exit 0
