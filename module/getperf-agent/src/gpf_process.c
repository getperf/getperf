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

#define __POSIX_VISIBLE (1)
#include "gpf_common.h"
#include "gpf_config.h"
#include "gpf_log.h"
#include "gpf_process.h"

/*
#include <sys/signal.h>
*/

/**
 * 既存サービスの起動チェック。2プロセスが起動されている場合は1を返す
 * @param config エージェント構造体
 * @param pidFile プロセスIDファイル
 * @param pid プロセスID
 * @return 合否
 */
int gpfCheckServiceExist( GPFConfig *config, char *pidFile, pid_t *pid )
{
	if ( gpfReadWorkFileNumber( config, config->pidFile, pid ) ) 
	{
		if ( gpfCheckProcess( *pid, "getperf" ) ) 
		{
			return 1;
		}
	}
	
	return 0;
}

/**
 * プロセスの有無チェック
 * @param pid プロセスID
 * @param keyword 実行モジュールの検索キーワード。NULLの場合は検索しない
 * @return 合否
 *
 * Windowsシステムプロセスの取得のため、OpenProcess()でPIDを特定する方法から、
 * CreateToolhelp32Snapshot()を使ってプロセスを列挙してPIDを検索する方法に変更
 */

int gpfCheckProcess( pid_t pid, char *keyword )
{

#if defined(_WINDOWS)

	HANDLE hSnapshot;
	PROCESSENTRY32 *procent = NULL;
	int rc = 0;
	
	hSnapshot = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS,0 );
	if ( hSnapshot == (HANDLE)-1 )
		return 0;

	procent = gpfMalloc( procent, sizeof(PROCESSENTRY32) );
    memset(procent, 0, sizeof(PROCESSENTRY32));
	
    procent->dwSize = sizeof(PROCESSENTRY32);
	Process32First( hSnapshot,procent );

	do 
	{
		if ( keyword )
		{
			if ( strstr( procent->szExeFile, keyword ) == NULL )
				continue;
		}
		if ( pid == procent->th32ProcessID ) 
		{
			rc = 1;
			break;
		}
	} while ( Process32Next( hSnapshot, procent ) );
	CloseHandle( hSnapshot );
	
	gpfFree( procent );

	return rc;
//	HANDLE ph = NULL;
//	if ( (ph = OpenProcess( PROCESS_QUERY_INFORMATION, 0, pid )) == NULL)
//		return 0;
//		return gpfError("process [pid=%d] not exist", pid);
	
//	CloseHandle(ph);

#elif (defined(FREEBSD) || defined(__FreeBSD__))

	int r = kill (pid, 0);
	if (r == 0)
	{
		return (1);
	}
	if (EPERM == errno)
	{
		return (1);
	}

	return (0);

#else

	struct stat	sb;
	char path[50];

	gpfSnprintf(path, sizeof(path), "/proc/%d", pid);
	if ( stat(path, &sb) == -1 ) 
		return 0;
//		return gpfError("process [pid=%d] not exist", pid);

	return 1;

#endif

}

/**
 * スレッドIDの取得
 * @return スレッドID
 */
GPFThreadId gpfGetThreadId( )
{
#if defined(_WINDOWS)

	return (GPFThreadId) GetCurrentThreadId();

#else /* not _WINDOWS */

	return (GPFThreadId) pthread_self();

#endif /* _WINDOWS */
}

/**
 * プロセスIDの取得
 * @return プロセスID
 */
pid_t gpfGetProcessId( )
{
#if defined(_WINDOWS)

	return (pid_t) _getpid();

#else /* not _WINDOWS */

	return (pid_t) getpid();

#endif /* _WINDOWS */
}


/**
 * プロセスの強制終了
 * @param pid プロセスID
 * @return 合否
 */
#if defined(_WINDOWS)
BOOL CALLBACK TerminateAppEnum( HWND hwnd, LPARAM lParam )
{
	DWORD dwID ;

	GetWindowThreadProcessId(hwnd, &dwID) ;

	if ( dwID == (DWORD)lParam )
	{
		PostMessage(hwnd, WM_CLOSE, 0, 0) ;
	}
	return TRUE ;
}

void UpdatePrivilege(void)
{
    HANDLE hToken;
    TOKEN_PRIVILEGES tp;
    LUID luid;

    if(OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,&hToken))
    {
       LookupPrivilegeValue(NULL,SE_DEBUG_NAME, &luid);

       tp.PrivilegeCount = 1;
       tp.Privileges[0].Luid = luid;
       tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED; 

       AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(TOKEN_PRIVILEGES), NULL, NULL);
    }
}
#endif

int gpfKill( pid_t pid )
{

#if defined(_WINDOWS)

	int rc = 1;
	HANDLE ph = NULL;
  	TCHAR filename[MAX_PATH];
  	int dwTimeout = 1000;

	if ( pid <= 1 )
		return gpfError("wrong pid %d", pid);

	// if ( (ph = OpenProcess( PROCESS_TERMINATE, 0, pid )) == NULL)
	if ( (ph = OpenProcess( PROCESS_ALL_ACCESS, TRUE, pid )) == NULL)
		return gpfError( "process [pid=%d] not exist", pid );

    // if (GetModuleFileNameEx(ph, NULL, filename, MAX_PATH) == 0) {
    //   printf("Failed to get module filename.\n");
    //   return rc;
    // } else {
    //   printf("Module filename is: %s.\n", filename);
    // }

	// EnumWindows((WNDENUMPROC)TerminateAppEnum, (LPARAM) pid ) ;

	if ( WaitForSingleObject( ph, dwTimeout ) != WAIT_OBJECT_0 )
	{
		UpdatePrivilege();
		gpfDebug("[TerminateProcess] START");
		if ( TerminateProcess(ph, 0) == 0 )
			// rc = gpfSystemError( "kill %d, %s", pid, filename );
			rc = gpfSystemError( "kill %d", pid );
		gpfDebug("[TerminateProcess] END");
	}

	CloseHandle(ph);
	return rc;

#else

	if ( pid <= 1 )
		return gpfError( "wrong pid %d", pid );

	if ( kill( pid, SIGKILL ) == -1 )
		return gpfSystemError( "kill %d", pid );

	return 1;

#endif

}

#if defined(_WINDOWS)

/**
 * コマンドを実行し、プロセスIDを登録する。タイムアウトが0場合は待たずに1を返す
 * @param execCommand 実行ファイル
 * @param timeout タイムアウト
 * @param outPath 標準出力パス
 * @param errPath 標準エラーパス
 * @param child 子プロセス
 * @param exitCode 終了コード
 * @return 合否
 */
int gpfExecCommand(char *execCommand, int timeout, char *outPath, char *errPath, pid_t *child, int *exitCode ) 
{
	char	*command    = NULL;
	int	ret = 1;

	STARTUPINFO *si = NULL;
	PROCESS_INFORMATION *pi = NULL;
	SECURITY_ATTRIBUTES *sa = NULL;
	HANDLE  hFileOut   = NULL;
	HANDLE  hStdOutput = NULL;
	HANDLE  hFileErr   = NULL;
	HANDLE  hStdError  = NULL;
	DWORD   retWait;

	typedef ULONG (__stdcall *GETPROCESSID)(HANDLE Process);
	GETPROCESSID GetProcessId=(GETPROCESSID)GetProcAddress(GetModuleHandle("kernel32.dll"), "GetProcessId");

	/* 標準出力ファイルハンドラの複製 */
	sa = gpfMalloc( sa, sizeof(SECURITY_ATTRIBUTES));
    memset(sa, 0, sizeof(SECURITY_ATTRIBUTES));
    sa->bInheritHandle = TRUE;
	if ( outPath )
	{
		hFileOut = CreateFile(outPath, FILE_APPEND_DATA, FILE_SHARE_READ || FILE_SHARE_WRITE, 
			sa, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		DuplicateHandle(GetCurrentProcess(), hFileOut, GetCurrentProcess(), 
			&hStdOutput, 0, TRUE, DUPLICATE_SAME_ACCESS);
	}
	
	if ( errPath )
	{
		hFileErr = CreateFile(errPath, FILE_APPEND_DATA, FILE_SHARE_READ || FILE_SHARE_WRITE, 
			sa, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		DuplicateHandle(GetCurrentProcess(), hFileErr, GetCurrentProcess(), 
			&hStdError, 0, TRUE, DUPLICATE_SAME_ACCESS);
	}

	/* 複製した標準出力ハンドラを指定して、ウィンドウなしで process startup 構造体セット */
	si = gpfMalloc( si, sizeof(STARTUPINFO));
	memset(si, 0, sizeof(STARTUPINFO));
	pi = gpfMalloc( pi, sizeof(PROCESS_INFORMATION));
    memset(pi, 0, sizeof(PROCESS_INFORMATION));
	si->cb		= sizeof(STARTUPINFO);
	si->dwFlags	    = STARTF_USESTDHANDLES; // STARTF_USESTDHANDLES;
	si->wShowWindow = SW_HIDE;
//	si->hStdOutput	= hFileOut;
//	si->hStdError	= hFileErr;
	si->hStdOutput	= hStdOutput;
	si->hStdError	= hStdError;

	command = gpfDsprintf(command, "%s", execCommand);
	gpfDebug( "[Exec] %s", command );
	gpfDebug("outPath=%s\n", outPath);

	/* プロセスの生成 */
//	if ( !CreateProcess( NULL, command, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, si, pi) )
	// if ( !CreateProcess( NULL, command, sa, sa, TRUE, CREATE_NO_WINDOW, NULL, NULL, si, pi) )
	// 第5引数を FALSE にしてプロセスハンドルを敬称しない
	if ( !CreateProcess( NULL, command, sa, sa, FALSE, CREATE_NO_WINDOW, NULL, NULL, si, pi) )
	{
		gpfSystemError("%s", command);
		ret = 0;
		goto lbl_exit;
	}
	/* プロセス生成後に不要となったファイルハンドラをクローズ */
	if ( hFileOut )	{ CloseHandle(hFileOut);	hFileOut = NULL; }
	if ( hFileErr )	{ CloseHandle(hFileErr);	hFileErr = NULL; }
	if ( hStdOutput )	{ CloseHandle(hStdOutput);	hStdOutput = NULL; }
	if ( hStdError )	{ CloseHandle(hStdError);	hStdError = NULL; }

	*child = GetProcessId( pi->hProcess );  
	gpfNotice("[Exec] %s, pid=%d", command, *child );

	// 不要なスレッドハンドルをクローズする
	if (!CloseHandle(pi->hThread)) {
		gpfSystemError("CloseHandle(hThread)");
		goto lbl_exit;
	}

	/* タイムアウト値が0の場合は何もせずに1を返す */
	if ( timeout <= 0 )
		goto lbl_exit;

	sleep(1);
	/* タイムアウトのモニタリング。タイムアウトしたプロセスは強制終了させる */
	while ( ( retWait = WaitForSingleObject( pi->hProcess, 1000 )) == WAIT_TIMEOUT )
	{
		timeout--;
		gpfDebug( "check timeout[%d] %d ret=%d", *child, timeout, retWait );
		if ( timeout <= 0 )
		{
			gpfNotice("[TIMEOUT] kill child pid=%d", *child );
			gpfKill( *child ); 
			retWait   = 0;
			*exitCode = 1;
			goto lbl_exit;
		}
	}
	GetExitCodeProcess( pi->hProcess, exitCode );
	gpfDebug( "exit = %d, wait = %d", *exitCode, retWait );
	if ( ret == 1)
		gpfInfo("[WAIT] Catch child pid=%d", *child );
	
lbl_exit:
	if ( hFileOut )	{ CloseHandle(hFileOut);	hFileOut = NULL; }
	if ( hFileErr )	{ CloseHandle(hFileErr);	hFileErr = NULL; }
	if ( hStdOutput )	{ CloseHandle(hStdOutput);	hStdOutput = NULL; }
	if ( hStdError )	{ CloseHandle(hStdError);	hStdError = NULL; }
	CloseHandle(pi->hProcess);
	// CloseHandle(pi->hThread);
	gpfFree(pi);
	gpfFree(si);
	gpfFree(sa);
	gpfFree(command);

	return ret;
}

#else
/**
  * ファイルオープンと複製
  * @param outPath パス名
  * @param fd      ファイルディスクリプタ
  * @return ファイルポインタ
  */
FILE *_gpfExecFileRedirect(const char *outPath, int fd) 
{
	FILE *fout = NULL;

	if ( ( fout = fopen(outPath, "a")) == NULL )
	{
		gpfSystemError("%s", outPath);
		return NULL;
	}
	if ( dup2(fileno(fout), fd) == -1 )
	{
		fclose(fout);
		gpfError( "%s", outPath );
		return NULL;
	}
	fclose(fout);
	return fout;
}

/**
 * コマンドを実行し、プロセスIDを登録する。タイムアウトが0場合は待たずに1を返す
 * @param execCommand 実行ファイル
 * @param timeout タイムアウト(waitpidの不具合があるためLinuxの場合は無効)
 * @param outPath 標準出力パス
 * @param errPath 標準エラーパス
 * @param child 子プロセス
 * @return 合否
 */
int gpfExecCommand(char *execCommand, int timeout, char *outPath, char *errPath, 
	pid_t *child, int *exitCode) 
{
	sigset_t mask;
	sigset_t orig_mask;
	pid_t pid;
	int status   = 0;
	int stat     = 0;
	int result   = 0;
	int killed   = 0;
	int exitLoop = 1;
	int fd_backup[2];
	
	sigemptyset (&mask);
	sigaddset (&mask, SIGCHLD);
	if (sigprocmask(SIG_BLOCK, &mask, &orig_mask) < 0) {
		perror ("sigprocmask");
		return 0;
	}

	/* 標準出力のパス指定がない場合は、/dev/nullに出力するように指定 */
	if ( outPath == NULL )
	{
		outPath = "/dev/null";
	}
	if ( errPath == NULL )
	{
		errPath = "/dev/null";
	}
	
	if ( (pid = fork()) < 0 )  
		return gpfSystemError("fork faild");

	/* ファイルディスクリプタを複製した標準出力先にスイッチしてコマンド実行 */
	if(pid == 0) 
	{
		fd_backup[0] = dup(1);
		fd_backup[1] = dup(2);

		/* 標準出力と標準エラー出力先を指定したファイルパスにする */
		if ( (_gpfExecFileRedirect(outPath, 1) != NULL) &&
		     (_gpfExecFileRedirect(errPath, 2) != NULL) )
		{
			result = execlp("sh", "sh", "-c", execCommand, NULL);
			fflush(stdout);
			fflush(stderr);
		}

		dup2(fd_backup[0], 1);
		dup2(fd_backup[1], 2);
		exit( result ); 
	} 

	*child = pid;
	gpfInfo("[Exec][%d] %s", pid, execCommand );


	/* タイムアウト値が0の場合は何もせずに1を返す */
	if ( timeout <= 0 )
		return 1;

 // 	{
	// 	struct timespec waittime;
	 
	// 	waittime.tv_sec  = timeout;
	// 	waittime.tv_nsec = 0;
	 
	// 	do {
	// 		if (sigtimedwait(&mask, NULL, &waittime) < 0) {
	// 			if (errno == EINTR) {
	// 				/* Interrupted by a signal other than SIGCHLD. */
	// 				continue;
	// 			}
	// 			else if (errno == EAGAIN) {
	// 				gpfInfo ("Timeout, killing child [%d]", pid);
	// 				kill (pid, SIGKILL);
	// 				killed = 1;
	// 			}
	// 			else {
	// 				perror ("sigtimedwait");
	// 				return 0;
	// 			}
	// 		}
	 
	// 		break;
	// 	} while (1);
	// }
	
	/* waitpidでプロセス終了を検知する */
	stat = waitpid( pid, &status, 0);

	if ( stat > 0 )
	{
		/* FreeBSDの場合正常終了でも-1を返す場合がある */
		int exit_status = (int)WEXITSTATUS(status);
/*		*exitCode = WEXITSTATUS(status);*/
		*exitCode = exit_status;
		gpfInfo("[WAIT] exited=%d", WIFEXITED(status) );
		gpfInfo("[WAIT] exitstatus=%d", WEXITSTATUS(status) );
		gpfInfo("[WAIT] Catch child pid=%d, rc=%d", pid, *exitCode);
		result = ( *exitCode == 0 )? 1 : 0;
	}
	else 
	{
		gpfSystemError("waitpid(pid=%d)=%d", pid, stat);
		exitLoop  = 0;
		*exitCode = 1;
		result    = 0;
	}

	return (killed == 1) ? 0 : result;
}
#endif 

/**
 * 対話的なコマンド実行
 * @param execCommand 実行ファイル
 * @param exitCode 終了コード
 * @return 合否
 */
int gpfExecCommandInteractive(char *execCommand, int *exitCode) 
{
	*exitCode = system( execCommand );

	return (*exitCode == 0) ? 1 : 0;
}

/**
 * シグナルハンドラー。SIGTERM以外のシグナルは何もしない。
 * SIGTERMの場合は gpfStopProcess()を実行する。
 * @param sig シグナル
 */
void	gpfChildSignalHandler(int sig)
{
	GPFConfig *config = GCON;
	pid_t processId = 0;
	
	switch(sig)
	{
#if !defined(_WINDOWS)
	case SIGPIPE:
		gpfNotice( "Got SIGPIPE. Where it came from ?" );
		break;
	case SIGALRM:
		gpfNotice( "Timeout while answering request" );
		break;
	case SIGQUIT:
#endif
	case SIGINT:
	case SIGTERM:
		gpfWarn( "Got signal. Exiting ..." );
		if ( config->mode == GPF_PROCESS_END )
			exit( -1 );

		processId = gpfGetProcessId( );
		gpfNotice( "stop process (pid=%d)", processId );
		gpfStopProcess( processId );

		exit( 0 );
		break;
	default:
		gpfWarn( "Got signal [%ul]. Ignoring ...", sig);
	}
}

/**
 * シグナル処理。コマンド実行プロセスはなにもせずに、スケジューラプロセスは gpfRunExit()を実行する。
 * @param processId プロセスID
 * @return 合否
 */
int gpfStopProcess( pid_t processId )
{
	GPFConfig *config = GCON;

	
	if ( processId == config->managedPid )
	{
		config->mode = GPF_PROCESS_END;
		gpfNotice( "run exit process (pid=%d, Scheduler)", processId );

		gpfRunExit();
		exit( 0 );
	}
	else
	{
		gpfNotice( "stop process (pid=%d, Worker)", processId );
	}
	return 1;
}

/**
 * シグナルの設定。gpfChildSignalHandler()にフック
 */
#if defined(_WINDOWS)

BOOL WINAPI HandlerRoutine(DWORD dwCtrlType)
{
	pid_t processId = 0;
	printf("catch handler %d\n", dwCtrlType);
	if (dwCtrlType == CTRL_C_EVENT || dwCtrlType == CTRL_BREAK_EVENT) {
		int i;
		printf("CTRL_C_EVENT\n");

		processId = gpfGetProcessId( );
		gpfStopProcess( processId );

		return TRUE;
	}

	if (dwCtrlType == CTRL_CLOSE_EVENT) {
		printf("CTRL_CLOSE_EVENT\n");
		return TRUE;
	}
	
	return FALSE;
}

void	gpfSetSignal( void )
{
	SetConsoleCtrlHandler(HandlerRoutine, TRUE);

	signal( SIGINT,  gpfChildSignalHandler );
	signal( SIGTERM, gpfChildSignalHandler );
}

#else /* not _WINDOWS */

void	gpfSetSignal( void )
{
	struct sigaction signalHandler;

	signalHandler.sa_handler = gpfChildSignalHandler;
	sigemptyset( &signalHandler.sa_mask );
	signalHandler.sa_flags = 0;

	sigaction( SIGINT,	&signalHandler, NULL );
	sigaction( SIGQUIT,	&signalHandler, NULL );
	sigaction( SIGTERM,	&signalHandler, NULL );
	sigaction( SIGPIPE,	&signalHandler, NULL );
}

#endif
