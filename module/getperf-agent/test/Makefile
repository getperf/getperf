CC=gcc
#CC=/usr/vacpp/bin/xlC
#CC=/opt/SUNWspro/bin/CC
#CC=CC

LOCALDIR   = /usr
INCLOCAL   = ../include
SRCDIR     = ../src
INCGSOAP   = ../gsoap/include

INCSSL     = $(LOCALDIR)/local/ssl/include
LIBSSL     = $(LOCALDIR)/local/ssl/lib

COMMON_OBJ = $(SRCDIR)/libgpfcommon.a
SOAP_OBJ   = $(SRCDIR)/libgpfsoap.a
ZIP_OBJ    = $(SRCDIR)/libgpfzip.a

CFLAGS=-g -Wall -O2 -I. -I/usr/local/include -I$(INCLOCAL) -I$(INCSSL) -I$(INCGSOAP) -L$(LIBSSL) -DTEST -DWITH_OPENSSL -DDEBUG -std=gnu99  -D_SVID_SOURCE
LD=ld 
RM=rm -f

LDFLAGS=-lnsl -lz -lpthread -lcunit -lssl -lcrypto -ldl

TARGET=all

SRCTEST=unit_test.c \
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

OBJTEST=$(SRCTEST:.c=.o)
OUTTEST=gpf_test

SRCTESTCMD=testcmd.c

OBJTESTCMD=$(SRCTESTCMD:.c=.o)
OUTTESTCMD=testcmd

all: test testcmd

test: $(OBJTEST) $(COMMON_OBJ) $(SOAP_OBJ) $(ZIP_OBJ)
	$(CC) $(CFLAGS) -o $(OUTTEST)    $(OBJTEST)    $(COMMON_OBJ) $(SOAP_OBJ) $(ZIP_OBJ) $(CUNITLLIB) $(LDFLAGS) 

testcmd: $(OBJTESTCMD) $(COMMON_OBJ) $(SOAP_OBJ) $(ZIP_OBJ)
	$(CC) $(CFLAGS) -o $(OUTTESTCMD) $(OBJTESTCMD) $(COMMON_OBJ) $(SOAP_OBJ) $(ZIP_OBJ) $(CUNITLLIB) $(LDFLAGS) 

%.o: %.c
	$(CC) $(CFLAGS) $(OSFLAGS) -o $@ -c $<

clean:
	-$(RM) $(OBJTEST) $(OBJTESTCMD) $(OUTTEST) $(OUTTESTCMD) core

