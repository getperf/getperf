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

#ifndef GETPERF_GPF_CONFIG_H
#define GETPERF_GPF_CONFIG_H

#include "sysinc.h"
#include "ght_hash_table.h"

/**
 * getperfctl command
 */

typedef enum
{
	GPF_CMD_NONE = 0,
	GPF_CMD_START,
	GPF_CMD_STOP,
	GPF_CMD_LOAD,
	GPF_CMD_INSTALL,
	GPF_CMD_REMOVE,
	GPF_CMD_SETUP
} gpf_task_t;

/**
 * Process status
 */

typedef enum
{
	GPF_PROCESS_INIT = 0,
	GPF_PROCESS_WAIT,
	GPF_PROCESS_RUN,
	GPF_PROCESS_TIMEOUT,
	GPF_PROCESS_END,
	GPF_PROCESS_ERROR
} gpf_collector_t;

/**
  * Default set fo getperf.ini
  */

#define GPF_DEFAULT_DISK_CAPACITY 100
#define GPF_DEFAULT_SAVE_HOUR     3
#define GPF_DEFAULT_RECOVERY_HOUR 3
#define GPF_DEFAULT_MAX_ERROR_LOG 500
#define GPF_LIMIT_MAX_ERROR_LOG   10000
#define GPF_DEFAULT_PROXY_PORT    8080
#define GPF_DEFAULT_LOG_LEVEL     3
#define GPF_DEFAULT_LOG_SIZE      100000
#define GPF_DEFAULT_LOG_ROTATION  5
#define GPF_DEFAULT_LOG_LOCALIZE  1

/**
  * Thread ID type
  */

typedef unsigned long GPFThreadId;

/**
  * Structure of the variable string  
  */

#define INITIAL_STR_LIST_SIZE 100

typedef struct GPFStrings_t
{
	char **strings;
	size_t	capacity;
	size_t	size;
} GPFStrings;

/**
  * Worker Job
  */

typedef struct GPFJob_t
{
  int     id;     /**< Primary key(sequence) */
  int     pid;    /**< Worker process id */
  int     status; /**< Process status */

  char    *cmd;   /**< Execute command */
	char	*ofile;	  /**< Output file */
	int		cycle;	  /**< Interval(sec) */
	int		step;	    /**< Execute count */

    struct  GPFJob_t    *next;  /**< Next job */
} GPFJob;

/**
  * Collector 
  */

typedef struct GPFCollector_t
{
  int     id;                 /**< primary key(sequence) */
  char    *statName;          /**< Metric */
  int     pid;                /**< Collector process id */
  int     status;             /**< Process status */

  int     statEnable;         /**< Enabled */
	int     build;				      /**< Build version */
  int     statStdoutLog;      /**< Standard output flag */
  int     statInterval;       /**< Interval(sec) */
  int     statTimeout;        /**< Timeout(sec) */
  
  time_t  nextTimestamp;      /**< Next start time(UTC) */
  time_t  startTimestamp;     /**< Start time(UTC) */
  time_t  endTimestamp;       /**< End time(UTC) */
  
  char    *dateDir;           /**< Date directory */
  char    *timeDir;           /**< Time directory */
  char    *odir;              /**< Output directory */

  char    *statMode;          /**< Stataus mode */

  struct  GPFJob_t    *jobStart;  /**< First job */
  struct  GPFCollector_t  *next;  /**< Next job */
} GPFCollector;

/**
  * Scheduler 
  */

typedef struct GPFSchedule_t
{
    int     diskCapacity;       /**< Disk free threshold(%) */
    int     saveHour;           /**< Metric data retention(H) */
    int     recoveryHour;       /**< Metric data retransmission(H) */
    int     maxErrorLog;        /**< Max rows of error output */

    int     pid;                /**< Scheduler process id */
    int     status;             /**< Process status */

    int     logLevel;           /**< Log level */
    int     debugConsole;       /**< Console log enabled */
    int     logSize;            /**< Log size */
    int     logRotation;        /**< Number of log rotation */
    int     logLocalize;        /**< Flag of Japanese log */

    int     hanodeEnable;       /**< HA node check flag */
    char    *hanodeCmd;         /**< HA node check script */

    int     postEnable;         /**< Post command enabled */
    char    *postCmd;           /**< Post command */

    int     remhostEnable;      /**< Remote transfer enabled */
    char    *urlCM;             /**< Web service URL (Configuration manager) */
    char    *urlPM;             /**< Web service URL (Performance manager) */
    int     soapTimeout;        /**< Web service timeout */
    char    *siteKey;           /**< Site key */
    
    int     proxyEnable;        /**< HTTP proxy enabled */
    char    *proxyHost;         /**< Proxy host */
    int     proxyPort;          /**< Proxy port */

    time_t  _last_update;       /**< Last update of parameter file */

    struct  GPFCollector_t  *collectorStart;    /**< First collector */
} GPFSchedule;

/**
  * SSL manager
  */

typedef struct GPFSSLConfig_t
{
	char    *hostname;      /* Hostname(Converted to lowercase , except the domain part) */
  char    *expired;       /* Expired date(YYYYMMDD) */
  char    *code;          /* Passowrd */
} GPFSSLConfig;

/**
  * Log manager
  */

typedef struct GPFLogConfig_t
{
    char    *logDir;        /**< Log directory */
    char    *logFile;       /**< Log filename */
    char    *logPath;       /**< Absolute log file path */
    char    *module;        /**< Module */
    int     logLevel;       /**< Log level */
    int     iniFlag;        /**< Initial flag */
    int     showLog;        /**< Console log flag */
    int     logSize;        /**< Log size */
    int     logRotation;    /**< Log rotation */
    int     lockOk;         /**< Log exclusive lock flag */
} GPFLogConfig;

/** 
  * Agent
  */

typedef struct GPFConfig_t
{
  int     module;         /**< Module id(S:Scheduler, C:Collector, W:Worker) */
  time_t  elapseTime;     /**< Elapsed time(sec) */
  time_t  startTime;      /**< Start time(UTC) */
  int     mode;           /**< Status(INIT, WAIT, RUN, ...) */
  pid_t   managedPid;     /**< Scheduler process id */
	int		  localeFlag;		  /**< Localization flag(0:English, 1:Japanese) */
	int     daemonFlag;     /**< Daemon flag */
	char    *host;          /**< Hostname(Convert to lowercase , except the domain part) */
  char    *serviceName;   /**< HA service name */
	char    *pwd;           /**< Current directory */
  char    *home;          /**< Home directory */
  char    *parameterFile; /**< Parameter file */
  char    *programName;   /**< Program name */
  char    *programPath;   /**< Program path */

  char    *outDir;        /**< Metric collection directory */
  char    *workDir;       /**< Work directory */
  char    *workCommonDir; /**< Common work directory */
  char    *archiveDir;    /**< Archive directory */
  char    *scriptDir;     /**< Script directory */
  char    *binDir;        /**< Binary directory */
  
  char    *sslDir;        /**< SSL manage directory */
  char    *cacertFile;    /**< CA cert file */
  char    *clcertFile;    /**< Client cert file */
  char    *clkeyFile;     /**< Bind file of client cert and key */
  char    *licenseFile;   /**< License file */
  
  int     soapRetry;      /**< WEB service retry count */

  char    *exitFlag;      /**< Exit flag file */
  char    *pidFile;       /**< PID file */
  char    *pidPath;       /**< PID absolute path */

	ght_hash_table_t *collectorPids; 	 /**< Collector pids */
  struct  GPFSSLConfig_t  *sslConfig; /**< SSL manager */
  struct  GPFLogConfig_t  *logConfig; /**< Log manager */
  struct  GPFSchedule_t   *schedule;  /**< Scheduler */
} GPFConfig;

/**
  * Collector
  */
typedef struct GPFTask_t
{
	GPFThreadId	 threadId;			   /**< Thread ID */
	GPFConfig    *config;			     /**< Agent config */
	GPFCollector *collector;		   /**< Collector */
	ght_hash_table_t *workerPids;  /**< Worker pids */
  int          mode;             /**< Mode(INIT, WAIT, RUN, ...) */
	time_t	     startTime;			   /**< Start time */
	time_t	     endTime;			     /**< End time */
	time_t		   timeout;			     /**< Job timeout */
	char         *dateDir;				 /**< Date directory */
	char         *timeDir;				 /**< Time directory */
	char         *odir;						 /**< Ouptput absolute path */
} GPFTask;

/**
  * Worker task job
  */
  
typedef struct GPFTaskJob_t
{
	GPFTask     *task;			/**< Task config */
	GPFJob      *job;			  /**< Job config */
	GPFThreadId	threadId;		/**< Worker thread id (0 if not use) */
	int         seq;			  /**< Job sequence */
	int         loopCount;	/**< Loop count */
	int         status;			/**< Process status */
	pid_t	      pid;			  /**< Worker process id */
	time_t	    startTime;	/**< Start time */
	time_t	    endTime;		/**< End time */
	time_t	    timeout;		/**< Timeout */
	int		      exitCode;		/**< Exit code */
} GPFTaskJob;

/**
  * Setup(admin)
  */

/**
  * Verify result
  */

typedef struct GPFSetupConfigResult_t
{
  char    *ofile;         /**< Verify result file */

  struct  GPFSetupConfigResult_t  *next;  /**< Next file */
} GPFSetupConfigResult;

/**
  * Domain
  */

typedef struct GPFSetupConfigDomain_t
{
  int     domainId;       /**< Domain ID */
  char    *domainName;    /**< Domain name */

  struct  GPFSetupConfigDomain_t  *next;  /**< Next domain */
} GPFSetupConfigDomain;

/**
  * License
  */

typedef struct GPFSetupConfigLicense_t
{
  char    *statName;      /**< Status name */
  int     amount;         /**< License amount */

  struct  GPFSetupConfigLicense_t *next;  /**< Next license */
} GPFSetupConfigLicense;

/**
  * Verify command
  */

typedef struct GPFSetupConfigVerifyCommand_t
{
  char    *metric;            /**< Metric name */
  int     metricId;           /**< Metric ID */
  int     priority;           /**< Priority */

  char    *cmd;               /**< Command */
  char    *verOpt;            /**< Version option */
  char    *testCommandOpt;    /**< Test command option */
  char    *filename;          /**< Output file */
  char    *priorityPath;      /**< Execute path of first priority */

  char    *timestamp;         /**< Execute timestamp */
  char    *verFile;           /**< Output file of command version */
  char    *outFile;           /**< Output file */
  char    *execPath;          /**< Execute command absolute path */
  char    *execOpt;           /**< Execute option */
  int     type;               /**< Command type 1:required, 2:option, 4:script */
	int     rc;                 /**< Exit code */
  char    *message;           /**< Message */
  char    *errMessage;        /**< Error message */

  struct  GPFSetupConfigVerifyCommand_t   *next;  /**< Next */
} GPFSetupConfigVerifyCommand;

/**
  * Setup data
  */

typedef struct GPFSetupConfig_t
{
  char    *userName;          /**< Username */
  char    *password;          /**< Password */
  char    *siteKey;           /**< Site key */
  int     siteId;             /**< Site ID */
  int     build;              /**< Build version */

  char    *osType;            /**< OS type */
  char    *osName;            /**< OS info */
  char    *statName;          /**< Metric category */

  int     domainId;           /**< Domain ID */
  char    *domainName;        /**< Domain name */

  char    *configZip;         /**< config file zip */

  char    *expired;			      /**< Host expired */
  int     status_ca;          /**< SSL CA cert status */
  int     status_ws;          /**< Host registration status */
  char    *message;           /**< Message from server */
  
  struct  GPFSetupConfigLicense_t *licenses;  /**< License config */
  struct  GPFSetupConfigResult_t  *results;   /**< Results */
  struct  GPFSetupConfigVerifyCommand_t   *verifyCommands;    /**< Verify commands */
  struct  GPFSetupConfigDomain_t  *domains;   /**< Domain config */
} GPFSetupConfig;

/**
  * Setup command
  */

typedef struct GPFSetupOption_t
{
	int     mode;             /**< Run mode */
	char    *program;         /**< Program name */
  char    *cmd;             /**< Command name */
  char    *userName;        /**< Username */
  char    *password;        /**< Password */
  char    *siteKey;         /**< Sitekey */
  char    *adminWebService; /**< Admin web service */ 
  char    *statName;        /**< Metric stat */
  char    *domainName;      /**< Domain name */
	char    *home;				    /**< Home */
	char    *configPath;      /**< Config path */
	int     recoverFlag;		  /**< Recover flag */
} GPFSetupOption;

/**
  * Global variable
  */

#ifdef GPF_MAIN_MODULE
GPFConfig         *GCON;
#else
extern GPFConfig  *GCON;
#endif


/**
  * Constructor 
  */

GPFJob       *gpfCreateJob();
GPFCollector *gpfCreateCollector(char *statName);
GPFSchedule  *gpfCreateSchedule();
GPFSSLConfig *gpfCreateSSLConfig();
GPFLogConfig *gpfCreateLogConfig(char *logDir, char *module);
GPFConfig    *gpfCreateConfig(char *host, char *home, char *programName, char *programPath, 
	char *binDir, char *configFile);
GPFTask      *gpfCreateTask(GPFConfig *config, GPFCollector *collector);
GPFTaskJob   *gpfCreateTaskJob( GPFTask *task, GPFJob *job, int seq );

GPFSetupConfigResult        *gpfCreateSetupConfigResult();
GPFSetupConfigDomain        *gpfCreateSetupConfigDomain();
GPFSetupConfigLicense       *gpfCreateSetupConfigLicense();
GPFSetupConfigVerifyCommand *gpfCreateSetupConfigVerifyCommand();
GPFSetupConfig              *gpfCreateSetupConfig();
int gpfSetSetupConfig( GPFSetupConfig *setup, GPFSetupOption *options );
GPFSetupOption              *gpfCreateSetupOption();

 /**
   * Destructor
   */

void gpfFreeJob(GPFJob **_job);
void gpfFreeCollector(GPFCollector **_collector);
void gpfFreeSchedule(GPFSchedule **_schedule);
void gpfFreeSSLConfig(GPFSSLConfig **_ssl);
void gpfFreeLogConfig(GPFLogConfig **_log);
void gpfFreeConfig(GPFConfig **_config);
void gpfFreeTaskJob( GPFTaskJob **_taskJob );
void gpfFreeTask(GPFTask **_task);
void gpfFreeCollectorPids( ght_hash_table_t **_collectorPids );
void gpfFreeWorkerPids( ght_hash_table_t **_workerPids );

void gpfFreeSetupConfigResult(GPFSetupConfigResult **_result);
void gpfFreeSetupConfigDomain(GPFSetupConfigDomain **_domain);
void gpfFreeSetupConfigLicense(GPFSetupConfigLicense **_license);
void gpfFreeSetupConfigVerifyCommand(GPFSetupConfigVerifyCommand **_command);
void gpfFreeSetupConfig(GPFSetupConfig **_setup);
void gpfFreeSetupOption(GPFSetupOption **_options);

/* Debug log */

void gpfShowConfig(GPFConfig *config);
void gpfShowSchedule(GPFSchedule *schedule);
void gpfShowCollector(GPFCollector *collector);
void gpfShowJobs(GPFJob *job);
void gpfShowTaskJob(GPFTaskJob *taskJob);
void gpfShowTask(GPFTask *task);

void gpfShowSetupConfig(GPFSetupConfig *setup);
void gpfShowSetupConfigResult(GPFSetupConfigResult *result);
void gpfShowSetupConfigDomain(GPFSetupConfigDomain *domain);
void gpfShowSetupConfigLicense(GPFSetupConfigLicense *license);
void gpfShowSetupConfigVerifyCommand(GPFSetupConfigVerifyCommand *command);
void gpfShowSetupOption(GPFSetupOption *options);

/* Setter, Getter */
GPFCollector *gpfFindCollector(GPFSchedule *schedule, char *statName);
GPFCollector *gpfFindAndAddCollector(GPFSchedule *schedule, char *statName);
GPFJob *gpfAddJob(GPFCollector *collector, char *cmd);

GPFSetupConfigLicense *gpfAddLicense(GPFSetupConfig *setup, char *statName, int amount);
GPFSetupConfigLicense *gpfFindLicense(GPFSetupConfig *setup, char *statName);

GPFSetupConfigResult *gpfAddSetupConfigResult(GPFSetupConfig *setup, char *ofile);
GPFSetupConfigDomain *gpfAddSetupConfigDomain(GPFSetupConfig *setup, int domainId, char *domainName);
GPFSetupConfigVerifyCommand *gpfAddSetupConfigVerifyCommand(GPFSetupConfig *setup, char *metric, int metricId, int priority);


#endif /* GETPERF_GPFCONF_H */
