#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT(getperf, 2.5.0, furusawa@getperf.com)
AM_INIT_AUTOMAKE([foreign no-installinfo dist-bzip2 no-dist-gzip])
AC_CONFIG_SRCDIR([src/gpf_config.c])
AC_CONFIG_HEADER([include/config.h])
AC_PREFIX_DEFAULT([dist/ptune])

# Checks for programs.
AC_PROG_CC

# Checks for libraries.

AC_CHECK_LIB([z], [gzread], [],
    [AC_MSG_ERROR([zlib not found, see http://www.zlib.net])])

#AC_CHECK_LIB([ssl], [SSL_library_init], [], 
#	[AC_MSG_FAILURE([OpenSSL not found, see http://www.openssl.org/])])

ACCEPT_SSL_LIB="no"
AC_CHECK_LIB(ssl, OPENSSL_init_ssl, [ACCEPT_SSL_LIB="yes"])
AC_CHECK_LIB(ssl, SSL_library_init, [ACCEPT_SSL_LIB="yes"])
AS_IF([test "x$ACCEPT_SSL_LIB" = xno], [AC_MSG_ERROR([library 'ssl' is required for OpenSSL])])

#AC_CHECK_LIB([crypto], [SSL_library_init], [], 
#	[AC_MSG_FAILURE([OpenSSL not found, see http://www.openssl.org/])])

AC_CHECK_LIB([pthread], [main], [],
	[AC_MSG_FAILURE([pthread not found])])

AC_SEARCH_LIBS([gethostbyname], [nsl])
AC_SEARCH_LIBS([socket], [socket], ,
   [AC_CHECK_LIB([nsl], [socket], LIBS="$LIBS -lsocket -lnsl", , -lsocket)])

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([arpa/inet.h regex.h fcntl.h float.h limits.h locale.h netdb.h \
	netinet/in.h stdarg.h stddef.h stdint.h stdlib.h string.h strings.h \
	sys/file.h sys/ioctl.h sys/socket.h sys/statvfs.h time.h sys/time.h \
	sys/types.h sys/timeb.h sys/sem.h termios.h unistd.h utime.h errno.h \
    openssl/ssl.h sys/prctl.h pthread.h sys/signal.h sys/sysctl.h assert.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_TYPE_PID_T
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM
AC_CHECK_TYPES([ptrdiff_t])

# Checks for library functions.
AC_PROG_RANLIB
AC_FUNC_FORK
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MALLOC
AC_FUNC_MKTIME
AC_FUNC_REALLOC
AC_FUNC_SELECT_ARGTYPES
AC_TYPE_SIGNAL
AC_FUNC_STAT
AC_FUNC_STRERROR_R
AC_FUNC_STRFTIME
AC_FUNC_STRTOD
AC_FUNC_UTIME_NULL
AC_FUNC_VPRINTF
AC_FUNC_CLOSEDIR_VOID
AC_C_INLINE
AC_FUNC_MEMCMP
AC_HEADER_STAT
AC_CHECK_FUNCS([ftime getcwd gethostbyname gettimeofday localtime_r \
	memmove memset mkdir select socket strchr strdup strerror \
	strncasecmp strndup strstr strtoull utime vsnprintf vasprintf \
	getcwd mkdir dup2 strchr strtol prctl gethostname strrchr getlogin_r])

AC_CONFIG_FILES([
	Makefile
	src/Makefile
])
AC_OUTPUT
