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


** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "ght_hash_table.h"

/* コンストラクター */

/* ワーカー(ジョブ)データ構造コンストラクター */

GPFJob       *gpfCreateJob()
{
	GPFJob *job = NULL;
	job = gpfMalloc(job, sizeof(GPFJob));

	job->id     = 0;		/* 主キー(シーケンス) */
	job->pid    = 0;		/* ワーカのプロセスID */
	job->status = 0;		/* プロセスステータス */
	job->cmd    = NULL;	/* 実行コマンド */
	job->ofile  = NULL;	/* 出力ファイル */
	job->cycle  = 0;	/* 実行周期(秒) */
	job->step   = 0;	/* 実行回数 */
	job->next   = NULL;	/* 次のジョブ */

	return job;
}

 /* コレクターデータ構造コンストラクター */

GPFCollector *gpfCreateCollector(char *statName)
{
	GPFCollector *collector = NULL;
	collector = gpfMalloc(collector, sizeof(GPFCollector));

	collector->id       = 0;					/* 主キー(シーケンス) */
	collector->statName = strdup(statName);	/* メトリック */
	collector->pid      = 0;					/* コレクターのプロセスID */
	collector->status   = 0;					/* プロセスステータス */

	collector->statEnable    = 0;				/* 実行可能フラグ */
	collector->build         = 0;				/* ビルド番号 */
	collector->statStdoutLog = 0;				/* 標準ログ出力フラグ */
	collector->statInterval  = 0;				/* 採取間隔(秒) */
	collector->statTimeout   = 0;				/* 採取タイムアウト(秒) */

    collector->nextTimestamp  = 0;				/* 次の開始時刻(UTC) */
    collector->startTimestamp = 0;				/* 開始時刻(UTC) */
    collector->endTimestamp   = 0;				/* 終了時刻(UTC) */
    
	collector->dateDir  = malloc( sizeof("YYYYMMDD") );	/* 日付ディレクトリ */
	collector->timeDir  = malloc( sizeof("HHMISS") );		/* 時刻ディレクトリ */
	collector->odir     = NULL;				/* 出力先ディレクトリ */
	collector->statMode = NULL;				/* 採取モード */

	collector->jobStart = NULL;				/* 最初のジョブ */
	collector->next     = NULL;				/* 次のコレクター */

	return collector;
}

/* スケジューラデータ構造コンストラクター */

GPFSchedule  *gpfCreateSchedule()
{
	GPFSchedule *schedule = NULL;
	schedule = gpfMalloc(schedule, sizeof(GPFSchedule));

    schedule->diskCapacity   = 0;		/* ディスク使用率閾値 */
    schedule->saveHour       = 0;		/* データ保存時間 */
	schedule->recoveryHour   = 0;		/* データ再送時間 */
	schedule->maxErrorLog    = 0;		/* エラーログの出力行数 */
    schedule->pid            = 0;		/* スケジューラのプロセスID */
	schedule->status         = 0;		/* プロセスステータス */
    schedule->logLevel       = 0;		/* ログレベル */
    schedule->debugConsole   = 0;		/* ログのコンソール出力フラグ */
    schedule->logSize        = 0;		/* ログサイズ */
    schedule->logRotation    = 0;		/* ログ世代数 */
    schedule->logLocalize    = 1;		/* 日本語メッセージフラグ */

    schedule->hanodeEnable   = 0;		/* HAノードチェックフラグ */
    schedule->hanodeCmd      = NULL;	/* HAノードチェックスクリプト */
    
    schedule->postEnable     = 0;		/* 後処理フラグ */
    schedule->postCmd        = NULL;	/* 後処理コマンド */
    
    schedule->remhostEnable  = 0;		/* 採取データ転送フラグ */
    schedule->urlCM          = NULL;	/* 構成管理用WEBサービス URL */
    schedule->urlPM          = NULL;	/* 性能管理用WEBサービス URL */
    schedule->soapTimeout    = 0;		/* WEBサービスタイムアウト */
    schedule->siteKey        = NULL;	/* サイトキー */
    
    schedule->proxyEnable    = 0;		/* HTTPプロキシー使用フラグ */
    schedule->proxyHost      = NULL;	/* プロキシーホスト */
    schedule->proxyPort      = 0;		/* プロキシーポート */

    schedule->_last_update   = 0;		/* パラメータファイル更新日付 */

    schedule->collectorStart = NULL;	/* 最初のコレクター */

	return schedule;
}

/* SSL管理データ構造コンストラクター */

GPFSSLConfig *gpfCreateSSLConfig()
{
	GPFSSLConfig *ssl = NULL;
	ssl = gpfMalloc(ssl, sizeof(GPFSSLConfig));

    ssl->hostname = NULL;	/* ホスト */
    ssl->expired  = NULL;	/* 有効期限(YYYYMMDD) */
    ssl->code     = NULL;	/* 認証コード */
	
	return ssl;
}

/* ログ管理データ構造コンストラクター */

GPFLogConfig *gpfCreateLogConfig(char *logDir, char *module)
{
	GPFLogConfig *log = NULL;
	log = gpfMalloc(log, sizeof(GPFLogConfig));

    log->logDir      = NULL;   /* ログファイルディレクトリ */
    log->logFile     = NULL;   /* ログファイル */
    log->logPath     = NULL;   /* ログパス */
    log->module      = NULL;   /* モジュール */
    log->logLevel    = GPF_NOTICE; /* ログレベル */
    log->iniFlag     = 0;       /* 初期化フラグ */
    log->showLog     = 1;       /* 画面出力フラグ */
    log->logSize     = 0;       /* ログサイズ */
    log->logRotation = 0;    /* ログローテーション */
    log->lockOk      = 0;       /* 排他許可フラグ */
	
	return log;
}

/* エージェントデータ構造体コンストラクター */

GPFConfig    *gpfCreateConfig(char *host, char *home, char *programName, char *programPath, char *binDir, char *configFile)
{
	GPFConfig *config = NULL;
	char *pidFile     = NULL;
	char *workDir     = NULL;
	char *pwd         = NULL;
	pid_t pid;
	
	/* ファイルパス初期化 */
	char *sslDir = gpfCatFile(home, "network", NULL);
	char *logDir = gpfCatFile(home, "_log", NULL);

	config  = gpfMalloc(config, sizeof(GPFConfig));
	pidFile = gpfDsprintf(pidFile, "_pid_%s", programName);
	pid     = getpid();
	workDir = gpfDsprintf(workDir, "_%d", pid);

	/* プロセス定義 */
    config->module         = 'S';			/* モジュール識別子(S, C, W) */
    config->elapseTime     = 0;			/* 経過時間(秒) */
    config->startTime      = time(NULL);	/* 起動時間(UTC) */
    config->mode           = GPF_PROCESS_INIT;	/* 実行状態(init, run, end, ...) */
    config->managedPid     = 0;			/* 管理用プロセスID(ワーカで使用) */
	config->localeFlag     = 1;			/* 地域別メッセージ出力フラグ */
	config->daemonFlag     = 0;			/* デーモン化フラグ */

	/* プログラム名定義 */
    config->host           = strdup(host);							/* ホスト名 */
	config->serviceName    = NULL;									/* HAサービス名 */
	config->pwd            = gpfMalloc( pwd, MAX_STRING_LEN );		/* カレントディレクトリ */
	config->home           = strdup(home);							/* ホームディレクトリ */
    config->parameterFile  = gpfCatFile(home, configFile, NULL);	/* パラメータファイル */
    config->programName    = strdup(programName);					/* プログラム名 */
    config->programPath    = strdup(programPath);					/* プログラムパス */

	/* ディレクトリ定義 */
    config->outDir         = gpfCatFile(home, "log", NULL);			/* 採取データディレクトリ */
	config->workDir        = gpfCatFile(home, "_wk", workDir, NULL);	/* ワークディレクトリ */
    config->workCommonDir  = gpfCatFile(home, "_wk", NULL);			/* 共有ワークディレクトリ */
    config->archiveDir     = gpfCatFile(home, "_bk", NULL);			/* アーカイブ保存ディレクトリ */
    config->scriptDir      = gpfCatFile(home, "script", NULL);		/* スクリプトディレクトリ */
	config->binDir         = strdup(binDir);						/* バイナリディレクトリ */
    
	/* SSL証明書定義 */
    config->sslDir         = strdup("network");
    config->cacertFile     = gpfCatFile(sslDir, "ca.crt", NULL);	    /* CAルート証明書 */
    config->clcertFile     = gpfCatFile(sslDir, "clcert.pem", NULL);	/* PM用CAルート証明書 */
    config->clkeyFile      = gpfCatFile(sslDir, "client.pem", NULL);
    config->licenseFile    = gpfCatFile(sslDir, "License.txt", NULL);	/* ライセンスファイル */
    
	/* WEBサービスリトライ回数 */
    config->soapRetry      = GPF_SOAP_RETRY;						

	/* 管理ファイル */
	if (!getcwd( config->pwd, MAX_STRING_LEN ))
	{
		gpfSystemError("getcwd failed");
		exit(-1);
	}

    config->exitFlag       = gpfCatFile(home, "_wk", "_exitFlag", NULL);	/* 終了フラグファイル */
    config->pidFile        = strdup(pidFile);								/* PIDファイル */
    config->pidPath        = gpfCatFile(home, "_wk", pidFile, NULL);		/* PIDファイル(絶対パス) */
	
	/* 構造体定義 */
	config->collectorPids  = ght_create( GPF_MAX_COLLECTORS );			/* 起動中のコレクターのPID */
    config->sslConfig      = NULL;										/* SSL構造体 */
    config->logConfig      = gpfCreateLogConfig(logDir, programName);	/* ログ構造体 */
    config->schedule       = NULL;										/* スケジュール構造体 */

	gpfFree(sslDir);
	gpfFree(logDir);
	gpfFree(pidFile);
	gpfFree(workDir);

	return config;
}

/* コレクター タスクデータ構造コンストラクター */

GPFTask      *gpfCreateTask(GPFConfig *config, GPFCollector *collector)
{
	time_t currentTime = 0;
	GPFTask *task = NULL;
	task = gpfMalloc(task, sizeof(GPFTask));

	/* 構造体定義 */
	currentTime = time( NULL );
	task->threadId   = 0;
	task->mode       = GPF_PROCESS_INIT;
	task->config     = config;
	task->collector  = collector;
	task->workerPids = ght_create( GPF_MAX_WORKERS );	/* PIDをキーとする */
	task->startTime  = time(NULL);
	task->endTime    = 0;
	task->timeout    = currentTime + collector->statTimeout;
	task->dateDir    = strdup( collector->dateDir );
	task->timeDir    = strdup( collector->timeDir );
	task->odir       = strdup( collector->odir );

	return task;
}

/* ワーカー タスクジョブデータ構造コンストラクター */

GPFTaskJob *gpfCreateTaskJob( GPFTask *task, GPFJob *job, int seq )
{
	GPFTaskJob *taskJob = NULL;
	taskJob = gpfMalloc(taskJob, sizeof(GPFTaskJob));

	/* 構造体定義 */
	taskJob->task      = task;
	taskJob->job       = job;
	taskJob->seq       = seq;
	taskJob->status    = GPF_PROCESS_INIT;
	taskJob->threadId  = 0;
	taskJob->loopCount = 0;
	taskJob->pid       = 0;
	taskJob->startTime = time(NULL);
	taskJob->endTime   = 0;
	taskJob->exitCode  = 0;
	taskJob->timeout   = 0;

	return taskJob;
}

/* setup(admin)用データ構造定義 */

/* 検証結果ファイルデータ構造コンストラクター */

GPFSetupConfigResult        *gpfCreateSetupConfigResult()
{
	GPFSetupConfigResult *result = NULL;
	result = gpfMalloc(result, sizeof(GPFSetupConfigResult));

    result->ofile = NULL;		/* 結果ファイル */

    result->next = NULL;		/* 次のファイル */

	return result;
}

/* ドメインデータ構造コンストラクター */

GPFSetupConfigDomain        *gpfCreateSetupConfigDomain()
{
	GPFSetupConfigDomain *domain = NULL;
	domain = gpfMalloc(domain, sizeof(GPFSetupConfigDomain));

    domain->domainId   = 0;       /* ドメインID */
    domain->domainName = NULL;    /* ドメイン名 */

    domain->next = NULL;  /* 次のドメイン */
	
	return domain;	
}

/* ライセンスデータ構造コンストラクター */

GPFSetupConfigLicense       *gpfCreateSetupConfigLicense()
{
	GPFSetupConfigLicense *license = NULL;
	license = gpfMalloc(license, sizeof(GPFSetupConfigLicense));

    license->statName = NULL;      /* 採取種別 */
    license->amount   = 0;         /* ライセンス数 */

    license->next = NULL;  /* 次のライセンス */

	return license;	
}

/* 検証コマンドデータ構造コンストラクター */

GPFSetupConfigVerifyCommand *gpfCreateSetupConfigVerifyCommand()
{
	GPFSetupConfigVerifyCommand *command = NULL;
	command = gpfMalloc(command, sizeof(GPFSetupConfigVerifyCommand));

    command->metric         = NULL;	/* 項目名 */
    command->metricId       = 0;		/* 項目ID */
    command->priority       = 0;		/* 優先度 */

    command->cmd            = NULL;	/* コマンド */
    command->verOpt         = NULL;	/* バージョン実行オプション */
    command->testCommandOpt = NULL;	/* コマンド実行オプション */
    command->filename       = NULL;	/* 出力ファイル */
    command->priorityPath   = NULL;	/* 優先する実行パス */

    command->timestamp      = NULL;	/* 実行日時 */
    command->verFile        = NULL;	/* バージョンコマンド実行結果 */
    command->outFile        = NULL;	/* コマンド出力結果 */
    command->execPath       = NULL;	/* 実行コマンド(絶対パス) */
    command->execOpt        = NULL;	/* 実行オプション */
    command->rc             = 0;		/* 終了コード */
    command->message        = NULL;	/* メッセージ */
    command->errMessage     = NULL;	/* エラーメッセージ */

    command->next           = NULL;	/* 次の検証コマンド */

	return command;	
}

/* セットアップデータ構造コンストラクター */

GPFSetupConfig              *gpfCreateSetupConfig()
{
	GPFSetupConfig *setup = NULL;
	setup = gpfMalloc(setup, sizeof(GPFSetupConfig));

	/* サイト定義 */
    setup->userName   = NULL;		/* ユーザ名 */
    setup->password   = NULL;		/* パスワード */
    setup->siteKey    = NULL;		/* サイトキー */
    setup->siteId     = 0;			/* サイトID */
    setup->build      = 0;			/* ビルド番号 */

	/* 採取種別定義 */
	setup->osType     = strdup(GPF_OSTYPE);	/* OSタイプ */
    setup->osName     = NULL;		/* OS情報 */
    setup->statName   = NULL;		/* 採取種別 */

	/* ドメイン定義 */
	setup->domainId   = 0;			/* ドメインID */
    setup->domainName = NULL;		/* ドメイン名 */
	setup->configZip  = NULL;       /* 構成ファイルアーカイブ */

	/* サーバステータス定義 */
    setup->expired    = NULL;		/* 有効期限 */
    setup->status_ca  = 0;			/* SSL証明書発行ステータス */
    setup->status_ws  = 0;			/* 構成ファイル発行ステータス */
    setup->message    = NULL;		/* サーバからのメッセージ */
    
	/* 構造体初期化 */
    setup->licenses       = NULL;	/* ライセンス */
    setup->results        = NULL;	/* 結果ファイル */
    setup->verifyCommands = NULL;	/* 検証コマンド */
    setup->domains        = NULL;	/* ドメイン */
	
	return setup;	
}

/* セットアップコマンド実行オプションデータ構造コンストラクター */

GPFSetupOption        *gpfCreateSetupOption()
{
	GPFSetupOption *options = NULL;
	options = gpfMalloc(options, sizeof(GPFSetupOption));

	options->mode            = GPF_CMD_NONE;
	options->program         = NULL;
	options->cmd             = NULL;
	options->userName        = NULL;   /**< ユーザ名 */
	options->password        = NULL;   /**< パスワード */
	options->adminWebService = NULL;   /**< パスワード */
	options->siteKey         = NULL;   /**< サイトキー */
	options->statName        = NULL;   /**< 採取種別 */
	options->domainName      = NULL;   /**< ドメイン名 */
	options->home            = NULL;   /**< ホーム */
	options->configPath      = NULL;   /**< 構成ファイルパス */
	options->recoverFlag     = 0;      /**< 設定ファイル再ダウンロード */

	return options;
}

/* セットアップコマンド実行オプションデータ構造セッター */

int gpfSetSetupConfig( GPFSetupConfig *setup, GPFSetupOption *options )
{
	/* サイト定義 */
	if ( options->userName )
		setup->userName   = strdup( options->userName );
	if ( options->password )
		setup->password   = strdup( options->password );
	if ( options->siteKey )
		setup->siteKey    = strdup( options->siteKey );
	
	/* 採取種別定義 */
	if ( options->statName )
	    setup->statName   = strdup( options->statName );
	
	/* ドメイン定義 */
	if ( options->domainName )
	    setup->domainName = strdup( options->domainName );
	
	return 1;	
}

/* デストラクター */

/* ワーカー(ジョブ)データ構造デストラクター */

void gpfFreeJob(GPFJob **_job)
{
	GPFJob *job_prev = NULL;
	GPFJob *job = _job[0];
	while (job != NULL || job_prev != NULL)
	{
		job_prev = job;
		if (job != NULL)
			job = job->next;

		gpfFree(job_prev->cmd);
		gpfFree(job_prev->ofile);
		gpfFree(job_prev);
	}
	*_job = NULL;
}

/* コレクターデータ構造デストラクター */

void gpfFreeCollector(GPFCollector **_collector)
{
	GPFCollector *collector_prev = NULL;
	GPFCollector *collector = _collector[0];

	while (collector != NULL || collector_prev != NULL)
	{
		collector_prev = collector;
		if (collector != NULL)
			collector = collector->next;

		gpfFree(collector_prev->statName);
		gpfFree(collector_prev->dateDir);
		gpfFree(collector_prev->timeDir);
		gpfFree(collector_prev->odir);
		gpfFree(collector_prev->statMode);

		gpfFreeJob(&(collector_prev->jobStart));
		gpfFree(collector_prev);
	}
	*_collector = NULL;
}

/* スケジューラデータ構造デストラクター */

void gpfFreeSchedule(GPFSchedule **_schedule)
{
	GPFSchedule *schedule = _schedule[0];

	if (schedule == NULL)
		return;
		
	gpfFree(schedule->hanodeCmd);
	gpfFree(schedule->postCmd);
	gpfFree(schedule->urlCM);
	gpfFree(schedule->urlPM);
	gpfFree(schedule->siteKey);
	gpfFree(schedule->proxyHost);

    gpfFreeCollector(&(schedule->collectorStart));
	gpfFree(schedule);

	*_schedule = NULL;
}

/* SSL管理データ構造デストラクター */

void gpfFreeSSLConfig(GPFSSLConfig **_ssl)
{
	GPFSSLConfig *ssl = _ssl[0];

	if (ssl == NULL)
		return;

	gpfFree(ssl->hostname);
    gpfFree(ssl->expired);
    gpfFree(ssl->code);
	gpfFree(ssl);

	*_ssl = NULL;
}

/* ログ管理データ構造デストラクター */

void gpfFreeLogConfig(GPFLogConfig **_log)
{
	GPFLogConfig *log = _log[0];
	if (log == NULL)
		return;

    gpfFree(log->logDir);
    gpfFree(log->logFile);
    gpfFree(log->logPath);
    gpfFree(log->module);
	gpfFree(log);

	*_log = NULL;
}

/* エージェントデータ構造デストラクター */

void gpfFreeConfig(GPFConfig **_config)
{
	GPFConfig *config = _config[0];

    gpfFree(config->host);
    gpfFree(config->serviceName);
    gpfFree(config->pwd);
    gpfFree(config->home);
    gpfFree(config->parameterFile);
    gpfFree(config->programName);
    gpfFree(config->programPath);
    gpfFree(config->outDir);
    gpfFree(config->workDir);
    gpfFree(config->workCommonDir);
    gpfFree(config->archiveDir);
    gpfFree(config->scriptDir);
    gpfFree(config->binDir);
    gpfFree(config->sslDir);
    gpfFree(config->cacertFile);
    gpfFree(config->clcertFile);
    gpfFree(config->clkeyFile);
    gpfFree(config->licenseFile);
    gpfFree(config->exitFlag);
    gpfFree(config->pidFile);
    gpfFree(config->pidPath);

    gpfFreeCollectorPids(&(config->collectorPids));
    gpfFreeSSLConfig(&(config->sslConfig));
    gpfFreeLogConfig(&(config->logConfig));
    gpfFreeSchedule(&(config->schedule));

	gpfFree(config);

	*_config = NULL;
}

/* コレクター タスクデータ構造デストラクター */

void gpfFreeTask( GPFTask **_task )
{
	GPFTask *task = _task[0];
	
	if (_task == NULL || task == NULL)
		return;

	gpfFree( task->dateDir );
    gpfFree( task->timeDir );
    gpfFree( task->odir );

	if ( task->workerPids )
		gpfFreeWorkerPids( &(task->workerPids) );

	gpfFree( task );

	*_task = NULL;
}

/* ワーカー タスクジョブデータ構造デストラクター */

void gpfFreeTaskJob( GPFTaskJob **_taskJob )
{
	GPFTaskJob *taskJob = _taskJob[0];
	
	if (_taskJob == NULL || taskJob == NULL)
		return;

	gpfFree( taskJob );

	*_taskJob = NULL;
}

/* 起動中のコレクター群データ構造デストラクター */

void gpfFreeCollectorPids( ght_hash_table_t **_collectorPids )
{
	GPFTask *task = NULL;
	const void *threadId;
	ght_iterator_t iterator;
	ght_hash_table_t *collectorPids = _collectorPids[0];
	
	if ( _collectorPids == NULL || collectorPids == NULL)
		return;
	
	for ( task = (GPFTask *) ght_first( collectorPids, &iterator, &threadId );
	      task ;
	      task = (GPFTask *) ght_next( collectorPids, &iterator, &threadId ) )
	{
//		ght_remove( collectorPids, sizeof(GPFThreadId), threadId );
		gpfFreeTask( &task );
	}
	ght_finalize( collectorPids );
}

/* 起動中のワーカー群データ構造デストラクター */

void gpfFreeWorkerPids( ght_hash_table_t **_workerPids )
{
	GPFTaskJob *taskJob = NULL;
	const void *threadId;
	ght_iterator_t iterator;
	ght_hash_table_t *workerPids = _workerPids[0];
	
	if ( _workerPids == NULL || workerPids == NULL)
		return;
	
	gpfDebug("BEGIN");
	for ( taskJob = (GPFTaskJob *) ght_first( workerPids, &iterator, &threadId );
	      taskJob ;
	      taskJob = (GPFTaskJob *) ght_next( workerPids, &iterator, &threadId ) )
	{
//		gpfDebug("[remove] thread=%u", *threadId);
//		taskJob = (GPFTaskJob *)ght_remove( workerPids, sizeof(GPFThreadId), threadId );
		gpfFreeTaskJob( &taskJob );
	}
	ght_finalize( workerPids );
}

/* setup(admin)用データ構造定義 */

/* 検証結果ファイルデータ構造デストラクター */

void gpfFreeSetupConfigResult(GPFSetupConfigResult **_result)
{
	GPFSetupConfigResult *result_prev = NULL;
	GPFSetupConfigResult *result = _result[0];
	
	while (result != NULL || result_prev != NULL)
	{
		result_prev = result;
		if (result != NULL)
			result = result->next;
		gpfFree(result_prev->ofile);
		gpfFree(result_prev);
	}
	*_result = NULL;
}

/* ドメインデータ構造デストラクター */

void gpfFreeSetupConfigDomain(GPFSetupConfigDomain **_domain)
{
	GPFSetupConfigDomain *domain_prev = NULL;
	GPFSetupConfigDomain *domain = _domain[0];
	
	while (domain != NULL || domain_prev != NULL)
	{
		domain_prev = domain;
		if (domain != NULL)
			domain = domain->next;

		gpfFree(domain_prev->domainName);
		gpfFree(domain_prev);
	}
	*_domain = NULL;
}

/* ライセンスデータ構造デストラクター */

void gpfFreeSetupConfigLicense(GPFSetupConfigLicense **_license)
{
	GPFSetupConfigLicense *license_prev = NULL;
	GPFSetupConfigLicense *license = _license[0];

	while (license != NULL || license_prev != NULL)
	{
		license_prev = license;
		if (license != NULL)
			license = license->next;

		gpfFree(license_prev->statName);
		gpfFree(license_prev);
	}

	*_license = NULL;
}

/* 検証コマンドデータ構造デストラクター */

void gpfFreeSetupConfigVerifyCommand(GPFSetupConfigVerifyCommand **_command)
{
	GPFSetupConfigVerifyCommand *command_prev = NULL;
	GPFSetupConfigVerifyCommand *command = _command[0];

	while (command != NULL || command_prev != NULL)
	{
		command_prev = command;
		if (command != NULL)
			command = command->next;

	    gpfFree(command_prev->metric);
	    gpfFree(command_prev->cmd);
	    gpfFree(command_prev->verOpt);
	    gpfFree(command_prev->testCommandOpt);
	    gpfFree(command_prev->filename);
	    gpfFree(command_prev->priorityPath);
	    gpfFree(command_prev->timestamp);
	    gpfFree(command_prev->verFile);
	    gpfFree(command_prev->outFile);
	    gpfFree(command_prev->execPath);
	    gpfFree(command_prev->execOpt);
	    gpfFree(command_prev->message);
	    gpfFree(command_prev->errMessage);
	    gpfFree(command_prev);
	}
	*_command = NULL;
}

/* セットアップデータ構造デストラクター */

void gpfFreeSetupConfig(GPFSetupConfig **_setup)
{
	GPFSetupConfig *setup = _setup[0];
	
	if (setup == NULL)
		return;

	gpfFree(setup->userName);
    gpfFree(setup->password);
    gpfFree(setup->siteKey);
    gpfFree(setup->osType);
    gpfFree(setup->osName);
    gpfFree(setup->expired);
    gpfFree(setup->statName);
    gpfFree(setup->domainName);
    gpfFree(setup->configZip);
    gpfFree(setup->message);
    
	gpfFreeSetupConfigLicense(&(setup->licenses));
	gpfFreeSetupConfigResult(&(setup->results));
	gpfFreeSetupConfigVerifyCommand(&(setup->verifyCommands));
	gpfFreeSetupConfigDomain(&(setup->domains));

    gpfFree(setup);

	*_setup = NULL;
}

/* セットアップコマンド実行オプションデータ構造デストラクター */

void gpfFreeSetupOption(GPFSetupOption **_options)
{
	GPFSetupOption *options = _options[0];
	
	if (options == NULL)
		return;

	gpfFree(options->program);
	gpfFree(options->cmd);
	gpfFree(options->userName);
	gpfFree(options->password);
	gpfFree(options->siteKey);
	gpfFree(options->adminWebService);
	gpfFree(options->statName);
	gpfFree(options->domainName);
	gpfFree(options->home);
	gpfFree(options->configPath);

    gpfFree(options);

	*_options = NULL;
}

/* デバック出力 */

/* エージェントデータ構造出力 */

void gpfShowConfig(GPFConfig *config)
{
	GPFSSLConfig *ssl = config->sslConfig;
	GPFLogConfig *log = config->logConfig;
	GPFSchedule *schedule = config->schedule;
	
	if ( ssl )
	{
		printf("ssl :\n");
		printf("  hostname : %s\n", (ssl->hostname)?ssl->hostname:"NULL");
		printf("  expired : %s\n", (ssl->expired)?ssl->expired:"NULL");
	}
	
	if ( log )
	{
		printf("log :\n");
		printf("  module : %s\n", (log->module)?log->module:"NULL");
		printf("  logFile : %s\n", (log->logFile)?log->logFile:"NULL");
		printf("  logPath : %s\n", (log->logPath)?log->logPath:"NULL");
		printf("  logSize : %d\n", log->logSize);
		printf("  logRotation : %d\n", log->logRotation);
	}
	
	gpfShowSchedule(schedule);
}

/* スケジューラデータ構造出力 */

void gpfShowSchedule(GPFSchedule *schedule)
{
	GPFCollector *collector;
	GPFJob *job;

	if (schedule == NULL)
	{
		gpfError("schedule not found");
		return;
	}
	
	printf("schedule :\n");
	printf("  pid : %d\n", schedule->pid);
	printf("  status : %d\n", schedule->status);
	printf("  sitekey : %s\n", (schedule->siteKey)?schedule->siteKey:"NULL");
	printf("  diskCapacity : %d\n", schedule->diskCapacity);

	printf("collector :\n");
	for (collector = schedule->collectorStart;
		collector != NULL;
		collector = collector->next)
	{
		gpfShowCollector(collector);
	}
}

/* コレクターデータ構造出力 */

void gpfShowCollector(GPFCollector *collector)
{
	GPFJob *job;

	if (collector == NULL)
	{
		gpfError("collector not found");
		return;
	}
	printf("  %d : %s\n", collector->id, (collector->statName)?collector->statName:"NULL");
	printf("    pid : %d\n", collector->pid);
	printf("    status : %d\n", collector->status);
	printf("    next : %lld\n", (long long)(collector->nextTimestamp));
	printf("    start : %lld\n", (long long)(collector->startTimestamp));
	printf("    timeout : %d\n", collector->statTimeout);
	printf("    odir : %s\n", (collector->odir)?collector->odir:"NULL");
	printf("    statMode : %s\n", (collector->statMode)?collector->statMode:"NULL");
	printf("  job :\n");

	for (job = collector->jobStart;
		job != NULL;
		job = job->next)
	{
		gpfShowJobs(job);
	}
}

/* ジョブデータ構造出力 */

void gpfShowJobs(GPFJob *job)
{
	if (job == NULL)
	{
		gpfError("job not found");
		return;
	}
	printf("    %d : %s\n", job->id, (job->cmd)?job->cmd:"NULL");
	printf("      out : %s\n", (job->ofile)?job->ofile:"NULL");
	printf("      pid : %d\n", job->pid);
	printf("      status : %d\n", job->status);
}

/* セットアップデータ構造出力 */

void gpfShowSetupConfig(GPFSetupConfig *setup)
{
	if (setup == NULL)
	{
		gpfError("setup not found");
		return;
	}
	printf("setupConfig :\n");
	printf("  userName : %s\n", (setup->userName)?setup->userName:"NULL");
	printf("  siteKey : %s\n", (setup->siteKey)?setup->siteKey:"NULL");
	printf("  statName : %s\n", (setup->statName)?setup->statName:"NULL");
	printf("  osType : %s\n", (setup->osType)?setup->osType:"NULL");
	printf("  expired : %s\n", (setup->expired)?setup->expired:"NULL");
	printf("  message : %s\n", (setup->message)?setup->message:"NULL");
	printf("  domainId : %d\n", (setup->domainId) );
	printf("  domainName : %s\n", (setup->domainName)?setup->domainName:"NULL");
	printf("  configZip : %s\n", (setup->configZip)?setup->configZip:"NULL");
	printf("  status_ca : %d\n", (setup->status_ca) );
	printf("  status_ws : %d\n", (setup->status_ws) );
	printf("setupConfig :\n");
	
	gpfShowSetupConfigResult(setup->results);
	gpfShowSetupConfigDomain(setup->domains);
	gpfShowSetupConfigLicense(setup->licenses);
	gpfShowSetupConfigVerifyCommand(setup->verifyCommands);	
}

/* コレクタータスク データ構造出力 */

void gpfShowTask(GPFTask *task)
{
	if (task == NULL)
	{
		gpfError("tasknot found");
		return;
	}
	printf("task :\n");
	printf("  threadId : %ul\n", (unsigned int)task->threadId );
	printf("  timeout : %lld\n", (long long)task->timeout );
	printf("  odir : %s\n", (task->odir)?task->odir:"NULL" );
}

/* ワーカータスクジョブ データ構造出力 */

void gpfShowTaskJob(GPFTaskJob *taskJob)
{
	if (taskJob == NULL)
	{
		gpfError("task job not found");
		return;
	}
	printf("taskJob :\n");
	printf("  threadId : %ul\n", (unsigned int)taskJob->threadId );
	printf("  pid : %d\n", taskJob->pid );
	printf("  exit : %d\n", taskJob->exitCode );
}

/* 検証結果ファイルデータ構造出力 */

void gpfShowSetupConfigResult(GPFSetupConfigResult *result)
{
	if (result == NULL)
	{
		gpfError("result not found");
		return;
	}
	printf("result :\n");
	while (result != NULL)
	{
		printf("  ofile : %s\n", (result->ofile)?result->ofile:"NULL");
		result = result->next;
	}
}

/* ドメインデータ構造出力 */

void gpfShowSetupConfigDomain(GPFSetupConfigDomain *domain)
{
	if (domain == NULL)
	{
		gpfError("domain not found");
		return;
	}
	printf("domain :\n");
	while (domain != NULL)
	{
		printf("  %d : %s\n", domain->domainId, (domain->domainName)?domain->domainName:"NULL");
		domain = domain->next;
	}
}

/* ライセンスデータ構造出力 */

void gpfShowSetupConfigLicense(GPFSetupConfigLicense *license)
{
	if (license == NULL)
	{
		gpfError("license not found");
		return;
	}
	printf("license :\n");
	while (license != NULL)
	{
		printf("  %s : %d\n", (license->statName)?license->statName:"NULL", license->amount);
		license = license->next;
	}
}

/* 検証コマンドデータ構造出力 */

void gpfShowSetupConfigVerifyCommand(GPFSetupConfigVerifyCommand *command)
{
	if (command == NULL)
	{
		gpfError("command not found");
		return;
	}
	printf("command :\n");
	while (command != NULL)
	{
		printf("  metric : %s,%d,%d\n", 
			(command->metric)?command->metric:"NULL", command->metricId, command->priority
		);
		printf("    filename : %s\n", (command->filename)?command->filename:"NULL");
		printf("    cmd : %s\n", (command->cmd)?command->cmd:"NULL");
		printf("    priority path : %s\n", (command->priorityPath)?command->priorityPath:"NULL");
		printf("    test cmd opt : %s\n", (command->testCommandOpt)?command->testCommandOpt:"NULL");
		printf("    veropt : %s\n", (command->verOpt)?command->verOpt:"NULL");
		printf("    verFile : %s\n", (command->verFile)?command->verFile:"NULL");
		printf("    type : %d\n", command->type );
		printf("\n");
		printf("    timestamp : %s\n", (command->timestamp)?command->timestamp:"NULL");
		printf("    verFile : %s\n", (command->verFile)?command->verFile:"NULL");
		printf("    outFile : %s\n", (command->outFile)?command->outFile:"NULL");
		printf("    execPath : %s\n", (command->execPath)?command->execPath:"NULL");
		printf("    execOpt : %s\n", (command->execOpt)?command->execOpt:"NULL");
		printf("    rc : %d\n", command->rc );
		printf("    message : %s\n", (command->message)?command->message:"NULL");
		printf("    errMessage : %s\n", (command->errMessage)?command->errMessage:"NULL");
		
		printf("\n");
		command = command->next;
	}
}

/* セットアップコマンド実行オプションデータ構造 */

void gpfShowSetupOption(GPFSetupOption *options)
{
	if (options == NULL)
	{
		gpfError("option not found");
		return;
	}
	
	printf("option :\n");
	printf("   mode : %d\n", options->mode );
	printf("   program : %s\n", options->program );
	printf("   cmd : %s\n", options->cmd );
	printf("   userName : %s\n", options->userName );
	printf("   password : %s\n", options->password );
	printf("   siteKey : %s\n", options->siteKey );
	printf("   adminWebService : %s\n", options->adminWebService );
	printf("   statName : %s\n", options->statName );
	printf("   domainName : %s\n", options->domainName );
	printf("   home : %s\n", options->home );
	printf("   configPath : %s\n", options->configPath );
	
}


/**
 * コレクターの検索
 * @param schedule スケジュール構造体
 * @param statName 採取種別
 * @return コレクター
 */
GPFCollector *gpfFindCollector(GPFSchedule *schedule, char *statName)
{
	int id;
	GPFCollector *collector = NULL;

	for (id =1, collector = schedule->collectorStart;
		collector != NULL;
		id++, collector = collector->next)
	{
		if (collector->statName != NULL)
		{
			if (strcmp(collector->statName, statName) == 0) 
			{
				return collector;
			}
		}
	}
	return NULL;
}

/**
 * コレクターの検索。ない場合は追加登録
 * @param schedule スケジュール構造体
 * @param statName 採取種別
 * @return コレクター
 */
GPFCollector *gpfFindAndAddCollector(GPFSchedule *schedule, char *statName)
{
	int id;
	GPFCollector *collector, *collectorPrev, *collectorNew;

	collectorPrev = NULL;
	for (id =1, collector = schedule->collectorStart;
		collector != NULL;
		id++, collector = collector->next)
	{
		if (collector->statName != NULL)
		{
			if (strcmp(collector->statName, statName) == 0) 
			{
				return collector;
			}
		}
		collectorPrev = collector;
	}

	collectorNew = gpfCreateCollector(statName);
	collectorNew->id = id;
	if (schedule->collectorStart == NULL)
		schedule->collectorStart = collectorNew;
	else 
		collectorPrev->next = collectorNew;
	
	return collectorNew;
}

/**
 * ジョブの追加
 * @param collector コレクター構造体
 * @return ジョブ
 */
GPFJob *gpfAddJob(GPFCollector *collector, char *cmd)
{
	int id;
	GPFJob *job, *jobPrev, *jobNew;

	jobPrev = NULL;
	for (id =1, job = collector->jobStart;
		job != NULL;
		id++, job = job->next)
	{
		if (id == 1000)
		{
			gpfError("max command limit exceed");
			return NULL;
		}
		jobPrev = job;
	}

	jobNew = gpfCreateJob();
	jobNew->id = id;
	jobNew->cmd = strdup(cmd);
	if (collector->jobStart == NULL)
		collector->jobStart = jobNew;
	else 
		jobPrev->next = jobNew;
	
	return jobNew;
}

/**
 * ライセンスの追加
 * @param setup セットアップ構造体
 * @param statName 採取種別
 * @param val 値
 * @return ライセンス
 */
GPFSetupConfigLicense *gpfAddLicense(GPFSetupConfig *setup, char *statName, int amount)
{
	int id;
	GPFSetupConfigLicense *license, *licensePrev, *licenseNew;

	gpfInfo( "add %s, %d", statName, amount );
	licensePrev = NULL;
	for (id =1, license = setup->licenses;
		license != NULL;
		id++, license = license->next)
	{
		if (id == 1000)
		{
			gpfError("max license limit exceed");
			return NULL;
		}
		if (strcmp(license->statName, statName) == 0)
		{
			license->amount = amount;
			return license;
		}
		licensePrev = license;
	}

	licenseNew = gpfCreateSetupConfigLicense();
	licenseNew->statName = strdup(statName);
	licenseNew->amount   = amount;

	if (setup->licenses == NULL)
		setup->licenses = licenseNew;
	else
		licensePrev->next = licenseNew;

	return licenseNew;
}

/**
 * ライセンスの検索
 * @param setup セットアップ構造体
 * @param statName 採取種別
 * @return ライセンス。存在しない場合はNULL
 */
GPFSetupConfigLicense *gpfFindLicense(GPFSetupConfig *setup, char *statName)
{
	int id;
	GPFSetupConfigLicense *license, *licensePrev, *licenseNew;

	licensePrev = NULL;
	for (id =1, license = setup->licenses;
		license != NULL;
		id++, license = license->next)
	{
		if (id == 1000)
		{
			gpfError("max license limit exceed");
			return NULL;
		}
		if (strcmp(license->statName, statName) == 0)
		{
			return license;
		}
		licensePrev = license;
	}
	return NULL;
}

/**
 * 検証結果ファイルの登録
 * @param setup セットアップ構造体
 * @param statName 採取種別
 * @return 検証結果ファイル
 */
 GPFSetupConfigResult *gpfAddSetupConfigResult(GPFSetupConfig *setup, char *ofile)
{
	GPFSetupConfigResult *result, *resultPrev, *resultNew;

	resultPrev = NULL;
	for (result = setup->results;
		result != NULL;
		result = result->next)
	{
		if (strcmp(result->ofile, ofile) == 0)
		{
			return result;
		}
		resultPrev = result;
	}

	resultNew = gpfCreateSetupConfigResult();
	resultNew->ofile = strdup(ofile);

	if (setup->results == NULL)
		setup->results = resultNew;
	else
		resultPrev->next = resultNew;

	return resultNew;
}

/**
 * ドメインの登録
 * @param setup セットアップ構造体
 * @param domainId ドメインID
 * @param domainName ドメイン名
 * @return ドメイン
 */
GPFSetupConfigDomain *gpfAddSetupConfigDomain(GPFSetupConfig *setup, int domainId, char *domainName)
{
	GPFSetupConfigDomain *domain, *domainPrev, *domainNew;

	domainPrev = NULL;
	for (domain = setup->domains;
		domain != NULL;
		domain = domain->next)
	{
		if (domain->domainId == domainId)
		{
			return domain;
		}
		domainPrev = domain;
	}

	domainNew = gpfCreateSetupConfigDomain();
	domainNew->domainId = domainId;
	domainNew->domainName = strdup(domainName);

	if (setup->domains == NULL)
		setup->domains = domainNew;
	else
		domainPrev->next = domainNew;

	return domainNew;
}

/**
 * 検証コマンドの登録
 * @param setup セットアップ構造体
 * @param metric 採取種別名
 * @param metricId 採取種別ID
 * @param priority 優先度
 * @return 検証コマンド
 */
GPFSetupConfigVerifyCommand *gpfAddSetupConfigVerifyCommand(GPFSetupConfig *setup, char *metric, int metricId, int priority)
{
	GPFSetupConfigVerifyCommand *command, *commandPrev, *commandNew;
	commandPrev = NULL;
	for (command = setup->verifyCommands;
		command != NULL;
		command = command->next)
	{
		if (strcmp(command->metric, metric) == 0 && command->metricId == metricId && command->priority == priority)
		{
			return command;
		}
		commandPrev = command;
	}

	commandNew = gpfCreateSetupConfigVerifyCommand();
	commandNew->metric = strdup(metric);
	commandNew->metricId = metricId;
	commandNew->priority = priority;

	if (setup->verifyCommands == NULL)
		setup->verifyCommands = commandNew;
	else
		commandPrev->next = commandNew;
	return commandNew;
}

