/*
** GETPERF
** Copyright (C) 2015-2016, Minoru Furusawa, Toshiba corporation.
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**/

#ifndef GETPERF_TYPES_H
#define GETPERF_TYPES_H

#define	GPF_FS_DBL		"%lf"
#define	GPF_FS_DBL_EXT(p)	"%." #p "lf"

#define GPF_FS_SIZE_T		"%u"
#define gpf_fs_size_t		unsigned int	/* use this type only in calls to printf() for formatting size_t */

#define GPF_PTR_SIZE		sizeof(void *)

#if defined(_WINDOWS)

#ifdef _UNICODE
#	define gpf_stat(path, buf)		__gpf_stat(path, buf)
#	define gpf_open(pathname, flags)	__gpf_open(pathname, flags | O_BINARY)
#else
#	define gpf_stat(path, buf)		_stat64(path, buf)
#	define gpf_open(pathname, flags)	open(pathname, flags | O_BINARY)
#endif

#ifdef UNICODE
#	include <strsafe.h>
#	define gpf_wsnprintf StringCchPrintf
#	define gpf_strlen wcslen
#	define gpf_strchr wcschr
#	define gpf_strstr wcsstr
#	define gpf_fullpath _wfullpath
#else
#	define gpf_wsnprintf gpf_snprintf
#	define gpf_strlen strlen
#	define gpf_strchr strchr
#	define gpf_strstr strstr
#	define gpf_fullpath _fullpath
#endif

#ifndef __UINT64_C
#	define __UINT64_C(x)	x
#endif

#	define gpf_uint64_t unsigned __int64
#	define GPF_FS_UI64 "%I64u"
#	define GPF_FS_UO64 "%I64o"
#	define GPF_FS_UX64 "%I64x"

/* #	define stat		_stat64 */
#	define snprintf		_snprintf

#	define alloca		_alloca

#ifndef uint32_t
#	define uint32_t	__int32
#endif

#ifndef PATH_SEPARATOR
#	define PATH_SEPARATOR	'\\'
#endif

#else	/* _WINDOWS */

#	define gpf_stat(path, buf)		stat(path, buf)
#	define gpf_open(pathname, flags)	open(pathname, flags)

#	ifndef __UINT64_C
#		ifdef UINT64_C
#			define __UINT64_C(c) (UINT64_C(c))
#		else
#			define __UINT64_C(c) (c ## ULL)
#		endif
#	endif

#	define gpf_uint64_t uint64_t
#	if __WORDSIZE == 64
#		define GPF_FS_UI64 "%lu"
#		define GPF_FS_UO64 "%lo"
#		define GPF_FS_UX64 "%lx"
#		define GPF_OFFSET 10000000000000000UL
#	else
#		ifdef HAVE_LONG_LONG_QU
#			define GPF_FS_UI64 "%qu"
#			define GPF_FS_UO64 "%qo"
#			define GPF_FS_UX64 "%qx"
#		else
#			define GPF_FS_UI64 "%llu"
#			define GPF_FS_UO64 "%llo"
#			define GPF_FS_UX64 "%llx"
#		endif
#		define GPF_OFFSET 10000000000000000ULL
#	endif

#ifndef PATH_SEPARATOR
#	define PATH_SEPARATOR	'/'
#endif

#endif	/* _WINDOWS */

#ifndef S_ISREG
#	define S_ISREG(x) (((x) & S_IFMT) == S_IFREG)
#endif

#ifndef S_ISDIR
#	define S_ISDIR(x) (((x) & S_IFMT) == S_IFDIR)
#endif

#define GPF_STR2UINT64(uint, string) sscanf(string, GPF_FS_UI64, &uint)
#define GPF_OCT2UINT64(uint, string) sscanf(string, GPF_FS_UO64, &uint)
#define GPF_HEX2UINT64(uint, string) sscanf(string, GPF_FS_UX64, &uint)

#define GPF_CONST_STRING(str) ""str

#endif
