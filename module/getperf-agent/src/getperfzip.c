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

#define GPF_MAIN_MODULE 1
#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_param.h"
#include "gpf_log.h"
#include "gpf_getopt.h"
#include "getperfzip.h"

char *gpfHelpMessage[] = {
	"getperfzip [--zip(-z)|--unzip(-u)] [--password(-p) pass] [--base(-b) basedir]",
	"           [--dir(-d) dir] filename.zip",
	"Options:",
	"  -z --zip             archive data",
	"  -u --unzip           extract data",
	"  -p --password <pass> password",
	"  -b --base <dir>      base directory",
	"  -d --dir <dir>       path name",
	"  <filename.zip>",
	0 /* end of text */
};

int main ( int argc, char **argv )
{
	int rc = -1;
	int option;
	int zipFlag, unzipFlag;
	char *password, *base, *parent, *zipfile;
	GPFConfig *config = NULL;

	zipFlag = unzipFlag = 0;
	password = base = parent = zipfile = NULL;

	GCON = NULL;

	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{ "zip",      gpf_no_argument,       0, 'z' },
			{ "unzip",    gpf_no_argument,       0, 'u' },
			{ "password", gpf_required_argument, 0, 'p' },
			{ "base",     gpf_required_argument, 0, 'b' },
			{ "dir",      gpf_required_argument, 0, 'd' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "zup:b:d:", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 'z':
			zipFlag = 1;
			break;

		case 'u':
			unzipFlag = 1;
			break;

		case 'p':
			password  = gpf_optarg;
			break;

		case 'b':
			base      = gpf_optarg;
			break;

		case 'd':
			parent    = gpf_optarg;
			break;

		case '?':
		case 'h':
			gpfUsage ( gpfHelpMessage );
			goto errata;

		default:
			gpfUsage ( gpfHelpMessage );
			goto errata;
		}
	}

	if ( gpf_optind + 1 == argc )
		zipfile = argv[gpf_optind++];

	if ( zipFlag == unzipFlag || base == NULL || zipfile == NULL )
	{
		gpfUsage( gpfHelpMessage );
		exit(-1);
	}

	if ( (rc = gpfInitAgent( &config, argv[0], NULL )) == 0)
		exit (-1);
	gpfSwitchLog( config, NULL, NULL);

	if ( zipFlag == 1 && parent != NULL )
	{
		rc =  zipDir( zipfile, base, parent, password ) ;
	}
	else if ( unzipFlag == 1 )
	{
		rc = unzipDir( zipfile, base, password );
	}
	else
	{
		gpfUsage( gpfHelpMessage );
		exit(-1);
	}

errata:

	exit ( ( rc == 1 ) ? 0 : 1);
}
