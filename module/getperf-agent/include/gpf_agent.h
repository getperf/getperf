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

#ifndef GETPERF_GPF_AGENT_H
#define GETPERF_GPF_AGENT_H

#include "gpf_process.h"
#include "ght_hash_table.h"

/**
 * Registration of task management structure.
 * Hash key is the unsigned long type of thread ID, but libght does not 
 * support unsinged long. To manage a value greater than 32bit, 
 * SIGSEGV error, change the hash key to a string in sprintf.
 */ 
int gpfInsertPids( ght_hash_table_t *Pids, void *task, GPFThreadId threadKey );

/**
 * Search of task management structure of thread key
 */ 
void *gpfGetPids( ght_hash_table_t *Pids, GPFThreadId threadKey );

/**
 * Deleting a task management structure of thread key.
 * If not exists, return NULL.
 */ 
void *gpfRemovePids( ght_hash_table_t *Pids, GPFThreadId threadKey );

/**
 * Initialization of the agent
 * ExecutePath ( execution path of getperf) is required . If you specify a relative 
 * path , automatically converted to an absolute path . If not specified configFile, 
 * a directory on one level of the execution path is initialized as the home directory , 
 * to load the getperf.ini. If mode is not of GPF_PROCESS_RUN, to initialize the 
 * semaphore for exclusive control .If you do not want to initialize the semaphore,
 * specify the GPF_PROCESS_INIT .
 */
int gpfInitAgent( GPFConfig **_config, char *executePath, char *configFile, int mode );

/**
 * Check exit flag file
 */
char *gpfCheckExitFile( GPFConfig *config);

/**
 * Run HA status script, regist service name
 */
int gpfCheckHAStatus( GPFConfig *config);

/**
 * Read {home}/ssl/License.txt, check license
 */
int gpfAuthLicense( GPFConfig *config, int expiredTime );

/**
 * Extract license file
 */
int gpfUnzipSSLConf( GPFConfig *config );

/**
 * Send SOAP attachement file
 */
int gpfExecSOAPCommandPM( GPFConfig *config, char *option, char *filePath );

/**
 * Download license file, check license
 */
int gpfCheckLicense( GPFConfig *config, int expiredTime );

/**
 * Check currTime time, set executable schedule, 
 * return executable schedule number
 */
int gpfCheckTimer( GPFConfig *config, time_t currTime );

/**
 * Pre operation of collector execute
 */
int gpfPrepareCollector( GPFConfig *config );

/**
 * Run scheduler
 */
int gpfRunScheduler( GPFConfig *config);

/**
 * Run collector
 */
#if defined(_WINDOWS)
unsigned WINAPI _gpfSpawnCollector( void *lpx );
#else
void * _gpfSpawnCollector( void * lpx );
#endif

GPFThreadId gpfSpawnCollector( GPFConfig *config, GPFCollector *collector );

/**
 * Run collector, command execute model
 */
pid_t gpfExecCollector( GPFConfig *config, GPFCollector *collector );

/**
 * Run collector
 */
int gpfRunCollector( GPFTask *task );

/**
 * Manage worker concurrent
 */
int gpfManageWorkerConcurrent( GPFTask *task );

/**
 * Manager worker serial
 */
int gpfManageWorkerSerial( GPFTask *task );

/**
 * Run worker, multithread model
 */
#if defined(_WINDOWS)
unsigned WINAPI _gpfSpawnWorker( void *lpx );
#else
void * _gpfSpawnWorker( void * lpx );
#endif

GPFThreadId gpfSpawnWorker( GPFTaskJob *taskJob );

/**
 * Run worker
 */
pid_t gpfRunWorker( GPFTaskJob *taskJob );

/**
 * Count running worker process
 */
int gpfCountWorkerPids( ght_hash_table_t *workerPids );

/**
 * Reap timeout or finished worker process
 */
int gpfReapTimeoutWorkers( ght_hash_table_t *timeoutPids, int nowait, int killAll );

/**
 * Reap timeout or finished worker process, limitTime is terminate time of all process.
 * If nowait is 0, it terminate immediately.
 */
int gpfReapTimeoutProcess( ght_hash_table_t *timeoutPids, int limitTime, int nowait );

/**
 * Purge collection data
 */
int gpfPurgeData( GPFTask *task );

/**
 * Report collector execute
 */
int gpfReportCollector( GPFTask *task );

/**
 * Archive arc_{host}__{CAT}_{YYYYMMDD}_{HHMISS}.zip 
 * from log/{CAT}/YYYYMMDD/HHMISS directory
 */
int gpfArchiveData( GPFTask *task );

/** 
 * Check zip log filename foward match
 */

int gpfCheckZipLogFormat( GPFTask *task, char *zipFile );

/** 
 * Check date format directory name
 */
int gpfCheckLogDateFormat( char *dirname );

/** 
 * Transfer all unsent data 
 */
int gpfSendCollectorDataAll( GPFTask *task );

/** 
 * Transfer unsent data 
 */
int gpfSendCollectorData( GPFTask *task, char *zipFile );

/**
 * Run exist process
 */
void gpfRunExit();

/**
 * Run Windows service
 */
#if defined _WINDOWS
void gpfServiceMain();
#endif

#endif
