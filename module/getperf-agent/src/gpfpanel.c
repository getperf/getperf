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
// #include <windows.h>

#include "resource.h" 
#define GPF_MAIN_MODULE 1
#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_param.h"
#include "gpf_log.h"

LPCSTR lpszWinName   = "Getperf";

HWND _PANEL;

int GPF_SETUP_FLG   = 0;
int GPF_RUNNING_FLG = 0;
int GPF_INSTALL_FLG = 0;

/**
 * メッセージボックスログ出力
 * @param commonFormat 共通フォーマット
 * @param localeFormat 地域別フォーマット

 * @return 合否
 */
int gpfMessageBox( char *commonFormat, char *localFormat, ...)
{
	char body[MAX_STRING_LEN];
	va_list	args;
	va_start(args, localFormat);
	if (GCON != NULL && GCON->localeFlag == 0)
		vsnprintf( &body[0], MAX_STRING_LEN, commonFormat, args);
	else
		vsnprintf( &body[0], MAX_STRING_LEN, localFormat, args);
	va_end(args);

	MessageBox(NULL, TEXT(body), TEXT("Getperf"), MB_OK );
	return 1;
}

/**
 * フラグファイルの有無をチェックして、パネル内ボタンのステータスを更新する
 *
 * @return 合否
 */
int gpfUpdatePanelStatus()
{
	pid_t exitPid = 0;
	GPF_SETUP_FLG   = gpfCheckWorkFile( GCON, "_setup_flg" );
/*	GPF_RUNNING_FLG = gpfCheckWorkFile( GCON, "_running_flg" ); */
	GPF_INSTALL_FLG = gpfCheckWorkFile( GCON, "_install_flg" );

	/* getperf プロセスが存在しない場合は起動フラグをリセットする */
	GPF_RUNNING_FLG = 
		( gpfCheckServiceExist(GCON, GCON->pidFile, &exitPid)) ?
		1 : 0;

	EnableWindow(GetDlgItem(_PANEL, IDC_SETUP),   TRUE);

	if ( GPF_SETUP_FLG == 0 ) 
	{
		EnableWindow(GetDlgItem(_PANEL, IDC_START),   FALSE);
		EnableWindow(GetDlgItem(_PANEL, IDC_STOP),    FALSE);
		EnableWindow(GetDlgItem(_PANEL, IDC_INSTALL), FALSE);
		EnableWindow(GetDlgItem(_PANEL, IDC_REMOVE),  FALSE);
	} 
	else 
	{
		if ( GPF_INSTALL_FLG == 0 ) 
		{
			EnableWindow(GetDlgItem(_PANEL, IDC_INSTALL), TRUE);
			EnableWindow(GetDlgItem(_PANEL, IDC_REMOVE),  FALSE);
			EnableWindow(GetDlgItem(_PANEL, IDC_START),   FALSE);
			EnableWindow(GetDlgItem(_PANEL, IDC_STOP),    FALSE);
		} 
		else 
		{
			EnableWindow(GetDlgItem(_PANEL, IDC_INSTALL), FALSE);
			EnableWindow(GetDlgItem(_PANEL, IDC_REMOVE),  TRUE);

			if ( GPF_RUNNING_FLG == 0 ) 
			{
				EnableWindow(GetDlgItem(_PANEL, IDC_START), TRUE);
				EnableWindow(GetDlgItem(_PANEL, IDC_STOP),  FALSE);
			} 
			else 
			{
				EnableWindow(GetDlgItem(_PANEL, IDC_SETUP), FALSE);
				EnableWindow(GetDlgItem(_PANEL, IDC_START), FALSE);
				EnableWindow(GetDlgItem(_PANEL, IDC_STOP),  TRUE);
				EnableWindow(GetDlgItem(_PANEL, IDC_INSTALL), FALSE);
				EnableWindow(GetDlgItem(_PANEL, IDC_REMOVE),  FALSE);
			}
		}
	}
	return 1;
}

/**
 * getperfctl スクリプト実行
 * @param script [IN] 実行スクリプト
 *
 * @return 合否
 */
int gpfRunGetperfctlScript( char *script )
{
	int rc = 0;
	char *scriptDir = GCON->scriptDir;
	char *cmd       = NULL;
	cmd = gpfCatFile( scriptDir, script, NULL );
	rc  = system( cmd );
	gpfFree( cmd );
	gpfUpdatePanelStatus();

	return (rc == 0) ? 1 : 0;
}

/**
 * ボタンの定期更新
* @param lpx [IN] スレッド用引数(未使用)
 *
 * @return 合否
 */
unsigned __stdcall _gpfUpdatePanelTimer( void * lpx )
{
	while (1)
	{
		gpfUpdatePanelStatus( );
		sleep(1);
	}
	return 0;
}

BOOL CALLBACK DlgProc(HWND hwnd, UINT Message, WPARAM wParam, LPARAM lParam)
{
	HANDLE hThread;
	GPFThreadId threadId;

	switch(Message)
	{
		case WM_INITDIALOG:
			_PANEL = hwnd;
			hThread = (HANDLE)_beginthreadex( NULL, 0, _gpfUpdatePanelTimer, hwnd, 0, 
				(unsigned int*)&threadId );

		break;
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case IDC_SETUP:
					gpfRunGetperfctlScript("gpfSetup.bat");
					break;

				case IDC_START:
					gpfRunGetperfctlScript("gpfStart.bat");
					break;

				case IDC_STOP:
					gpfRunGetperfctlScript("gpfStop.bat");
					break;

				case IDC_INSTALL:
					gpfRunGetperfctlScript("gpfInstall.bat");
					break;

				case IDC_REMOVE:
					gpfRunGetperfctlScript("gpfRemove.bat");
					break;
			}
		break;
		case WM_CLOSE:
			EndDialog(hwnd, 0);
			/* ワークディレクトリ削除。gpfInitAgent()を実行した後は終了時に必要 */
			gpfRemoveWorkDir( GCON );
		break;
		default:
			return FALSE;
	}
	return TRUE;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
	LPSTR lpCmdLine, int nCmdShow)
{
	int rc               = 0;
	GPFConfig *config    = NULL;
	const char *program  = __argv[0];

	if ( FindWindow( NULL, "Getperf" ) != NULL )
	{ 
		/* すでに起動してます */
		gpfMessageBox( GPF_MSG065E, GPF_MSG065 );
		return FALSE; 
	}
	
	if ( (rc = gpfInitAgent( &config, program, NULL, GPF_PROCESS_INIT )) == 0)
	{
		gpfMessageBox( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}
	GCON = config;
	return DialogBox(hInstance, MAKEINTRESOURCE(IDD_MAIN), NULL, DlgProc);
}
