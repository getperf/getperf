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
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/
 
#ifndef GETPERF_TREEZIP_H
#define GETPERF_TREEZIP_H

#include "gpf_config.h"
#include "gpf_common.h"

uLong filetime(char *f, tm_zip *tmzip, uLong *dt);
int getFileCrc(const char* filenameinzip,void*buf,unsigned long size_buf,unsigned long* result_crc);
int addZipfile(zipFile zf, char *basedir, char *filenameinzip, char *password);
int addZipTree(zipFile zf, char *basedir, char *parentpath, char *passwd);
int zipDir(char *zipfile, char *basedir, char *parentpath, char *passwd);


#endif /* GETPERF_TREEZIP_H */
