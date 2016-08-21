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

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_service.h"
#include "gpf_agent.h"

#define EVENTLOG_REG_PATH TEXT("SYSTEM\\CurrentControlSet\\Services\\EventLog\\")

static	SERVICE_STATUS		serviceStatus;
static	SERVICE_STATUS_HANDLE	serviceHandle;

int	application_status = GPF_APP_RUNNING;

static void	parent_signal_handler(int sig)
{
	switch (sig)
	{
		case SIGINT:
		case SIGTERM:
			gpfInfo( "Got signal. Exiting ..." );
//			zbx_on_exit();
			break;
	}
}

static VOID WINAPI ServiceCtrlHandler(DWORD ctrlCode)
{
	serviceStatus.dwServiceType		= SERVICE_WIN32_OWN_PROCESS;
	serviceStatus.dwCurrentState		= SERVICE_RUNNING;
	serviceStatus.dwControlsAccepted	= SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN;
	serviceStatus.dwWin32ExitCode		= 0;
	serviceStatus.dwServiceSpecificExitCode	= 0;
	serviceStatus.dwCheckPoint		= 0;
	serviceStatus.dwWaitHint		= 0;

	switch(ctrlCode)
	{
		case SERVICE_CONTROL_STOP:
		case SERVICE_CONTROL_SHUTDOWN:
			gpfNotice( "Getperf %s (build %d) Agent shutdown requested", GPF_VERSION, GPF_BUILD );

			serviceStatus.dwCurrentState	= SERVICE_STOP_PENDING;
			serviceStatus.dwWaitHint	= 4000;
			SetServiceStatus(serviceHandle, &serviceStatus);

			/* notify other threads and allow them to terminate */
			gpfRunExit();
			gpfNotice("Getperf Windows Service stopping");
			sleep(1);

			serviceStatus.dwCurrentState	= SERVICE_STOPPED;
			serviceStatus.dwWaitHint	= 0;
			serviceStatus.dwCheckPoint	= 0;
			serviceStatus.dwWin32ExitCode	= 0;

			break;
		default:
			break;
	}

	SetServiceStatus(serviceHandle, &serviceStatus);
	gpfNotice("Getperf Windows Service stopped");
}

static VOID WINAPI ServiceEntry(DWORD argc, LPTSTR *argv)
{
	LPTSTR	wservice_name;
	wservice_name = strdup(APPLICATION_NAME);
	serviceHandle = RegisterServiceCtrlHandler(wservice_name, ServiceCtrlHandler);
	gpfFree(wservice_name);

	/* start service initialization */
	serviceStatus.dwServiceType		= SERVICE_WIN32_OWN_PROCESS;
	serviceStatus.dwCurrentState		= SERVICE_START_PENDING;
	serviceStatus.dwControlsAccepted	= SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN;
	serviceStatus.dwWin32ExitCode		= 0;
	serviceStatus.dwServiceSpecificExitCode	= 0;
	serviceStatus.dwCheckPoint		= 0;
	serviceStatus.dwWaitHint		= 2000;

	SetServiceStatus(serviceHandle, &serviceStatus);

	/* service is running */
	serviceStatus.dwCurrentState	= SERVICE_RUNNING;
	serviceStatus.dwWaitHint	= 0;
	SetServiceStatus(serviceHandle, &serviceStatus);

	/* メイン処理実行 */
	gpfServiceMain();
}

void	service_start()
{
	int				ret;
	static SERVICE_TABLE_ENTRY	serviceTable[2];

	serviceTable[0].lpServiceName = strdup(APPLICATION_NAME);
	serviceTable[0].lpServiceProc = (LPSERVICE_MAIN_FUNCTION)ServiceEntry;
	serviceTable[1].lpServiceName = NULL;
	serviceTable[1].lpServiceProc = NULL;

	ret = StartServiceCtrlDispatcher(serviceTable);
	gpfFree(serviceTable[0].lpServiceName);

	if (ret == 0)
	{
		if ( GetLastError() == ERROR_FAILED_SERVICE_CONTROLLER_CONNECT)
		{
			gpfError("\n\n\t!!!ATTENTION!!! Getperf Agent started as a console application. !!!ATTENTION!!!\n");
		}
		else
		{
			gpfSystemError( "StartServiceCtrlDispatcher() failed" );
		}
	}
}

static int	svc_OpenSCManager(SC_HANDLE *mgr)
{
	if ((*mgr = OpenSCManager(NULL, NULL, GENERIC_WRITE)) != NULL)
		return 1;

	gpfSystemError( "cannot connect to Service Manager" );

	return 0;
}

static int	svc_OpenService(SC_HANDLE mgr, SC_HANDLE *service, DWORD desired_access)
{
	LPTSTR	wservice_name;
	int	ret = 1;

	wservice_name = strdup(APPLICATION_NAME);

	if ((*service = OpenService(mgr, wservice_name, desired_access)) == NULL)
	{
		gpfSystemError( "cannot open service [%s]", APPLICATION_NAME );
		ret = 0;
	}

	gpfFree(wservice_name);

	return ret;
}

static int	svc_install_event_source(const char *path)
{
	HKEY	hKey;
	DWORD	dwTypes = EVENTLOG_ERROR_TYPE | EVENTLOG_WARNING_TYPE | EVENTLOG_INFORMATION_TYPE;
	TCHAR	execName[MAX_PATH];
	TCHAR	regkey[256], *wevent_source;

	wevent_source = strdup(APPLICATION_NAME);
	gpfSnprintf(regkey, sizeof(regkey)/sizeof(TCHAR), EVENTLOG_REG_PATH TEXT("System\\%s"), wevent_source);
	gpfFree(wevent_source);

	if (ERROR_SUCCESS != RegCreateKeyEx(HKEY_LOCAL_MACHINE, regkey, 0, NULL, REG_OPTION_NON_VOLATILE,
			KEY_SET_VALUE, NULL, &hKey, NULL))
	{
		gpfSystemError( "unable to create registry key" );
		return 0;
	}

	strncpy(execName, path, MAX_PATH);
	RegSetValueEx(hKey, TEXT("TypesSupported"), 0, REG_DWORD, (BYTE *)&dwTypes, sizeof(DWORD));
	RegSetValueEx(hKey, TEXT("EventMessageFile"), 0, REG_EXPAND_SZ, (BYTE *)execName,
			(DWORD)( strlen(execName) + 1) * sizeof(TCHAR));
	RegCloseKey(hKey);

	gpfInfo( "event source [%s] installed successfully", APPLICATION_NAME );

	return 1;
}

int	gpfCreateService( const char *cmdLine )
{
#define MAX_CMD_LEN	MAX_PATH * 2

	SC_HANDLE		mgr, service;
	SERVICE_DESCRIPTION	sd;
	LPTSTR			wservice_name;
	DWORD			code;
	int			ret = 0;

	if (svc_OpenSCManager(&mgr) == 0)
		return ret;

	wservice_name = strdup(APPLICATION_NAME);

	if ((service = CreateService(mgr, wservice_name, wservice_name, GENERIC_READ, SERVICE_WIN32_OWN_PROCESS,
			SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, cmdLine, NULL, NULL, NULL, NULL, NULL)) == NULL)
	{
		if (ERROR_SERVICE_EXISTS == (code = GetLastError()))
			gpfError("service [%s] already exists", APPLICATION_NAME);
		else
			gpfSystemError("cannot create service [%s]", APPLICATION_NAME);
	}
	else
	{
		gpfInfo("service [%s] installed successfully", APPLICATION_NAME);
		CloseServiceHandle(service);
		ret = 1;

		/* update the service description */
		if (svc_OpenService(mgr, &service, SERVICE_CHANGE_CONFIG) == 1)
		{
			sd.lpDescription = TEXT("Provides system monitoring");
			if (ChangeServiceConfig2(service, SERVICE_CONFIG_DESCRIPTION, &sd) == 0)
				gpfSystemError("service description update failed");
			CloseServiceHandle(service);
		}
		gpfWriteWorkFile( GCON, "_install_flg", "" );
	}

	gpfFree(wservice_name);

	CloseServiceHandle(mgr);

	if (ret == 1)
		ret = svc_install_event_source( cmdLine );

	return ret;
}

static int	svc_RemoveEventSource()
{
	TCHAR	regkey[256];
	LPTSTR	wevent_source;
	int	ret = 0;

	wevent_source = strdup(APPLICATION_NAME);
	gpfSnprintf(regkey, sizeof(regkey)/sizeof(TCHAR), EVENTLOG_REG_PATH TEXT("System\\%s"), wevent_source);
	gpfFree(wevent_source);

	if (RegDeleteKey(HKEY_LOCAL_MACHINE, regkey) == ERROR_SUCCESS)
	{
		gpfInfo("event source [%s] uninstalled successfully", APPLICATION_NAME);
		ret = 1;
	}
	else
	{
		gpfSystemError("unable to uninstall event source [%s]", APPLICATION_NAME);
	}

	return 1;
}

int	gpfRemoveService()
{
	SC_HANDLE	mgr, service;
	int		ret = 0;

	if (svc_OpenSCManager(&mgr) == 0)
		return ret;

	if (svc_OpenService(mgr, &service, DELETE) == 1)
	{
		if (DeleteService(service) != 0)
		{
			gpfInfo("service [%s] uninstalled successfully", APPLICATION_NAME);
			gpfRemoveWorkFile( GCON, "_install_flg" );
			ret = 1;
		}
		else
		{
			gpfSystemError("cannot remove service [%s]", APPLICATION_NAME);

			/* 削除対象としてマークされた場合はOSを再起動する必要があります */
			gpfMessage( GPF_MSG059E, GPF_MSG059 );
		}

		CloseServiceHandle(service);
	}

	CloseServiceHandle(mgr);

	if (ret == 1)
		ret = svc_RemoveEventSource();

	return ret;
}

int	gpfStartService()
{
	SC_HANDLE	mgr, service;
	int		ret = 0;

	if (svc_OpenSCManager(&mgr) == 0)
		return ret;

	if (svc_OpenService(mgr, &service, SERVICE_START) == 1)
	{
		if (StartService(service, 0, NULL) != 0)
		{
			gpfInfo("service [%s] started successfully", APPLICATION_NAME);

			ret = 1;
		}
		else
		{
			gpfSystemError("cannot start service [%s]", APPLICATION_NAME);
		}

		CloseServiceHandle(service);
	}

	CloseServiceHandle(mgr);

	return ret;
}

int	gpfStopService()
{
	SC_HANDLE	mgr, service;
	SERVICE_STATUS	status;
	int		ret = 0;

	if (svc_OpenSCManager(&mgr) == 0)
		return ret;

	if (svc_OpenService(mgr, &service, SERVICE_STOP) == 1)
	{
		if (ControlService(service, SERVICE_CONTROL_STOP, &status) != 0)
		{
			gpfNotice( "service [%s] stopped successfully", APPLICATION_NAME);
			ret = 1;
		}
		else
		{
			gpfSystemError("cannot stop service [%s]", APPLICATION_NAME);
		}

		CloseServiceHandle(service);
	}

	CloseServiceHandle(mgr);

	return ret;
}

void	set_parent_signal_handler()
{
	signal(SIGINT, parent_signal_handler);
	signal(SIGTERM, parent_signal_handler);
}
