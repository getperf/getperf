/*
   minizip.c
   Version 1.1, February 14h, 2010
   sample part of the MiniZip project - ( http://www.winimage.com/zLibDll/minizip.html )

         Copyright (C) 1998-2010 Gilles Vollant (minizip) ( http://www.winimage.com/zLibDll/minizip.html )

         Modifications of Unzip for Zip64
         Copyright (C) 2007-2008 Even Rouault

         Modifications for Zip64 support on both zip and unzip
         Copyright (C) 2009-2010 Mathias Svensson ( http://result42.com )
*/


#ifndef _WINDOWS
        #ifndef __USE_FILE_OFFSET64
                #define __USE_FILE_OFFSET64
        #endif
        #ifndef __USE_LARGEFILE64
                #define __USE_LARGEFILE64
        #endif
        #ifndef _LARGEFILE64_SOURCE
                #define _LARGEFILE64_SOURCE
        #endif
        #ifndef _FILE_OFFSET_BIT
                #define _FILE_OFFSET_BIT 64
        #endif
#endif

// #if defined(_WINDOWS)
// #pragma warning(disable : 4996)
// #include	<windows.h>
// #include	<wincon.h>
// #include <direct.h>
// #include <io.h>
// #endif

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"

#include "zip.h"
#include "treezip.h"

#ifdef WIN32
        #define USEWIN32IOAPI
        #include "iowin32.h"
#endif


#ifdef WRITEBUFFERSIZE
#define WRITEBUFFERSIZE (16384)
#endif

#ifdef _WINDOWS
uLong filetime(char *f, tm_zip *tmzip, uLong *dt) 
{
	int ret = 0;
	FILETIME ftLocal;
	HANDLE hFind;
	WIN32_FIND_DATA ff32;

	hFind = FindFirstFile(f,&ff32);
	if (hFind != INVALID_HANDLE_VALUE)
	{
		FileTimeToLocalFileTime(&(ff32.ftLastWriteTime),&ftLocal);
		FileTimeToDosDateTime(&ftLocal,((LPWORD)dt)+1,((LPWORD)dt)+0);

		FindClose(hFind);
		ret = 1;
	}

	return ret;
}
#else
uLong filetime(char *f, tm_zip *tmzip, uLong *dt) 
{
  int ret=0;
  struct stat s;        /* results of stat() */
  struct tm* filedate;
  time_t tm_t=0;

  if (strcmp(f,"-")!=0)
  {
    char name[MAXFILENAME+1];
    int len = strlen(f);
    if (len > MAXFILENAME)
      len = MAXFILENAME;

    gpfStrlcpy(name, f, MAXFILENAME - 1);
    /* strncpy doesnt append the trailing NULL, of the string is too long.  */
    name[ MAXFILENAME ] = '\0';
    if (name[len - 1] == '/')
      name[len - 1] = '\0';
    /* not all systems allow stat'ing a file with / appended  */
    if (stat(name,&s)==0)
    {
      tm_t = s.st_mtime;
      ret = 1;
    }
  }
  filedate = localtime(&tm_t);

  tmzip->tm_sec  = filedate->tm_sec;
  tmzip->tm_min  = filedate->tm_min;
  tmzip->tm_hour = filedate->tm_hour;
  tmzip->tm_mday = filedate->tm_mday;
  tmzip->tm_mon  = filedate->tm_mon ;
  tmzip->tm_year = filedate->tm_year;

  return ret;
}
#endif

/* calculate the CRC32 of a file, because to encrypt a file, we need known the CRC32 of the file before */
int getFileCrc(const char* filenameinzip,void*buf,unsigned long size_buf,unsigned long* result_crc)
{
   unsigned long calculate_crc=0;
   int err=ZIP_OK;
   FILE * fin = fopen64(filenameinzip,"rb");
   unsigned long size_read = 0;
   unsigned long total_read = 0;
   if (fin==NULL)
   {
       err = ZIP_ERRNO;
   }

    if (err == ZIP_OK)
        do
        {
            err = ZIP_OK;
            size_read = (int)fread(buf,1,size_buf,fin);
            if (size_read < size_buf)
                if (feof(fin)==0)
            {
                gpfError("error in reading %s", filenameinzip);
                err = ZIP_ERRNO;
            }

            if (size_read>0)
                calculate_crc = crc32(calculate_crc,buf,size_read);
            total_read += size_read;

        } while ((err == ZIP_OK) && (size_read>0));

    if (fin)
        fclose(fin);

    *result_crc=calculate_crc;
    return err;
}

int isLargeFile(const char* filename)
{
  int largeFile = 0;
  ZPOS64_T pos = 0;
  FILE* pFile = fopen64(filename, "rb");

  if(pFile != NULL)
  {
    int n = fseeko64(pFile, 0, SEEK_END);

    pos = ftello64(pFile);

	gpfDebug("File : %s is %lld bytes", filename, pos);

    if(pos >= 0xffffffff)
     largeFile = 1;

                fclose(pFile);
  }

 return largeFile;
}

// ファイルをパスワード付きで zip 圧縮
int addZipfile(zipFile zf, char *basedir, char *filenameinzip, char *password) 
{
	int err = ZIP_OK;
    int opt_compress_level=Z_DEFAULT_COMPRESSION;
	void* buf    = NULL;
	int size_buf = WRITEBUFFERSIZE;
	FILE * fin;
	int size_read;
	const char *savefilenameinzip;
	zip_fileinfo zi;
	unsigned long crcFile=0;
	int zip64 = 0;

	buf = (void*)malloc(size_buf);
	if (buf==NULL) {
		gpfError("[Error] allocating memory");
		return ZIP_INTERNALERROR;
	}

	zi.tmz_date.tm_sec = zi.tmz_date.tm_min = zi.tmz_date.tm_hour =
	zi.tmz_date.tm_mday = zi.tmz_date.tm_mon = zi.tmz_date.tm_year = 0;
	zi.dosDate = 0;
	zi.internal_fa = 0;
	zi.external_fa = 0;
	filetime(filenameinzip,&zi.tmz_date,&zi.dosDate);

	if ((password != NULL) && (err==ZIP_OK))
		err = getFileCrc(filenameinzip, buf, size_buf, &crcFile);

	zip64 = isLargeFile(filenameinzip);
	/* The path name saved, should not include a leading slash. */
	/*if it did, windows/xp and dynazip couldn't read the zip file. */
	savefilenameinzip = filenameinzip;
	while( savefilenameinzip[0] == '\\' || savefilenameinzip[0] == '/' )
	{
		savefilenameinzip++;
	}

	err = zipOpenNewFileInZip3_64(zf,savefilenameinzip,&zi,
		NULL,0,NULL,0,NULL /* comment*/,
		(opt_compress_level != 0) ? Z_DEFLATED : 0,
		opt_compress_level,0,
		/* -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, */
		-MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
		password,crcFile, zip64);

	if (err != ZIP_OK)
		gpfError("[Error] Can't open %s", filenameinzip);
	else {
		char *filepathinzip = NULL;
		int retry = GPF_SOAP_RETRY;

		filepathinzip = gpfCatFile( basedir, filenameinzip, NULL );
		while (retry > 0 ) {
			fin = fopen64(filepathinzip,"rb");
			if (fin==NULL) {
				err=ZIP_ERRNO;
				gpfSystemError("[Error] Can't opening %s for reading", filepathinzip);
				sleep(10);
			} else {
				err=ZIP_OK;
				break;
			}
			retry --;
		}
		gpfFree(filepathinzip);
	}

	if (err == ZIP_OK) {
		do {
			err = ZIP_OK;
			size_read = (int)fread(buf, 1, size_buf, fin);
			if (size_read < size_buf)
				if (feof(fin)==0) {
					gpfError("[Error] Can't read %s", filenameinzip);
					err = ZIP_ERRNO;
				}

			if (size_read>0) {
				err = zipWriteInFileInZip (zf,buf,size_read);
				if (err<0) {
					gpfError("[Error] Can't write %s", filenameinzip);
				}
			}
		} while ((err == ZIP_OK) && (size_read>0));
	}

	if (fin)
		fclose(fin);

	if (err<0)
		err=ZIP_ERRNO;
	else {
		err = zipCloseFileInZip(zf);
		if (err!=ZIP_OK)
			gpfError("[Error] Can't close %s", filenameinzip);
	}

	gpfFree( buf );
	return err;
}

// �ィレクトリ下�ファイルを�帰�に検索し�zip圧縮する
int addZipTree(zipFile zf, char *basedir, char *parentpath, char *passwd) {
	char fullname[MAXFILENAME];
	char *fullpath = NULL;


#if defined(_WINDOWS)
	HANDLE           hnd;
	WIN32_FIND_DATA  file_list;
	char strFindPath[MAXFILENAME];
	errno = 0;

	// �定パスの*検索
	fullpath = gpfCatFile(basedir, parentpath, NULL);
	sprintf(strFindPath, "%s/*", fullpath); 
	gpfFree(fullpath);
	hnd = FindFirstFile( strFindPath, &file_list );
	if(hnd == INVALID_HANDLE_VALUE)
	{
		gpfError("[Error] %s %s", parentpath, strerror(errno)); 
		return(-1);
	}
	while (FindNextFile( hnd, &file_list )) {

		if ((strcmp (file_list.cFileName, ".")) != 0 && 
			(strcmp (file_list.cFileName, "..")) != 0) { 
			strcpy(fullname, parentpath);
			strcat(fullname, "/"); 
			strcat(fullname, file_list.cFileName); 
			if (file_list.dwFileAttributes == 0x00000010) {
				addZipTree(zf, basedir, fullname, passwd); 
			} else {
				addZipfile(zf, basedir, fullname, passwd);
				gpfNotice("Add : %s", fullname);
			}
		}
	}
	FindClose(hnd);

#elif defined(__sun)

	fullpath = gpfCatFile(basedir, parentpath, NULL);
	DIR *dir = opendir (fullpath); 
	gpfFree(fullpath);
	if (dir == NULL ) {
		gpfError("[Error] %s %s", parentpath, strerror(errno)); 
		return(-1);
	}
	struct dirent *dcon;
	struct stat dstuff;
	struct stat s;

	while (dcon = readdir (dir)) {
		if ((strcmp (dcon->d_name, ".")) != 0 && 
			(strcmp (dcon->d_name, "..")) != 0) { 
			strcpy(fullname, parentpath);
			strcat(fullname, "/"); 
			strcat(fullname, dcon->d_name); 

			stat(dcon->d_name, &s);
			if (s.st_mode & S_IFDIR) {
				addZipTree(zf, basedir, fullname, passwd); 
			} else {
				addZipfile(zf, basedir, fullname, passwd);
				gpfInfo("Add : %s", fullname);
			}
		}
	} 
	closedir (dir);

#else

	fullpath = gpfCatFile(basedir, parentpath, NULL);
	DIR *dir = opendir (fullpath); 
	gpfFree(fullpath);
	if (dir == NULL ) {
		gpfError("[Error] %s %s", parentpath, strerror(errno)); 
		return(-1);
	}
	struct dirent *dcon;
	struct stat dstuff;

	while (dcon = readdir (dir)) {
		if ((strcmp (dcon->d_name, ".")) != 0 && 
			(strcmp (dcon->d_name, "..")) != 0) { 
			strcpy(fullname, parentpath);
			strcat(fullname, "/"); 
			strcat(fullname, dcon->d_name); 

            stat(dcon->d_name, &dstuff);
            if (dstuff.st_mode & S_IFDIR) {
            // if (dcon->d_namelen == 4) {
				addZipTree(zf, basedir, fullname, passwd); 
			} else {
				addZipfile(zf, basedir, fullname, passwd);
				gpfInfo("Add : %s", fullname);
			}
		}
	} 
	closedir (dir);

#endif

	return(0);
}

// �ィレクトリをzip圧縮する
int zipDir(char *zipfile, char *basedir, char *parentpath, char *passwd) 
{
	int err = 0;
	int errclose;
	zipFile zf;
	int opt_overwrite = 1;

	char cwd[MAXFILENAME];

	#if defined(_WINDOWS)
		zlib_filefunc_def ffunc;
	#	endif

	if (getcwd(cwd, sizeof(cwd)) == NULL)
	{
		gpfSystemError("getcwd failed");
		return 0;
	}
	if (chdir(basedir) != 0) {
		gpfError("[Error] chdir %s", basedir);
		return(errno);
	}

	#if defined(_WINDOWS)
        fill_win32_filefunc64A(&ffunc);
        zf = zipOpen2_64(zipfile,(opt_overwrite==2) ? 2 : 0,NULL,&ffunc);
	#	else
//        zf = zipOpen64(zipfile,(opt_overwrite==2) ? 2 : 0);
        zf = zipOpen(zipfile,(opt_overwrite==2) ? 2 : 0);
	#	endif

	if (zf == NULL) {
		gpfSystemError("%s", zipfile);
		err= ZIP_ERRNO;
	} else {
		gpfDebug( "[ZIP] %s", zipfile);

		err = addZipTree(zf, basedir, parentpath, passwd); 

		errclose = zipClose(zf, NULL);
		if (errclose != ZIP_OK) {
			gpfError("[Error] close %s\n", zipfile);
			err = errclose;
		}
	}
	if (chdir(cwd) != 0)
	{
		gpfSystemError("chdir failed");
		return 0;
	}

	return (err == 0)?1:0;
}
