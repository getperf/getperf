#ACLOCAL_AMFLAGS = -I m4

## Process this file with automake to produce Makefile.in
minizip_dir = $(top_srcdir)/src/minizip
minizip_src = $(minizip_dir)/src

gsoap_dir = $(top_srcdir)/gsoap
gsoap_src = $(gsoap_dir)/src
libgpfsoap_a_CFLAGS = -DWITH_OPENSSL

CFLAGS = -I$(minizip_dir)/include -I$(gsoap_dir)/include

common_ldadd = $(top_srcdir)/src/libgpfcommon.a 
soap_ldadd   = $(top_srcdir)/src/libgpfsoap.a 
zip_ldadd    = $(top_srcdir)/src/libgpfzip.a 

noinst_LIBRARIES   = libgpfcommon.a libgpfsoap.a libgpfzip.a

bin_PROGRAMS       = getperf getperfzip getperfsoap getperfctl logretrieve

getperf_SOURCE     = getperf.c
getperf_LDADD      = $(common_ldadd) $(zip_ldadd)
getperf_LDFLAGS    = -lpthread

getperfzip_SOURCE  = getperfzip.c
getperfzip_LDADD   = $(common_ldadd) $(zip_ldadd)
getperfzip_LDFLAGS = -lz

getperfsoap_SOURCE  = getperfsoap.c
getperfsoap_LDADD   = $(common_ldadd) $(soap_ldadd) $(zip_ldadd)
getperfsoap_LDFLAGS = -lpthread -lz -lssl -lcrypto 

logretrieve_SOURCE  = logretrieve.c
logretrieve_LDADD   = $(common_ldadd) $(zip_ldadd)
logretrieve_LDFLAGS = -lpthread

getperfctl_SOURCE  = getperfctl.c
getperfctl_LDADD   = $(common_ldadd) $(soap_ldadd) $(zip_ldadd)
getperfctl_CFLAGS  = -DWITH_OPENSSL -std=gnu99
getperfctl_LDFLAGS = -lpthread -lz -lssl -lcrypto 

libgpfcommon_a_SOURCES = \
	hash_functions.c hash_table.c \
	gpf_common.c gpf_config.c gpf_log.c gpf_param.c \
	gpf_process.c gpf_daemon.c gpf_admin.c gpf_agent.c \
	gpf_getopt.c gpf_regexp.c gpf_logrt.c \
	md5c.c mutexs.c

libgpfsoap_a_SOURCES = \
	gpf_soap_common.c gpf_soap_agent.c gpf_soap_admin.c \
	$(gsoap_src)/soapClient.c $(gsoap_src)/soapClientLib.c $(gsoap_src)/soapC.c $(gsoap_src)/stdsoap2.c

libgpfzip_a_SOURCES = \
	$(minizip_src)/ioapi.c $(minizip_src)/treeunz.c $(minizip_src)/treezip.c $(minizip_src)/unzip.c $(minizip_src)/zip.c 

