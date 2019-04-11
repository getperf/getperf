/* 
** GETPERF
** Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
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
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/

/*
 * Function: strlcpy, strlcat
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

 /*
 * Function: rel2abs
 * Copyright (c) 1997 Shigio Yamaguchi. All rights reserved.
 * Copyright (c) 1999 Tama Communications Corporation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"

/**
 * malloc() extention. old shuld not be null
 */
void *_gpfMalloc2(char *filename, int line, void *old, size_t size)
{
	register int max_attempts;
	void *ptr = NULL;

	if(old != NULL)
	{
		gpfCrit("[file:%s,line:%d] gpfMalloc error. Already allocated memory." ,
			filename, line);
		return NULL;
	}

	for(max_attempts = 10, size = MAX(size, 1); 
		max_attempts > 0 && !ptr;
		max_attempts--)
	{
		ptr = malloc(size);
	}

	if (!ptr)
	{
		gpfCrit("[file:%s,line:%d] gpfMalloc error. requested '%lu' bytes.", 
			filename, line, size);
	}

	return ptr;
}

/**
 * realloc() extention
 */
void *_gpfRealloc2(char *filename, int line, void *src, size_t size)
{
	register int max_attempts;
	void *ptr = NULL;

	for(max_attempts = 10, size = MAX(size, 1); 
		max_attempts > 0 && !ptr;
		max_attempts--)
	{
		ptr = realloc(src, size);
	}

	if (!ptr)
	{
		gpfCrit("[file:%s,line:%d] gpfMalloc error. requested '%lu' bytes.", 
			filename, line, size);
	}

	return ptr;
}

/**
 * vsnprintf() extention. Add '\0' character to last
 */
int gpfSnprintf(char* str, size_t count, const char *fmt, ...)
{
	char *buffer = NULL;
	va_list	args;
	int	writen_len = 0;
    
	buffer = gpfMalloc( buffer, MAX_STRING_LEN );
	va_start(args, fmt);

	writen_len = vsnprintf( &buffer[0], MAX_STRING_LEN, fmt, args);
	writen_len = MIN(writen_len + 1, ((int)count) - 1);
	writen_len = MAX(writen_len, 0);

	va_end(args);
	gpfStrlcpy(str, buffer, writen_len);
	gpfFree( buffer );
	
	return writen_len;
}

/**
 * Replace string
 */
char *gpfStringReplace(char *str, char *src, char *dest)
{
	char *new_str = NULL;
	char *p;
	char *q;
	char *r;
	char *t;
	long len;
	long diff;
	unsigned long count = 0;

	len = (long)strlen(src);
	if ( len == 0 ) 
	{
		gpfError( "gpfStringReplace error : src size is 0" );
		return NULL;
	}

	/* count the number of occurances of src */
	for ( p=str; (p = strstr(p, src)); p+=len, count++ );

	if ( 0 == count )	return strdup(str);
	diff = (long)strlen(dest) - len;
	/* allocate new memory */
	new_str = gpfMalloc(new_str, 
		(size_t)(strlen(str) + count*diff + 1)*sizeof(char));

	for (q=str,t=new_str,p=str; (p = strstr(p, src)); )
	{
		/* copy until next occurance of src */
		for ( ; q < p; *t++ = *q++);
		q += len;
		p = q;
		for ( r = dest; (*t++ = *r++); );
		--t;
	}
	/* copy the tail of str */
	for( ; *q ; *t++ = *q++ );
	*t = '\0';
	
	return new_str;
}

/**
 * Trim right null character
 */
void gpfRtrim(char *str, const char *charlist)
{
	register char *p;

	if( !str || !charlist || !*str || !*charlist ) return;

	for(
		p = str + strlen(str) - 1;
		p >= str && NULL != strchr(charlist, *p);
		p--)
			*p = '\0';
}

/**
 * Trim left null character
 */
void gpfLtrim(register char *str, const char *charlist)
{
	register char *p;

	if (NULL == str || NULL == charlist || '\0' == *str || '\0' == *charlist)
		return;

	for (p = str; '\0' != *p && NULL != strchr(charlist, *p); p++)
		;

	if (p == str)
		return;
	
	while ('\0' != *p)
		*str++ = *p++;

	*str = '\0';
}

/**
 * Trim left and right null character
 */
void gpfLRtrim(char *str, const char *charlist)
{
	gpfRtrim(str, charlist);
	gpfLtrim(str, charlist);
}

/**
 * Remove null caracter
 */
void gpfRemoveChars(register char *str, const char *charlist)
{
	register char *p;

	if (NULL == str || NULL == charlist || '\0' == *str || '\0' == *charlist)
		return;

	for (p = str; '\0' != *p; p++)
		if (NULL == strchr(charlist, *p))
			*str++ = *p;

	*str = '\0';
}

/**
 * strncpy() extention. Copy string from src to dst, Add '\0' to last.
 */
size_t gpfStrlcpy(char *dst, const char *src, size_t siz)
{
	char *d = dst;
	const char *s = src;
	size_t n = siz;

	/* Copy as many bytes as will fit */
	if ( n != 0 ) {
		while ( --n != 0 ) {
			if ( ( *d++ = *s++ ) == '\0' )
				break;
		}
	}

	/* Not enough room in dst, add NUL and traverse rest of src */
	if (n == 0) {
		if (siz != 0)
			*d = '\0';     /* NUL -terminate dst */
		while (*s++)
		;
	}

	return(s - src - 1);   /* count does not include NUL */
}

/**
 * strncat() extention
 */
size_t gpfStrlcat(char *dst, const char *src, size_t siz)
{
	char *d = dst;
	const char *s = src;
	size_t n = siz;
	size_t dlen;

	/* Find the end of dst and adjust bytes left but don't go past end */
	while (n-- != 0 && *d != '\0')
		d++;
	dlen = d - dst;
	n = siz - dlen;

	if (n == 0)
		return(dlen + strlen(s));
	while (*s != '\0') {
		if (n != 1) {
			*d++ = *s;
			n--;
		}
		s++;
	}
	*d = '\0';

	dlen += (size_t)(s - src);
	if ( dlen >= siz )
		dlen = siz - 1;
	
	return(dlen);  /* count does not include NUL */
}

/**
 * vsnprintf() extention
 */
 char* gpfDsprintf(char *dest, const char *f, ...)
{
	char	*string = NULL;
	int	n, size = MAX_STRING_LEN >> 1;
	va_list args;
	va_list curr;

	va_start(args, f);

	while(1) {
		string = gpfMalloc(string, size);
		va_copy(curr, args);
		n = vsnprintf(string, size, f, curr);
		va_end(curr);

		if(n >= 0 && n < size)
			break;

		/* result was truncated */
		if (-1 == n)
			size = size * 3 / 2 + 1;	/* the length is unknown */
		else
			size = n + 1;	/* n bytes + trailing '\0' */

		gpfFree(string);
	}
	if(dest) gpfFree(dest);
	va_end(args);

	return string;
}

/**
 * strncat() extention
 */
char* gpfStrdcat(char *dest, const char *src)
{
	register int new_len = 0;
	char *new_dest = NULL;

	if(!src)	return dest;
	if(!dest)	return strdup(src);
	
	new_len += (int)strlen(dest);
	new_len += (int)strlen(src);
	
	new_dest = gpfMalloc(new_dest, new_len + 1);
	
	if(dest)
	{
		strcpy(new_dest, dest);
		strcat(new_dest, src);
		gpfFree(dest);
	}
	else
	{
		strcpy(new_dest, src);
	}

	new_dest[new_len] = '\0';

	return new_dest;
}

/**
 * 文字列の分割
 * 入力文字列はstrtok()関数内で更新されるため、静的変数の利用は不可
 * @param n   分割数
 * @param sep 連結文字(NULL 指定は不可)
 * @param string 対象文字列
 * @return 分割後の文字列配列
 */
char **gpfSplit(int *n, char *sep, char *string)
{
    char **array=NULL;
    char *p=string;
    char *s;

	*n = 0;
	if ( p == NULL)
		return NULL;
	
	for(*n=0; (s = strtok(p, sep)) != NULL; (*n)++) {
        array = (char**)gpfRealloc(array, sizeof(char*) * (*n+1));
        array[*n] = s;
        p = NULL;
    }
    
    return array;
}

/** 文字列の比較
 *
 * @param   a 比較する文字列
 * @param   b 比較する文字列
 *
 * @return  aの方が大きい場合は負数、bのほうが大きい場合は整数、aとbが同じ場合は0
 */

int gpfCompareString( const void* a, const void* b )
{
    return strcmp( * (char **) a, * (char **) b);
}

/** 文字列配列の初期化
 *
 * @return 文字列配列構造体のポインタ
 */
GPFStrings *gpfCreateStrings()
{
	GPFStrings *gs = NULL;

	gs = gpfMalloc( gs, sizeof( GPFStrings ) );
	gs->capacity = INITIAL_STR_LIST_SIZE;
	gs->strings  = (char **)malloc( sizeof(char *) * gs->capacity );
	gs->size     = 0;

	return gs;
}

/** 文字列配列のメモリ開放
 *
 * @param   gs 文字列配列構造体のポインタ
 */
void gpfFreeStrings(GPFStrings *gs)
{
	size_t i;
	if ( gs == NULL )
		return;
	for (i = 0; i < gs->size; i ++)
	{
		gpfFree( gs->strings[i] );
	}
	gpfFree( gs->strings );
	gpfFree( gs );
}

/** 文字列配列構造体に文字列を挿入。第二引数の静的変数の指定は不可
 *
 * @param   gs 文字列配列構造体のポインタ
 * @param   str 文字列
 *
 * @return  合否
 */
int gpfInsertStrings(GPFStrings *gs, char *str)
{
	int result = 1;
	char **list_tmp;
	
	gs->size ++;
	if ( gs->size >= gs->capacity )
	{
		gs->capacity += INITIAL_STR_LIST_SIZE;
		list_tmp = realloc( gs->strings, sizeof(char *) * gs->capacity );
		if( list_tmp == NULL )
		{
			gpfFreeStrings( gs );
			return 0;
		}
		gs->strings = list_tmp;
	}
	gs->strings[ gs->size - 1 ] = str;
	return result;
}

/**
 * ファイルパスを連結する
 * @param fmt   第一パス名
 * @param ...   可変長ファイルパス名
 * @return 連結後のパス
 */
char *gpfCatFile(const char *fmt, ...)
{
	char *parameter = NULL;
	char *result = NULL;
	va_list args;
	char *buffer = NULL;
	size_t length = 0;

	buffer = gpfMalloc( buffer, MAXFILENAME );
    memset(buffer, 0, MAXFILENAME);
	length += gpfStrlcat(buffer, fmt, MAXFILENAME);

	va_start(args, fmt);
    while ((parameter = va_arg(args, char *)) != NULL) 
	{
		if ((length + 1) >= MAXFILENAME)
			goto erange;
		length += gpfStrlcat(buffer, GPF_FILE_SEPARATORS, MAXFILENAME);
		if ((length + strlen(parameter)) >= MAXFILENAME)
			goto erange;
		length += gpfStrlcat(buffer, parameter, MAXFILENAME);
	}

finish:
	va_end(args);
	return buffer;

erange:
	va_end(args);
	gpfFree( buffer );
	gpfError("Buffer overflow : buffer[%d>%d]", length, MAXFILENAME);
	return (NULL);
}

/**
 * 相対パスを絶対パスに変換します
 * @param path   変換対象パス
 * @param base   基準ディレクトリ
 * @param result 変換結果格納バッファ
 * @param size   バッファサイズ
 * @return 絶対パス
 */
char *rel2abs(const char *path, const char *base, char *result, const size_t size)
{
	const char *pp, *bp;
	/*
	 * endp points the last position which is safe in the result buffer.
	 */
	const char *endp = result + size - 1;
	char *rp;
	int length;
	int path_length = strlen(path);
	
	if (*path == GPF_FILE_SEPARATOR) {
		if (path_length >= size)
			goto erange;
		strcpy(result, path);
		goto finish;
/*	} else if (*base != GPF_FILE_SEPARATOR || !size) {
		errno = EINVAL;
		return (NULL); */
	} else if (size == 1)
		goto erange;

	length = strlen(base);

	/* drive letter */
	if (path_length > 2)
	{
		if (*(path+1) == ':' || (*path == '\\' && *(path+1) == '\\'))
		{
			strcpy(result, path);
			goto finish;
		}
	}
	
	if (!strcmp(path, ".") || !strcmp(path, GPF_CURRENT_PATH)) {
		if (length >= size)
			goto erange;
		strcpy(result, base);
		/*
		 * rp points the last char.
		 */
		rp = result + length - 1;
		/*
		 * remove the last '/'.
		 */
		if (*rp == GPF_FILE_SEPARATOR) {
			if (length > 1)
				*rp = 0;
		} else
		rp++;
		/* rp point NULL char */
		if (*++path == GPF_FILE_SEPARATOR) {
			/*
			 * Append '/' to the tail of path name.
			 */
			*rp++ = GPF_FILE_SEPARATOR;
			if (rp > endp)
				goto erange;
			*rp = 0;
		}
		goto finish;
	}
	bp = base + length;
	if (*(bp - 1) == GPF_FILE_SEPARATOR)
		--bp;
	/*
	 * up to root.
	 */
	for (pp = path; *pp && *pp == '.'; ) {
		if (!strncmp(pp, GPF_PARENT_PATH, 3)) {
			pp += 3;
			while (bp > base && *--bp != GPF_FILE_SEPARATOR)
				;
		} else if (!strncmp(pp, GPF_CURRENT_PATH, 2)) {
			pp += 2;
		} else if (!strncmp(pp, "..\0", 3)) {
			pp += 2;
			while (bp > base && *--bp != GPF_FILE_SEPARATOR)
				;
		} else
			break;
	}
	/*
	 * down to leaf.
	 */
	length = bp - base;
	if (length >= size)
		goto erange;
	strncpy(result, base, length);
	rp = result + length;
	if (*pp || *(pp - 1) == GPF_FILE_SEPARATOR || length == 0)
		*rp++ = GPF_FILE_SEPARATOR;
	if (rp + strlen(pp) > endp)
		goto erange;
	strcpy(rp, pp);
finish:
	return result;
erange:
	errno = ERANGE;
	return (NULL);
}

/**
 * ホスト名の取得。「.」以降の文字列はカットし、大文字は小文字に変換する。
 * @param   *hostName ホスト名
 * @return  合否
 */

int gpfGetHostname (char *hostName)
{
	int i;
	char *p;
	
#if defined(_WINDOWS)
	DWORD computerNameLen = MAX_COMPUTERNAME_LENGTH + 1;

	if ( GetComputerName(hostName, &computerNameLen) )  
	{
#else
	if ( gethostname(hostName, MAX_COMPUTERNAME_LENGTH) == 0 ) 
	{
#endif
		if ((p = strchr(hostName, '.')) != NULL)
			*p = '\0';

		for ( i = 0; hostName[i] != '\0' || i < MAX_COMPUTERNAME_LENGTH; i++ ) 
		{
			hostName[i] = tolower(hostName[i]);
		}
	} 
	else 
	{
		printf("DEBUG: gpfGetHostname1 NG. %s\n", GetLastError());
		return gpfSystemError( "gethostname : host='%s'", hostName );
	}

	return 1;
}

/**
 * ディレクトリの作成。親ディレクトリが存在しない場合は順次作成する。
 * @param   *newdir ディレクトリパス
 * @return  合否
 */

int gpfMakeDirectory( char * newdir )
{
	char *buffer ;
	char *p;
	int  len = (int)strlen( newdir );

	if ( len <= 0 )
		return 0;

	buffer = (char*)malloc( len + 1);
	if ( buffer == NULL )
		return gpfSystemError( "allocating memory" );
	strcpy( buffer,newdir );

	if ( buffer[len - 1] == GPF_FILE_SEPARATOR ) 
	{
		buffer[len - 1] = '\0';
	}

	if ( mkdir( buffer, 0777) == 0)
	{
		free( buffer );
		return 1;
	}

	p = buffer + 1;
	while (1)
	{
		char hold;

		while ( *p && *p != GPF_FILE_SEPARATOR )
			p++;
		hold = *p;
		*p = 0;
		if (gpfCheckDirectory( buffer) == 0) 
		{
			if ( (mkdir( buffer, 0777) == -1) && ( errno == ENOENT ) )
			{
				gpfError( "couldn't create directory %s", buffer );
				free( buffer );
				return 0;
			}
		}
		if ( hold == 0 )
			break;

		*p++ = hold;
	}
	free( buffer );

	return 1;
}
 
/**
 * 実行パスから上位のディレクトリを絶対パスに変換して返す
 * @param inPath 入力パス
 * @param parentLevel 上位の階層の数
 * @return 合否
 */
char *gpfGetParentPathAbs( char *inPath, int parentLevel )
{
	char cwd[MAXFILENAME];
	char absPath[MAXFILENAME];
	char *ret = NULL;
	char *eol = NULL;

	if (!getcwd(cwd, sizeof(cwd)))
	{
		gpfError("Unable getcwd()");
		return NULL;
	}
	if (!rel2abs(inPath, cwd, absPath, MAXFILENAME))
	{
		gpfError("Unable rel2abs()");
		return NULL;
	}

	ret = strdup(absPath);
	while ( parentLevel > 0 )
	{
		eol = strrchr( ret, GPF_FILE_SEPARATOR );
		if (eol != NULL) 
			*eol = '\0';
		else
			break;
			
		parentLevel --;
	}

	return(ret);
}

/**
 * ディレクトリの存在確認
 * @param path 指定ディレクトリ
 * @return 合否
 */
#if defined(_WINDOWS)
int gpfCheckDirectory( const char *path)
{
	WIN32_FIND_DATA ffd;
	HANDLE  hFindFile = FindFirstFile(path, &ffd);
	if (hFindFile == INVALID_HANDLE_VALUE) 
	{
		return 0;
	}
	FindClose(hFindFile);
	if (ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		return 1;
	else
		return 0;
}
#else
int gpfCheckDirectory( const char *path)
{
	int result = 1;
	struct stat	sb;

	if (stat(path, &sb) == -1) 
		return 0;
	
	if (!S_ISDIR(sb.st_mode))
		result = 0;

	return result;
}
#endif

/**
 * ファイルのコピー
 * @param srcPath コピー元パス
 * @param targetPath コピー先パス
 * @return 合否
 */
#if defined(_WINDOWS)
int gpfCopyFile( const char *srcPath, const char *targetPath )
{
	int rc = 0;
	
	rc = CopyFile( srcPath, targetPath, FALSE );

	return rc;
}
#else
int gpfCopyFile( const char *srcPath, const char *targetPath )
{
	int rc       = 0;
	int srcFD    = -1;
	int targetFD = -1;
    int readSize = 0;
    char buff[MAX_BUF_LEN];

	if ( ( srcFD = open( srcPath, O_RDONLY ) ) == -1 )
	{
		gpfSystemError( "open %s", srcPath );
		goto errata;
	}
	
	if ( ( targetFD = open( targetPath, O_WRONLY|O_CREAT|O_TRUNC, 0666 ) ) == -1 )
	{
		gpfSystemError( "open %s", targetPath );
		goto errata;
	}

	while( ( readSize = read( srcFD ,buff, MAX_BUF_LEN) ) > 0 )
	{
	    if( write( targetFD, buff, readSize) == -1 )
	    {
			gpfSystemError( "write %s", targetPath );
	    	goto errata;
	    }
	}
	rc = 1;

	errata:
	if ( srcFD != -1 )
		close( srcFD );
	if ( targetFD != -1 )
		close( targetFD );

	return rc;
}
#endif

/**
 * ワークファイルの読み込み(先頭行のみ)
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
int gpfReadWorkFileHead( GPFConfig *config, char *filename, char **buf, int maxRows)
{
	return _gpfReadWorkFile( config, filename, buf, maxRows);
}

/**
 * ワークファイルの読み込み(全行)
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @return 合否
 */
int gpfReadWorkFile( GPFConfig *config, char *filename, char **buf)
{
	return _gpfReadWorkFile( config, filename, buf, 0);
}

/**
 * ワークファイルから数値の読み込み
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param value 数値
 * @return 合否
 */
int gpfReadWorkFileNumber( GPFConfig *config, char *filename, int *num )
{
	int rc = 0;
	char *value = NULL;
	char *invalidValue = NULL;
	
	if ( !_gpfReadWorkFile( config, filename, &value, 0) )
		goto errange;
	
	*num = strtol(value, &invalidValue, 10);  
	if (*invalidValue == '\0' || *invalidValue == '\n' )
		rc = 1;
	
errange:
	gpfFree( value );
	return rc;
}

/**
 * ワークファイルの確認
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfCheckWorkFile( GPFConfig *config, char *filename )
{
	char *workDir  = NULL;
	char *workPath = NULL;
	int rc         = 0;
	struct stat stats;

	workDir = (*filename == '_')?config->workCommonDir:config->workDir;
	workPath = gpfCatFile(workDir, filename, NULL);
	gpfDebug("workPath=%s", workPath);

	rc = ( stat( workPath, &stats) == 0 ) ? 1 : 0;
	gpfFree( workPath );
	
	return( rc );
}

/**
 * ワークファイルの削除
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfRemoveWorkFile( GPFConfig *config, char *filename )
{
	char *workDir  = NULL;
	char *workPath = NULL;
	int rc         = 0;
	struct stat stats;

	workDir = (*filename == '_')?config->workCommonDir:config->workDir;
	workPath = gpfCatFile(workDir, filename, NULL);
	gpfDebug("delete workPath=%s", workPath);

	if ( stat( workPath, &stats) == 0 )
	{
		rc = ( unlink( workPath ) == 0 ) ? 1 : 0;
	}
	gpfFree( workPath );
	
	return( rc );
}

/**
 * ワークファイルの読み込み
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param result バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
int _gpfReadWorkFile( GPFConfig *config, char *filename, char **result, int maxRows)
{
	char *workDir  = NULL;
	char *workPath = NULL;
	char *buf      = NULL;
	FILE *file     = NULL;
	int lineno     = 0;
	int rc         = 0;
	char *line     = NULL;
	char *base     = NULL;
	struct stat stats;

	line = gpfMalloc( line, MAX_BUF_LEN );
	gpfDebug("filename=%s,maxrows=%d", filename, maxRows);
	workDir = (*filename == '_')?config->workCommonDir:config->workDir;
	workPath = gpfCatFile(workDir, filename, NULL);
	gpfDebug("workPath=%s", workPath);

	if ( stat( workPath, &stats) != 0)
	{
//		gpfSystemError("%s", workPath);
		goto errange;
	}

	if( (file = fopen(workPath, "r")) == NULL)
	{
		gpfSystemError("%s", workPath);
		goto errange;
	}

	for( lineno = 1; 
		( base = fgets(line, MAX_BUF_LEN, file) ) != NULL; 
		lineno++ )
	{
//	gpfDebug("ln=%s", line);
		if ( maxRows != 0 && lineno > maxRows )
			break;
		if (lineno == 1)
			buf = gpfDsprintf(buf, "%s", line);
		else
			buf = gpfStrdcat( buf, line );
	}
	result[0] = buf;
//	gpfDebug("buf=%s", buf);

	rc = 1;

	errange:

	gpfFree(line);
	gpfFree(workPath);
	gpf_fclose(file);
	gpfDebug("_gpfReadWorkFile:END");

	return rc;
}

/**
 * ワークファイルへの数値の書き込み。ファイル名が'_'で始まる場合は共有ディレクトリ_wkに保存し、そうでない場合はローカルディレクトリ_wk/_{pid}に保存する
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param num 数値
 * @return 合否
 */
int gpfWriteWorkFileNumber( GPFConfig *config, char *filename, int num )
{
	int rc = 0;
	char *value = NULL;

	gpfDebug("write %s[%d]", filename, num );
	value= gpfDsprintf( value, "%d", num );
	rc = gpfWriteWorkFile( config, filename, value );

	gpfFree( value );
	return ( rc );
}

/**
 * ワークファイルの書き込み。ファイル名が'_'で始まる場合は共有ディレクトリ_wkに保存し、そうでない場合はローカルディレクトリ_wk/_{pid}に保存する
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @return 合否
 */
int gpfWriteWorkFile( GPFConfig *config, char *filename, char *buf)
{
	char *workDir  = NULL;
	char *workPath = NULL;
	FILE *file     = NULL;
	int lineno     = 0;
	char line[MAX_BUF_LEN];
	struct stat stats;

	workDir = (*filename == '_')?config->workCommonDir:config->workDir;
	workPath = gpfCatFile(workDir, filename, NULL);

	if( (file = fopen(workPath, "w")) == NULL)
	{
		gpfSystemError("%s", workPath);
		goto errange;
	}
	if ( fputs(buf, file) == -1)
	{
		gpfSystemError("%s", workPath);
		goto errange;
	}

	gpfFree(workPath);
	gpf_fclose(file);
	return 1;

	errange:
	gpfFree(workPath);
	gpf_fclose(file);
	return 0;
}

/**
 * ディレクトリの削除
 * @param dirPath ディレクトリパス
 *
 * @return 合否
 */
int gpfRemoveDir( char *dirPath ) 
{
	char *cmd = NULL;
	int rc = 1;

	if ( dirPath == NULL )
		return gpfError("directory is null");

	cmd = gpfMalloc( cmd, MAX_STRING_LEN );

#ifdef _WINDOWS
	gpfSnprintf(cmd, MAX_STRING_LEN, "rmdir /S /Q \"%s\"", dirPath);
#else
	gpfSnprintf(cmd, MAX_STRING_LEN, "/bin/rm -rf \"%s\" 2> /dev/null", dirPath);
#endif
	
	if (system(cmd) != 0) 
		rc = gpfSystemError( "%s", cmd );

	gpfFree( cmd );

	return rc;
}

/**
 * ワークディレクトリの削除
 * @param config エージェント構造体
 *
 * @return 合否
 * Windowsでディレクトリは空になるが、ディレクトリ自体が消えない問題発生。
 * 起動時に不要な_wk/_{PID}は全て削除して貰うよう暫定策適用。
 */
int gpfRemoveWorkDir( GPFConfig *config ) 
{
	char cmd[MAX_STRING_LEN];
	char *workDir = NULL;

	if ( config == NULL )
		return gpfError("config is null");

	if ( ( workDir = config->workDir) == NULL )
		return gpfError("work dir is null");

#ifdef _WINDOWS
	gpfSnprintf(cmd, MAX_STRING_LEN, "rd /S /Q %s", workDir);
	system(cmd);
#else
	gpfSnprintf(cmd, MAX_STRING_LEN, "/bin/rm -rf \"%s\" 2> /dev/null", workDir);
	gpfInfo("[RemoveWorkDir] %s", cmd);
	if (system(cmd) != 0) 
		return gpfSystemError( "%s", cmd );
#endif
	
	return 1;
}

/**
 * 現在時刻の取得
 *
 * @param   
 * @return  浮動小数点の経過秒
 */

double	gpfTime(void)
{
#if defined(_WINDOWS)

	struct _timeb current;
	_ftime(&current);

	return (((double)current.time) + 1.0e-6 * ((double)current.millitm));

#else /* not _WINDOWS */

	struct timeval current;

	if ( gettimeofday( &current, NULL ) )
		gpfSystemError( "gettimeofday()" );

	return (((double)current.tv_sec) + 1.0e-6 * ((double)current.tv_usec));

#endif /* _WINDOWS */

}

/**
 * プロセスのタイトルを設定する
 * @param fmt フォーマット
 * @param ... 可変長引数
 */
void	gpfSetproctitle(const char *fmt, ...)
{

#ifdef HAVE_PRCTL
	int rc;
	char title[ MAX_STRING_LEN ];

	va_list args;

	va_start( args, fmt );
	vsnprintf( title, MAX_STRING_LEN - 1, fmt, args );
	va_end( args );

	printf( "set proctitle : %s", title );
	if ( ( rc = prctl(PR_SET_NAME, title ) ) != 0)
		gpfSystemError("prctl");

#endif /* HAVE_PRCTL */

}

/** キー入力。入力がない場合は処理待ちしない
 *
 * @return  キー入力コード
 */
#if defined _WINDOWS

int gpfGetch() 
{
	int ch = 0;
	char *yesno = NULL;

	if ( _kbhit() )
		ch = _getch();

	/* 継続しますか(n/y) */
	if ( ch != 0 ) 
	{
		gpfGetLine( GPF_MSG052E, GPF_MSG052, &yesno );
		if ( strcmp( yesno, "y" ) == 0 )
		{
			ch = 0;
		}
		gpfFree( yesno );
	}

	return ch;
}

#else

int gpfGetch() 
{
	char in_char   = 0; /* 入力されたキーを保持 */
	int oldf;
	char read_byte = 0; /* 読み込んだバイト数 */
	struct termios tty_backup; /* 変更前の設定を保持 */
	struct termios tty_change; /* 変更後の設定を保持 */
	char *yesno = NULL;
	
	tcgetattr( STDIN_FILENO, &tty_backup );
	tty_change = tty_backup;
	tty_change.c_lflag &= ~( ICANON | ECHO );
	tcsetattr( STDIN_FILENO, TCSANOW, &tty_change );
	oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
	fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
	read_byte = read(0, &in_char, 1);
	if (read_byte == 0)
	{
		fflush(NULL);
	}
	tcsetattr( STDIN_FILENO, TCSANOW, &tty_backup );
	fcntl(STDIN_FILENO, F_SETFL, oldf);
	
	/* 継続しますか(n/y) */
	if ( in_char > 0 ) 
	{
		gpfGetLine( GPF_MSG052E, GPF_MSG052, &yesno );
		if ( strcmp( yesno, "y" ) == 0 )
		{
			in_char = 0;
		}
		gpfFree( yesno );
	}
	else
	{
		sleep(1);
	}
	return in_char;
}

#endif

/**
 * メッセージを出力し、1行入力する
 * @param commonFormat 英語メッセージ
 * @param localFormat 日本語メッセージ
 * @param result バッファ
 * @return 合否
 */
int gpfGetLine( char *commonFormat, char *localFormat, char **result)
{
	char *message = NULL;
	char *buf = NULL;
	char line[MAX_STRING_LEN];

	message = (GCON != NULL && GCON->localeFlag == 0) ? commonFormat : localFormat;
	if (*result) {
		printf("%s[%s]:", message, *result); 
	} else {
		printf("%s:", message); 
	}
	if (fgets( line, MAX_STRING_LEN, stdin ) == NULL)
	{
		return 0;
	}
	gpfRtrim( line, GPF_CFG_RTRIM_CHARS );

	if (strcmp(line, "") != 0) {
		buf = strdup( line );
		result[0] = buf;
	}
	
	return 1;
}

/**
 * パスワードを入力する
 * @param commonFormat 英語メッセージ
 * @param localFormat 日本語メッセージ
 * @param result バッファ
 * @return 合否
 */
int gpfGetPass( char *commonFormat, char *localFormat, char **result)
{
	char *message = NULL;

#if defined(_WINDOWS)

	int i = 0;
	int ch;
	char line[MAX_STRING_LEN];
	char *buf;
	
	message = (GCON != NULL && GCON->localeFlag == 0) ? commonFormat : localFormat;
	fputs( message , stdout);

	i = 0;
	while ( i < MAX_STRING_LEN )
	{
		ch = _getch();
		if (ch == '\b') 
		{
			if (i > 0) 
			{
				fputs("\b \b", stdout);
				i--;
			}
			continue;
		} 
		else if (ch < 0x20 || ch > 0x7e) 
			break;

		line[i] = ch;
		fputs("*", stdout);
		i++;
	}
	line[i] = '\0';

	fputs("\n", stdout);
	buf = strdup(line);
	result[0] = buf;
    return 1; 

#else

	struct termios oflags, nflags; 
	int i = 0;
	int ch;
	char line[MAX_STRING_LEN];
	char *buf;
	
	message = (GCON != NULL && GCON->localeFlag == 0) ? commonFormat : localFormat;
	fputs( message , stdout);

    /* disabling echo */ 
    tcgetattr(fileno(stdin), &oflags); 
    nflags = oflags; 

#ifdef __sun
	nflags.c_iflag &= ~(IMAXBEL|IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
	nflags.c_oflag &= ~OPOST;
	nflags.c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
	nflags.c_cflag &= ~(CSIZE|PARENB);
	nflags.c_cflag |= CS8;
#else
	cfmakeraw(&nflags);
#endif

    if (tcsetattr(fileno(stdin), TCSANOW, &nflags) != 0) 
        return gpfSystemError("tcsetattr"); 
 
	i = 0;
	while ( i < MAX_STRING_LEN )
	{
		ch = getchar();
		if (ch == '\b') 
		{
			if (i > 0) 
			{
				fputs("\b \b", stdout);
				i--;
			}
			continue;
		} 
		if (ch == '\r' || ch == '\n')
			break;
		line[i] = ch;
		fputs("*", stdout);
		i++;
	}
	line[i] = '\0';
 
    /* restore terminal */ 
    if (tcsetattr(fileno(stdin), TCSANOW, &oflags) != 0) 
        return gpfSystemError("tcsetattr"); 

	fputs("\n", stdout);
	buf = strdup(line);
	result[0] = buf;
    return 1; 

#endif

}

/**
 * 指定したフォーマット形式で何秒前の現在時刻を取得
 * @param sec 経過秒
 * @param format フォーマット
 * @param type フォーマットタイプ
 *   GPF_DATE_FORMAT_DEFAULT         0
 *   GPF_DATE_FORMAT_YYYYMMDD        1
 *   GPF_DATE_FORMAT_HHMISS          2
 *   GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
 *   GPF_DATE_FORMAT_DIR             4
 * @return 合否
 */
int gpfGetCurrentTime( int sec, char *format, int type)
{
	time_t    t;

	t = time(NULL) - sec;
	return gpfGetTimeString( t, format, type );
}

/**
 * 指定したフォーマット形式で時刻を変換
 * @param t 時刻
 * @param format フォーマット
 * @param type フォーマットタイプ
 *   GPF_DATE_FORMAT_DEFAULT         0
 *   GPF_DATE_FORMAT_YYYYMMDD        1
 *   GPF_DATE_FORMAT_HHMISS          2
 *   GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
 *   GPF_DATE_FORMAT_DIR             4
 * @return 合否
 */
int gpfGetTimeString( time_t t, char *format, int type)
{
	struct tm *tm;
	tm = localtime(&t);
	if (type == GPF_DATE_FORMAT_YYYYMMDD)
		gpfSnprintf( format, MAX_STRING_LEN, 
			"%.4d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday);
	else if (type == GPF_DATE_FORMAT_HHMISS)
		gpfSnprintf( format, MAX_STRING_LEN, 
			"%.2d%.2d%.2d" , 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_YYYYMMDD_HHMISS)
		gpfSnprintf( format, MAX_STRING_LEN, 
			"%.4d%.2d%.2d_%.2d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_DIR)
		gpfSnprintf( format, MAX_STRING_LEN, 
			"%.4d%.2d%.2d%s%.2d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			GPF_FILE_SEPARATORS,
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_DEFAULT)
		gpfSnprintf( format, MAX_STRING_LEN, 
			"%.4d/%.2d/%.2d %.2d:%.2d:%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else
		return gpfError("unkown date format type");

	return 1;
}

/**
 * 指定したフォーマット形式で時刻を変換
 * @param t 時刻
 * @param format フォーマット
 * @param type フォーマットタイプ
 *   GPF_DATE_FORMAT_DEFAULT         0
 *   GPF_DATE_FORMAT_YYYYMMDD        1
 *   GPF_DATE_FORMAT_HHMISS          2
 *   GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
 *   GPF_DATE_FORMAT_DIR             4
 * @return 合否
 */
int gpfDGetTimeString( char **format, int type, time_t t )
{
	struct tm *tm;
	tm = localtime(&t);
	if (type == GPF_DATE_FORMAT_YYYYMMDD)
		*format = gpfDsprintf(*format,
			"%.4d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday);
	else if (type == GPF_DATE_FORMAT_HHMISS)
		*format = gpfDsprintf(*format,
			"%.2d%.2d%.2d" , 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_YYYYMMDD_HHMISS)
		*format = gpfDsprintf(*format,
			"%.4d%.2d%.2d_%.2d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_DIR)
		*format = gpfDsprintf(*format,
			"%.4d%.2d%.2d%s%.2d%.2d%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			GPF_FILE_SEPARATORS,
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else if (type == GPF_DATE_FORMAT_DEFAULT)
		*format = gpfDsprintf(*format,
			"%.4d/%.2d/%.2d %.2d:%.2d:%.2d" , 
			tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday, 
			tm->tm_hour, tm->tm_min, tm->tm_sec);
	else
		return gpfError("unkown date format type");

	return 1;
}

/**
 * 指定したディレクトリのディスク使用量[%]を取得
 * @param dir パス名
 * @param capacity ディスク使用率
 * @return 合否
 */

 #ifdef _WINDOWS

int gpfCheckDiskFree(char *dir, int *capacity)
{
	char driveName[MAXFILENAME]; 
	char *endPtr;
	BOOL success;
	unsigned long sectorsPerCluster;
	unsigned long bytesPerSector;
	unsigned long freeClusters;
	unsigned long clusters;
	
	if (!gpfStrlcpy(driveName, dir, MAXFILENAME))
		return gpfError("gpfStrlcpy : %s", dir);

	driveName[sizeof(driveName) - 1] = 0;
	endPtr = strchr(driveName, '\\');
	if (!endPtr || endPtr >= driveName + sizeof(driveName) - 1) 
		return gpfError("path must include '\\' : %s", driveName);
	*(endPtr + 1) = 0;

	success = GetDiskFreeSpace(driveName, &sectorsPerCluster, 
		&bytesPerSector, &freeClusters, &clusters);

	if (!success)
		return gpfSystemError("GetDiskFreeSpace");

	if (clusters == 0)
		return gpfError("clusters size is 0");

	*capacity = (int)( ((double)freeClusters) / ((double)clusters) * 100.0 );

	return 1;
}

#else

int gpfCheckDiskFree(char *dir, int *capacity)
{
	int rc = 0;

#ifdef HAVE_SYS_STATVFS_H
	struct statvfs fs;
	rc = statvfs(dir, &fs);

#else
	struct statfs fs;
#  ifdef HAVE___STATFS_SOLARIS
	rc = statfs(dir, &fs, 0, 0);
#  else
	rc = statfs(dir, &fs);
#  endif
#endif
	if (rc != 0)
		return gpfSystemError("%s", dir);

	if (fs.f_blocks == 0)
		return gpfError("blocks size is 0");

	*capacity = (int)(((double)fs.f_bavail/(double)fs.f_blocks) * 100.0);

	return 1;
}

#endif

/**
 * ディスク容量のチェック
 * @param config エージェント構造体
 * @return 合否
 */
int gpfCheckDiskUtil( GPFConfig *config)
{
	int rc    = 0;
	int free  = 0;
	int limit = 0;

	if (config == NULL || config->home == NULL)
		return gpfError("home is null");

	if (config->schedule == NULL)
		return gpfError("schedule is null");

	limit = config->schedule->diskCapacity;

	rc = gpfCheckDiskFree(config->home, &free);
	rc = rc && (free <= limit)?0:1;
	
	gpfNotice("Disk Free[%d] > %d : %s", free, limit, (rc == 1)?"OK":"NG");

	return rc;
}

/**
 * パスがホーム下を指定しているか、".."が含まれないかをチェックする
 * 
 * @param config エージェント構造体
 * @param path パス名
 * @return 合否
 */
int gpfCheckPathInHome( GPFConfig *config, const char *path )
{
	if ( strstr( path, config->home ) != path)
		return gpfError( "path error (home) %s", path );

	/* ".."が2回以上含まれている場合はNG */

#if defined _WINDOWS
	if ( strstr( path, "../.." ) != NULL )
		return gpfError( "path error (../..) %s", path );
#else
	if ( strstr( path, "..\\.." ) != NULL )
		return gpfError( "path error (..\\..) %s", path );
#endif

	return 1;
}

/**
 * ヘルプメッセージの出力
 */
void gpfUsage( char **msgs )
{
	printf("%s v%s (build %d)\n", APPLICATION_NAME, GPF_VERSION, GPF_BUILD);

	while (*msgs) printf("%s\n", *msgs++);
}

/**
 * コピー元からコピー先への上書きコピー
 * (ディレクトリの場合はその下のファイルを全てコピーする)
 * @param srcDir ソースディレクトリ
 * @param targetDir ターゲットディレクトリ
 * @param filename ファイル名
 * @return 合否
 */
#if defined _WINDOWS

int gpfBackupConfig( char *srcDir, char *targetDir, char *filename )
{
	int rc              = 0;
	char *suffix        = NULL;
	char *srcPath       = NULL;
	char *srcPathNew    = NULL;
	char *targetPath    = NULL;
	char *targetPathNew = NULL;

	srcPath = gpfCatFile( srcDir, filename, NULL );
	targetPath = gpfCatFile( targetDir, filename, NULL );

	gpfDebug( "COPY DIR %s --> %s", srcPath, targetPath );
	/* ディレクトリの場合はその下の.iniファイルを全てコピーする */
	if ( gpfCheckDirectory( srcPath )  == 1 )
	{
		char *searchPath = NULL;
		WIN32_FIND_DATA fd;
		HANDLE h;

		if ( gpfCheckDirectory( targetPath ) == 0 )
			gpfMakeDirectory( targetPath );

		searchPath = gpfCatFile(srcPath, "*", NULL);
	    h = FindFirstFileEx(searchPath, FindExInfoStandard, &fd, FindExSearchNameMatch, NULL, 0);
		gpfFree(searchPath);

	    if ( INVALID_HANDLE_VALUE == h ) 
		{
			gpfSystemError( "open %s", srcPath );
			goto errata;
		}

		while ( FindNextFile( h, &fd ) )
		{
			if ( (suffix = strchr( fd.cFileName, '.')) != NULL)
			{
				suffix ++;
				if ( *suffix == '\0' || strcmp(suffix, ".") == 0 )
					continue;
			}
			if ( ( rc = gpfBackupConfig( srcPath, targetPath, fd.cFileName ) ) == 0 ) 
				break;

		}
	    FindClose( h );
	}
	/* ファイルの場合はディレクトリパス指定でコピー */
	else if (! ( GetFileAttributes( srcPath ) & FILE_ATTRIBUTE_DIRECTORY ) )
	{
		gpfDebug( "COPY FILE %s --> %s", srcPath, targetPath );
		if ( ( rc = gpfCopyFile( srcPath, targetPath ) ) == 0 )
		{
			gpfError( "copy %s %s failed", srcPath, targetPath );
			goto errata;
		}
	}
	
	errata:
	gpfFree( srcPath );
	gpfFree( targetPath );
	
	return rc;
}

#else

int gpfBackupConfig( char *srcDir, char *targetDir, char *filename )
{
	int rc              = 0;
	DIR	*dir            = NULL;
	char *suffix        = NULL;
	char *srcPath       = NULL;
	char *srcPathNew    = NULL;
	char *targetPath    = NULL;
	char *targetPathNew = NULL;
	struct dirent *d    = NULL;
	struct stat	  sb;

	srcPath = gpfCatFile( srcDir, filename, NULL );
	targetPath = gpfCatFile( targetDir, filename, NULL );

	/* ディレクトリの場合はその下の.iniファイルを全てコピーする */
	if ( gpfCheckDirectory( srcPath )  == 1 )
	{
		if ( gpfCheckDirectory( targetPath ) == 0 )
			gpfMakeDirectory( targetPath );

		if ((dir = opendir( srcPath )) == NULL ) 
		{
			gpfSystemError("open %s", srcPath);
			goto errata;
		}

		while ((d = readdir(dir)) != NULL) 
		{
			if ( (suffix = strchr(d->d_name, '.')) != NULL)
			{
				suffix ++;
				if ( *suffix == '\0' || strcmp(suffix, ".") == 0 )
					continue;
			}
			if ( ( rc = gpfBackupConfig( srcPath, targetPath, d->d_name ) ) == 0 ) 
				break;

		}

		if ( closedir(dir) == -1) 
		{
			gpfSystemError("close %s", srcPath);
			goto errata;
		}
	}
	/* ファイルの場合はディレクトリパス指定でコピー */
	else if ( stat( srcPath, &sb ) != -1 && S_ISREG( sb.st_mode ) )
	{
		if ( ( rc = gpfCopyFile( srcPath, targetPath ) ) == 0 )
		{
			gpfError( "copy %s %s failed", srcPath, targetPath );
			goto errata;
		}
	}
	
	errata:
	gpfFree( srcPath );
	gpfFree( targetPath );
	
	return rc;
}
#endif 

