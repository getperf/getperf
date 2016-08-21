#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"

#include "unit_test.h"
#include "cunit_test.h"

/**
 * 標準的な構成(スケジューラ 1件、コレクター 2件、ジョブ 3件)の作成と削除
 */

void test_gpf_config_001(void)
{
	GPFJob *job1;
	GPFJob *job2;
	GPFJob *job3;
	GPFJob *job;
	GPFCollector *collector;
	GPFCollector *collector2;
	GPFSchedule *schedule;
	GPFConfig *config;
	
	/* コレクター2件とジョブ3件の作成 */
	job1 = gpfCreateJob();
	job2 = gpfCreateJob();
	job3 = gpfCreateJob();
	collector  = gpfCreateCollector("HW");
	collector2 = gpfCreateCollector("JVM");
	
	job1->cmd  = strdup("cmd1");
	job1->next = job2;
	job2->cmd  = strdup("cmd2");
	job2->next = job3;
	job3->cmd  = strdup("cmd3");
	collector->jobStart = job1;	
	collector->next = collector2;
	
	/* スケジューラの作成 */
	schedule = gpfCreateSchedule();
	schedule->collectorStart = collector;
	
	for (job = collector->jobStart;
		job != NULL;
		job = job->next)
	{
		printf("job : %s\n", job->cmd);
		CU_ASSERT(job->cmd != NULL);
	}
	
	/* エージェントの作成 */
	config = gpfCreateConfig("host", "home", "programName", "programPath", "bidDir", "configFile");
	config->schedule = schedule;
	gpfShowConfig(config);
	
	/* エージェントの削除 */
	gpfFreeConfig(&config);
	CU_ASSERT(config == NULL);
	
}

/**
 * コレクターとジョブの登録
 */

void test_gpf_config_002(void)
{
	GPFCollector *collector, *collector2, *collector3;
	GPFJob *job, *job2, *job3;

	GPFSchedule *schedule;
	
	/* コレクターを作成し、出力ディレクトリが正しくコピーされていること */
	schedule = gpfCreateSchedule();
	collector = gpfFindAndAddCollector(schedule, "HW");
	collector->odir = strdup("dir-HW");
	collector2 = gpfFindAndAddCollector(schedule, "JVM");
	collector2->odir = strdup("dir-JVM");
	collector3 = gpfFindAndAddCollector(schedule, "HW");
	CU_ASSERT(strcmp(collector3->odir, "dir-HW") == 0);
	collector3 = gpfFindAndAddCollector(schedule, "JVM");
	CU_ASSERT(strcmp(collector3->odir, "dir-JVM") == 0);

	/* ジョブを作成し、登録した件数分のIDが発番されていること */
	job = gpfAddJob(collector, "vmstat 5 > _odir_/vmstat.txt");
	job2 = gpfAddJob(collector, "netstat -s > _odir_/netstat_s.txt");
	job3 = gpfAddJob(collector, "swap -s > _odir_/swap.txt");
	CU_ASSERT(job3->id == 3);

	gpfShowSchedule(schedule);  
	gpfFreeSchedule(&schedule);
}

/**
 * セットアップのライセンス、検証結果、ドメインの登録
 */
void test_gpf_config_003(void)
{
	GPFSetupConfig *setup;
	GPFSetupConfigLicense *license, *license2, *license3;
	GPFSetupConfigResult *result;
	GPFSetupConfigDomain *domain;
	GPFSetupConfigVerifyCommand *command;
	
	/* ライセンスの登録 */
	setup = gpfCreateSetupConfig();
	license = gpfAddLicense(setup, "HW", 10);
	CU_ASSERT(license->amount == 10);

	license2 = gpfAddLicense(setup, "JVM", 5);
	CU_ASSERT(license2->amount == 5);

	license3 = gpfAddLicense(setup, "HW", 100);
	CU_ASSERT(license->amount == 100);
	
	license = gpfFindLicense(setup, "JVM");
	CU_ASSERT(license->amount == 5);

	/* 検証結果の登録 */
	result = gpfAddSetupConfigResult(setup, "vmstat.txt");
	result = gpfAddSetupConfigResult(setup, "iostat.txt");
	result = gpfAddSetupConfigResult(setup, "netstat.txt");
	CU_ASSERT(strcmp(result->ofile, "netstat.txt") == 0);

	/* ドメインの登録 */
	domain = gpfAddSetupConfigDomain(setup, 1, "domain01");
	domain = gpfAddSetupConfigDomain(setup, 2, "  DB");
	domain = gpfAddSetupConfigDomain(setup, 3, "  AP");
	domain = gpfAddSetupConfigDomain(setup, 4, "  WEB");

	CU_ASSERT(strcmp(domain->domainName, "  WEB") == 0);

	command = gpfAddSetupConfigVerifyCommand(setup, "CPU", 1, 1);
	
	gpfShowSetupConfig(setup);
	gpfFreeSetupConfig(&setup);
}

/**
 * コレクターとジョブの登録
 */
void test_gpf_config_004(void)
{
	GPFJob *job;
	GPFJob *job1;
	GPFJob *job2;
	GPFJob *job3;
	GPFCollector *collector;

	/* コレクター、ジョブの再作成 */
	job1 = gpfCreateJob();
	job2 = gpfCreateJob();
	job3 = gpfCreateJob();
	collector = gpfCreateCollector("HW");
	
	job1->cmd  = strdup("cmdcmdcmd1");
	job1->next = job2;
	job2->cmd  = strdup("cmdcmd2");
	job2->next = job3;
	job3->cmd  = strdup("cmd3");
	collector->jobStart = job1;	

	printf("test14[2]\n");
	for (job = collector->jobStart;
		job != NULL;
		job = job->next)
	{
		printf("job : %s\n", job->cmd);  
		CU_ASSERT(job->cmd != NULL);
	}
	gpfFreeCollector(&collector);
	CU_ASSERT(collector == NULL);
}

void test_gpf_config_005(void)
{
	GPFJob *job1;
	GPFJob *job2;
	GPFJob *job3;
	GPFJob *job;
	GPFTask *task;
	GPFTaskJob *task_job;
	GPFCollector *collector;
	GPFSchedule *schedule;
	GPFConfig *config;
	time_t ajustTime;
	
	/* コレクター2件とジョブ3件の作成 */
	job1 = gpfCreateJob();
	job2 = gpfCreateJob();
	job3 = gpfCreateJob();
	collector  = gpfCreateCollector("HW");
	
	job1->cmd  = strdup("cmd1");
	job1->next = job2;
	job2->cmd  = strdup("cmd2");
	job2->next = job3;
	job3->cmd  = strdup("cmd3");
	collector->jobStart = job1;	
	
	/* スケジューラの作成 */
	schedule = gpfCreateSchedule();
	schedule->collectorStart = collector;
	
	for (job = collector->jobStart;
		job != NULL;
		job = job->next)
	{
		printf("job : %s\n", job->cmd);
		CU_ASSERT(job->cmd != NULL);
	}
	
	/* エージェントの作成 */
	config = gpfCreateConfig("host", "home", "programName", "programPath", "bidDir", "configFile");
	config->schedule = schedule;
	ajustTime = 0;
	gpfGetTimeString( ajustTime, collector->dateDir, GPF_DATE_FORMAT_YYYYMMDD );
	gpfGetTimeString( ajustTime, collector->timeDir, GPF_DATE_FORMAT_HHMISS );
	collector->odir    = strdup("/tmp");
	task = gpfCreateTask(config, collector);
	task_job = gpfCreateTaskJob(task, job1, 1);
	
	gpfFreeTaskJob( &task_job );
	gpfFreeTask( &task );
	
	/* エージェントの削除 */
	gpfFreeConfig(&config);
	CU_ASSERT(config == NULL);
}

void test_gpf_config_006(void)
{
}

void test_gpf_config_007(void)
{
}

void test_gpf_config_008(void)
{
}

void test_gpf_config_009(void)
{
}

void test_gpf_config_010(void)
{
}

void test_gpf_config_011(void)
{
}

void test_gpf_config_012(void)
{
}

void test_gpf_config_013(void)
{
}

void test_gpf_config_014(void)
{
}

void test_gpf_config_015(void)
{
}

void test_gpf_config_016(void)
{
}

void test_gpf_config_017(void)
{
}

void test_gpf_config_018(void)
{
}

void test_gpf_config_019(void)
{
}

void test_gpf_config_020(void)
{
}

