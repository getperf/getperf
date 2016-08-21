/* 
** GETPERF
** Copyright (C) 2009-2012 Getperf Ltd.
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

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_param.h"
#include "gpf_log.h"
#include "gpf_getopt.h"
#include "gpf_process.h"
#include "getperf.h"

#if defined(_WINDOWS)
#include "gpf_service.h"
#endif /* _WINDOWS */


char *gpfHelpMessage[] = {
	"getperf [--error(-e)] [--time(-t) [sec]] [--log(-l) [file]]",
	"Options:",
	"  -e --error            output error",
	"  -t --time             timeout sec",
	"  -l --log <output.txt> output file",
	0 /* end of text */
};

int main ( int argc, char **argv )
{
	int rc = 0;
	int option;
	int mode         = GPF_PROCESS_RUN;
	int exitCode     = 0;
	int timeout      = 10;
	char *outputFile = NULL;
	int elapse       = 0;
	FILE *out        = NULL;
	
	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{ "error", gpf_required_argument, 0, 'e' },
			{ "time",  gpf_required_argument, 0, 't' },
			{ "log",   gpf_required_argument, 0, 'l' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "e:t:l:", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 'e':
			mode = 1;
			exitCode = atoi(gpf_optarg);
			break;

		case 't':
			timeout = atoi(gpf_optarg);
			break;

		case 'l':
			outputFile = gpf_optarg;
			break;

		case '?':
		case 'h':
		default:
			gpfUsage ( gpfHelpMessage );
			exit(-1);
		}
	}

	if ( outputFile != NULL)
	{
		out = fopen( outputFile, "wb" );
	}
	else
	{
		out = stdout;
	}
#if defined _WINDOWS
	service_start();
#else
	gpfDaemonStart( "/dev/null" );
#endif

	printf ("timeout = %d\n", timeout);
	for ( elapse = 0; elapse <= timeout; elapse ++)
	{
		if ( elapse % 5 == 0)
		{
			fprintf( out, "%d\n", elapse );
			fflush( out );
		}
		
		if ( elapse <= timeout )
			sleep( 1 );
	}
	
	if ( outputFile != NULL )
		close( out );

	if ( mode == 1)
	{
		fprintf( stderr, "error occured!\ntestcmd\n" );
	}
	
	exit ( exitCode );
}
