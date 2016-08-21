#!/bin/sh

PWD=`dirname $0`
SITE_HOME="${HOME}/conf/IZA5971/moi"
GP_HOME="${PWD}/../"
#GP_TEST_HOME=${GP_HOME}
GP_TEST_HOME="${PWD}/../test/cfg"

cp -r "${SITE_HOME}/ptune/ssl"  ${GP_TEST_HOME}
cp "${GP_HOME}/src/getperf"     ${GP_TEST_HOME}
cp "${GP_HOME}/src/getperfsoap" ${GP_TEST_HOME}
cp "${GP_HOME}/src/getperfzip"  ${GP_TEST_HOME}
cp "${GP_HOME}/src/getperfctl"  ${GP_TEST_HOME}

sleep 1
#valgrind -v --track-origins=yes --error-limit=no --leak-check=yes --show-reachable=no \
#valgrind -v  --leak-check=full --show-reachable=no --error-limit=no --leak-check=yes  \
#--suppressions=/usr/lib/valgrind/openssl.sup \
#valgrind -v  --leak-check=full --show-reachable=no --error-limit=no --leak-check=yes  \
#$srcdir/gpf_test -s gpf_common  2>&1 | \
#tee valgrind.log
$srcdir/gpf_test -s gpf_param -t 8
#perl test_getperfzip.pl
#perl test_getperfsoap2.pl
#perl test_getperf.pl
#${GP_TEST_HOME}/reset_dat.sh
#${GP_HOME}/build/ptune/bin/setup
#${GP_HOME}/build/ptune/bin/getperf
