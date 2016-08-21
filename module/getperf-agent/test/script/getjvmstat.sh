#!/bin/sh
#
# This procedure gets JVM heap information by jvmstat
#

LANG=C;export LANG
COLUMNS=160;export COLUMNS
CWD=`dirname $0`
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-l dir] [-e errfile] [-i interval] [-c cnt] [-v JDK_ver]"

# --------- JVM ŠÂ‹«•Ï”Ý’è --------------
. ${CWD}/jvm_env
#JAVA_HOME=/usr/local/bin/jvm/1.4.2/bin;export JAVA_HOME
JVMSTAT_HOME=${CWD}/jvmstat;export JVMSTAT_HOME
PATH=$JAVA_HOME/bin:$JVMSTAT_HOME/bin:$PATH;export PATH

# Set default params
DIR=.
ERR=/dev/null
INTERVAL=1
NTIMES=2
JDK="142"

# Check number of args
if [ $# -lt 1 ]; then
        echo "$USAGE" 1>&2
        exit 1
fi
if [ ! -d ${JAVA_HOME} -or ! -d ${JVMSTAT_HOME} ]; then
        echo "$USAGE" 1>&2
        exit 1
fi

# Get command option
OPT=
while getopts m:l:e:i:c:v: OPT
do
        case $OPT in
        l)      DIR=$OPTARG
                ;;
        e)      ERR=$OPTARG
                ;;
        i)      INTERVAL=$OPTARG
                ;;
        c)      NTIMES=$OPTARG
                ;;
        v)      JDK=$OPTARG
                ;;
        \?)     echo "$USAGE" 1>&2
                exit 1
                ;;
        esac
done
shift `expr $OPTIND - 1`

# Set current Date & Time
INTERVAL=`expr 1000 '*' $INTERVAL`
OUTDIR=${DIR}
WORK=${CWD}/../_wk

# Check directory 
if [ ! -d ${OUTDIR} ]; then
    /bin/mkdir -p ${OUTDIR}
    /bin/chmod 777 ${OUTDIR}
else
    /bin/rm -rf ${OUTDIR}
    /bin/mkdir -p ${OUTDIR}
    /bin/chmod 777 ${OUTDIR}
fi
if [ ! -d ${WORK} ]; then
    /bin/mkdir -p ${WORK}
    /bin/chmod 777 ${WORK}
fi

if [ ! -d $JAVA_HOME ]; then
    echo "$USAGE" 1>&2
    exit 1
fi

if [ "141" -eq ${JDK} ]; then
	# Get JVM process list JDK 1.4.1
	JVMLIST=${OUTDIR}/jvmlist.txt
	if [ -x /usr/ucb/ps ]; then
	    # Execute ps.
	    /usr/ucb/ps -axww 1> $WORK/jvmlist.tmp 2> $ERR
	    # Reformat process list.
	    perl $CWD/refjvmlist2.pl $WORK/jvmlist.tmp > $JVMLIST
	else
	    echo "$USAGE" 1>&2
	    exit 1
	fi
else
	# Get JVM process list JDK 1.4.2
	JVMLIST=${OUTDIR}/jvmlist.txt
	if [ -x $JVMSTAT_HOME/bin/jvmps ]; then
	    # Execute jvmps.
	    $JVMSTAT_HOME/bin/jvmps -v 1> $WORK/jvmlist.tmp 2> $ERR
	    # Reformat process list.
	    perl $CWD/refjvmlist.pl $WORK/jvmlist.tmp > $JVMLIST
	else
	    echo "$USAGE" 1>&2
	    exit 1
	fi
fi

# Invoke jvmstat each processes.
JVMSTAT_CMD="${JVMSTAT_HOME}/bin/jvmstat"
exec < ${JVMLIST}
while read LINE
do
    # Set jvmstat command line.
    JVMSTAT_ARG=`echo ${LINE} | perl -F, -lane 'print "-gc $F[0]"'`
    JVMSTAT_ARG="${JVMSTAT_ARG} ${INTERVAL} ${NTIMES}"
    JVMSTAT_OFILE=`echo ${LINE} | perl -F, -lane 'print "$F[1].txt"'`

    # Exec jvmstat.
    /bin/date '+Date:%Y/%m/%d %H:%M:%S' > ${OUTDIR}/${JVMSTAT_OFILE}
    ${JVMSTAT_CMD} ${JVMSTAT_ARG} >> ${OUTDIR}/${JVMSTAT_OFILE} &
done

exit 0

