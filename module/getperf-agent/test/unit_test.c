#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_getopt.h"

#include "unit_test.h"
#include "unit_test_case.h"
#include "cunit_test.h"

char *progname = "unit_test";
char title_message[] = "GETPERF Test (unit)";
char usage_message[] = "-s <suite> -t <test>";
char *help_message[] = {
	"Options:",
	"  -h --help            give this help",
	"  -s [--suite] <suite> suite specified ",
	"  -t [--test]  <test>  test specified ",
	0 /* end of text */
};

char host_name[MAX_COMPUTERNAME_LENGTH];
char  *execpath  = NULL;
char  *home      = NULL;

/*
extern CU_TestInfo test_info_gpf_config[];
extern CU_TestInfo test_info_gpf_param[];
extern CU_TestInfo test_info_gpf_log[];
extern CU_TestInfo test_info_gpf_common[];
extern CU_TestInfo test_info_gpf_process[];
extern CU_TestInfo test_info_gpf_soap_common[];
extern CU_TestInfo test_info_gpf_soap_admin[];
extern CU_TestInfo test_info_gpf_soap_agent[];
extern CU_TestInfo test_info_gpf_admin[];
extern CU_TestInfo test_info_gpf_agent[];

extern CU_SuiteInfo suites_array_base[];
*/
CU_SuiteInfo suites_array_base[12];
void set_test_suite()
{
	suites_array_base[0].pName  = strdup("gpf_config");
	suites_array_base[1].pName  = strdup("gpf_param");
	suites_array_base[2].pName  = strdup("gpf_log");
	suites_array_base[3].pName  = strdup("gpf_common");
	suites_array_base[4].pName  = strdup("gpf_process");
	suites_array_base[5].pName  = strdup("gpf_soap_common");
	suites_array_base[6].pName  = strdup("gpf_soap_admin");
	suites_array_base[7].pName  = strdup("gpf_soap_agent");
	suites_array_base[8].pName  = strdup("gpf_admin");
	suites_array_base[9].pName  = strdup("gpf_agent");
	suites_array_base[10].pName = strdup("gpf_json");
	suites_array_base[11].pName = NULL;

	suites_array_base[0].pTests  = test_info_gpf_config;
	suites_array_base[1].pTests  = test_info_gpf_param;
	suites_array_base[2].pTests  = test_info_gpf_log;
	suites_array_base[3].pTests  = test_info_gpf_common;
	suites_array_base[4].pTests  = test_info_gpf_process;
	suites_array_base[5].pTests  = test_info_gpf_soap_common;
	suites_array_base[6].pTests  = test_info_gpf_soap_admin;
	suites_array_base[7].pTests  = test_info_gpf_soap_agent;
	suites_array_base[8].pTests  = test_info_gpf_admin;
	suites_array_base[9].pTests  = test_info_gpf_agent;
	suites_array_base[10].pTests = test_info_gpf_json;
	suites_array_base[11].pTests = NULL;
}

int main(int argc, char **argv)
{
	int          option;

	char         *suite_metric = NULL;
	char         *test_metric  = NULL;

	CU_pSuite     pSuite       = NULL;
	CU_TestInfo   *pTests      = NULL;
	int i;
	int j;

	set_test_suite();
	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{"help",	gpf_no_argument,       0, 'h' },
			{"suite",	gpf_required_argument, 0, 's' },
			{"test",	gpf_required_argument, 0, 't' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "hs:t:", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 'h':
			printf("Usage : %s %s\n", progname, usage_message);
			exit(-1);
			break;

		case 't':
			test_metric = strdup( gpf_optarg );
			break;

		case 's':
			suite_metric = strdup( gpf_optarg );
			break;

		case '?':
			break;

		default:
			printf("Usage : %s %s\n", progname, usage_message);
			exit (1);
		}
	}
	
	if (suite_metric != NULL) 
		printf("SUITE : %s\n", suite_metric);
	if (test_metric != NULL) 
		printf("TEST  : %s\n", test_metric);
	CU_initialize_registry();

	printf("test\n");
	
	if (suite_metric != NULL) 
	{
		i = 0;
		while (suites_array_base[i].pName != NULL)
		{
			if (strcmp(suites_array_base[i].pName, suite_metric) == 0)
			{
				break;
			}
			i++;
		}

		if (suites_array_base[i].pName != NULL)
		{
			printf("Add suite : %s\n", suites_array_base[i].pName);

			pSuite = CU_add_suite(suites_array_base[i].pName, 
				suites_array_base[i].pInitFunc,
				suites_array_base[i].pCleanupFunc);
		}
		if (pSuite != NULL)
		{
			char *test_id = NULL; 
			if (test_metric != NULL)
			{
				test_id = gpfDsprintf( test_id, "Test_%s", test_metric);
				printf("TestId : %s\n", test_id);
			}
			pTests = suites_array_base[i].pTests;
			j = 0;
			printf("%d %d %s\n", i, j, suites_array_base[i].pName);
			while (pTests[j].pName != NULL)
			{
				if (test_metric == NULL ||
					(test_id != NULL && strcmp(pTests[j].pName, test_id) == 0))
				{
					printf("Add test name : %s\n", pTests[j].pName);
					CU_add_test(pSuite, pTests[j].pName, pTests[j].pTestFunc);
				}
				j++;
			}
			gpfFree( test_id );
		}
	} 
	else 
	{
		i = 0;
		while (suites_array_base[i].pName != NULL)
		{
			printf("Add suite : %s\n", suites_array_base[i].pName);
			pSuite = CU_add_suite(suites_array_base[i].pName, 
				suites_array_base[i].pInitFunc,
				suites_array_base[i].pCleanupFunc);

			pTests = suites_array_base[i].pTests;
			i++;

			j = 0;
			while (pTests[j].pName != NULL)
			{
				printf("Add test name : %s\n", pTests[j].pName);
				CU_add_test(pSuite, pTests[j].pName, pTests[j].pTestFunc);
				j++;
			}
		}
	}
	argv[0] = "test";
	CU_basic_set_mode(CU_BRM_NORMAL);
	CU_basic_run_tests();
	CU_cleanup_registry();

	fflush(stdout);
	gpfFree( test_metric );
	gpfFree( suite_metric );
}

