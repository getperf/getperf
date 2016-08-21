#!/bin/sh
ERR=/dev/null

# Set Initial Parameter
#         "_pwd_/getnsts.sh -i 30 -n 60 -l _odir_",

LANG=C; export LANG
PATH=$PATH:`dirname $0`; export PATH
CMDNAME=`basename $0`
CWD=`dirname $0`
OUTDIR=.
USAGE="Usage: $CMDNAME [-l logdir] [-i interval] [-n cnt]"

# Set default params
INTERVAL=5
NTIMES=3
PCMD="/usr/bin/netstat"
PARG="-s"

# Get exec path
OSNAME=`uname -s`
case ${OSNAME} in
  FreeBSD ) 
    _PING="ping -c1 $_HOST"
		;;
  Linux   )
    PCMD="/bin/netstat"
    ;;
  HP-UX   )
    PCMD="/bin/netstat"
    ;;
  AIX     )
    PCMD="/bin/netstat"
    ;;
  SunOS   )
    PCMD="/usr/bin/netstat"
    ;;
        * ) echo "Unsupport : $OS" #知らないカーネルならエラー終了
esac

# Get command option
OPT=
while getopts js:l:i:n: OPT
do
    case $OPT in
    l) OUTDIR=$OPTARG
        ;;
    i) INTERVAL=$OPTARG
        ;;
    n) NTIMES=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`

OFILE=${OUTDIR}/netstats.txt

echo "OSNAME:$OSNAME" > $OFILE

if [ -x ${PCMD} ]; then
    PFCNT=1
    while test ${PFCNT} -le ${NTIMES}
    do
        # Sleep Interval
        if [ ${PFCNT} -ne ${NTIMES} ]; then
            sleep ${INTERVAL} &
        fi

        # Set Current Date
        /bin/date '+Date:%y/%m/%d %H:%M:%S' >> ${OFILE}

        # Exec ps command. 
        ${PCMD} ${PARG} >> ${OFILE}

        wait
        PFCNT=`expr ${PFCNT} + 1`
    done
else
    echo "$PCMD : not found."
    exit 1
fi
