#!/bin/sh
ERR=/dev/null

# Set Initial Parameter
#         "_pwd_/getpsutil.sh -i 30 -n 60 -l _odir_",

LANG=C; export LANG
PATH=$PATH:`dirname $0`; export PATH
CMDNAME=`basename $0`
CWD=`dirname $0`
OUTDIR=.
USAGE="Usage: $CMDNAME [logdir]"

# Set default params
INTERVAL=5
NTIMES=3
PCMD="/bin/ps"
PARG="-eF"

# Get exec path
OSNAME=`uname -s`
case ${OSNAME} in
  FreeBSD ) 
    PCMD="/bin/ps"
    PARG="-axo user,pid,ppid,%cpu,%mem,rss,vsz,args"
		;;
  Linux   )
    PCMD="/bin/ps"
    PARG="-eo user,pid,ppid,%cpu,%mem,rss,vsz,args"
    ;;
  HP-UX   )
    PCMD="/bin/ps"
    ;;
  AIX     )
    PCMD="/bin/ps"
    ;;
  SunOS   )
    PCMD="/usr/bin/ps"
    ;;
        * ) 
    echo "Unsupport : $OS"
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

OFILE=${OUTDIR}/ps.txt

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
