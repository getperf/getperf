## Process this file with automake to produce Makefile.in

common_ldadd = \
	$(top_srcdir)/src/libgpfcommon.a 

soap_ldadd = \
	$(top_srcdir)/src/libgpfsoap.a 

zip_ldadd = \
	$(top_srcdir)/src/libgpfzip.a 

bin_PROGRAMS   = testcmd getperfctl

# テスト用コード
check_PROGRAMS = gpf_test

# テスト用コード(カテゴリ1)
gpf_test_SOURCES = unit_test.c \
test_gpf_admin.c \
test_gpf_agent.c \
test_gpf_common.c \
test_gpf_config.c \
test_gpf_log.c \
test_gpf_param.c \
test_gpf_process.c \
test_gpf_json.c \
test_gpf_soap_admin.c \
test_gpf_soap_agent.c \
test_gpf_soap_common.c 

gpf_test_LDADD = $(common_ldadd) $(soap_ldadd) $(zip_ldadd) 
gpf_test_CFLAGS = -DTEST -DWITH_OPENSSL -DDEBUG -std=c99  -D_SVID_SOURCE
gpf_test_LDFLAGS = -lz -lpthread -lcunit -lssl -lcrypto

# テスト用コード(コマンド)
testcmd_SOURCES = testcmd.c

testcmd_LDADD = $(common_ldadd) $(soap_ldadd) $(zip_ldadd) 
testcmd_CFLAGS = -DTEST -DWITH_OPENSSL -DDEBUG -std=c99  -D_SVID_SOURCE
testcmd_LDFLAGS = -lz -lpthread -lcunit -lssl -lcrypto

TESTS = tests.sh

getperfctl_SOURCE  = getperfctl.c
getperfctl_LDADD   = $(common_ldadd) $(soap_ldadd) $(zip_ldadd)
getperfctl_CFLAGS  = -DWITH_OPENSSL -std=c99
getperfctl_LDFLAGS = -lpthread -lz -lssl -lcrypto
