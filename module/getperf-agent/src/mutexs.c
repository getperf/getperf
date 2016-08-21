/* 
** ZABBIX
** Copyright (C) 2000-2005 SIA Zabbix
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
#include "mutexs.h"

#if !defined(_WINDOWS)

#	if !HAVE_SEMUN
		union semun
		{
			int val;			/* <= value for SETVAL */
			struct semid_ds *buf;		/* <= buffer for IPC_STAT & IPC_SET */
			unsigned short int *array;	/* <= array for GETALL & SETALL */
			struct seminfo *__buf;		/* <= buffer for IPC_INFO */
		};

#		undef HAVE_SEMUN
#		define HAVE_SEMUN 1

#	endif /* semun */

	static int	ZBX_SEM_LIST_ID = -1;

#endif /* not _WINDOWS */

/******************************************************************************
 *                                                                            *
 * Function: zbx_mutex_create_ext                                             *
 *                                                                            *
 * Purpose: Create the mutex                                                  *
 *                                                                            *
 * Parameters:  mutex - handle of mutex                                       *
 *              name - name of mutex (index for nix system)                   *
 *              forced - remove mutex if exist (only for nix)                 *
 *                                                                            *
 * Return value: If the function succeeds, the return ZBX_MUTEX_OK,           *
 *               ZBX_MUTEX_ERROR on an error                                  *
 *                                                                            *
 * Author: Eugene Grigorjev                                                   *
 *                                                                            *
 * Comments: you can use alias 'zbx_mutex_create' and 'zbx_mutex_create_force'*
 *                                                                            *
 ******************************************************************************/
int zbx_mutex_create_ext(ZBX_MUTEX *mutex, ZBX_MUTEX_NAME name, unsigned char forced)
{
#if defined(_WINDOWS)	

	if(NULL == ((*mutex) = CreateMutex(NULL, FALSE, name)))
		return gpfSystemError("mutex create");

#else /* not _WINDOWS */
#define ZBX_MAX_ATTEMPTS 10
	int	attempts = 0;

	int	i;
	key_t	sem_key;
	union semun semopts;
	struct semid_ds seminfo;

	if((sem_key = ftok(".", (int)'z') ) == -1)
		return gpfSystemError("Can not create IPC key for path '.'");

lbl_create:
	if ( (ZBX_SEM_LIST_ID = semget(sem_key, ZBX_MUTEX_COUNT, IPC_CREAT | IPC_EXCL | 0666)) != -1)
	{
		/* set default semaphore value */
		semopts.val = 1;
		for ( i = 0; i < ZBX_MUTEX_COUNT; i++ )
		{
			semopts.val = 1;
			if(semctl(ZBX_SEM_LIST_ID, i, SETVAL, semopts) == -1)
				return gpfSystemError("Semaphore [%i] error in semctl(SETVAL)", name);

			zbx_mutex_lock(&i);
			zbx_mutex_unlock(&i);
		}
	}
	else if (errno == EEXIST)
	{
		gpfDebug("semaphores already exist, trying to recreate.");

		ZBX_SEM_LIST_ID = semget(sem_key, 0 , 0666 );

		if(forced) {
			if( 0 != semctl(ZBX_SEM_LIST_ID, 0, IPC_RMID, 0))
			{
				gpfCrit("Can't recreate semaphores for IPC key 0x%lx,ID %ld", sem_key, ZBX_SEM_LIST_ID);
				exit(1);
			}

			/* Semaphore is successfully removed */
			ZBX_SEM_LIST_ID = -1;

			if ( ++attempts > ZBX_MAX_ATTEMPTS )
			{
				gpfCrit("Can't recreate semaphores for IPC key 0x%lx", sem_key);
				exit(1);
			}
			if ( attempts > (ZBX_MAX_ATTEMPTS / 2) )
			{
				gpfInfo("Wait 1 sec for next attemtion of ZABBIX semaphores creation.");
				sleep(1);
			}
			goto lbl_create;
		}
		
		semopts.buf = &seminfo;
		/* wait for initialization */
		for ( i = 0; i < ZBX_MUTEX_MAX_TRIES; i++)
		{
			if( -1 == semctl(ZBX_SEM_LIST_ID, 0, IPC_STAT, semopts))
			{
				gpfSystemError("Semaphore [%i] error in semctl(IPC_STAT)", name);
				break;
			}
			if(semopts.buf->sem_otime !=0 ) goto lbl_return;
			sleep(1);
		}
		
		return gpfError("Semaphore [%i] not initialized", name);
	}
	else
	{
		return gpfSystemError("Can not create Semaphore");
	}
	
lbl_return:
	*mutex = name;
	
#endif /* _WINDOWS */

	return 1;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_mutex_lock                                                   *
 *                                                                            *
 * Purpose: Waits until the mutex is in the signaled state                    *
 *                                                                            *
 * Parameters: mutex - handle of mutex                                        *
 *                                                                            *
 * Return value: If the function succeeds, the return 1, 0 on an error        *
 *                                                                            *
 * Author: Eugene Grigorjev                                                   *
 *                                                                            *
 * Comments:                                                                  *
 *                                                                            *
 ******************************************************************************/

int zbx_mutex_lock(ZBX_MUTEX *mutex)
{
	int rc = 0;
#if defined(_WINDOWS)	

	if(WaitForSingleObject(*mutex, INFINITE) != WAIT_OBJECT_0)
		return gpfError("Error on mutex locking");

#else /* not _WINDOWS */

	struct sembuf sem_lock = { *mutex, -1, 0 };

	rc = semop(ZBX_SEM_LIST_ID, &sem_lock, 1);
	if ( rc == -1 )
		return 0;
#endif /* _WINDOWS */

	return 1;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_mutex_unlock                                                 *
 *                                                                            *
 * Purpose: Unlock the mutex                                                  *
 *                                                                            *
 * Parameters: mutex - handle of mutex                                        *
 *                                                                            *
 * Return value: If the function succeeds, the return 1, 0 on an error        *
 *                                                                            *
 * Author: Eugene Grigorjev                                                   *
 *                                                                            *
 * Comments:                                                                  *
 *                                                                            *
 ******************************************************************************/

int zbx_mutex_unlock(ZBX_MUTEX *mutex)
{
	int rc = 0;
#if defined(_WINDOWS)	

	if(ReleaseMutex(*mutex) == 0)
		return gpfSystemError("Error on mutex UNlocking");

#else /* not _WINDOWS */
	struct sembuf sem_unlock = { *mutex, 1, 0};

	rc = semop(ZBX_SEM_LIST_ID, &sem_unlock, 1);
	if ( rc == -1 )
		return 0;
	
#endif /* _WINDOWS */

	return 1;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_mutex_destroy                                                *
 *                                                                            *
 * Purpose: Destroy the mutex                                                 *
 *                                                                            *
 * Parameters: mutex - handle of mutex                                        *
 *                                                                            *
 * Return value: If the function succeeds, the return 1, 0 on an error        *
 *                                                                            *
 * Author: Eugene Grigorjev                                                   *
 *                                                                            *
 * Comments:                                                                  *
 *                                                                            *
 ******************************************************************************/

int zbx_mutex_destroy(ZBX_MUTEX *mutex)
{
	
#if defined(_WINDOWS)	

	if(CloseHandle(*mutex) == 0)
		return gpfSystemError("Error on mutex destroying");

#else /* not _WINDOWS */
	union semun semopts;

	semopts.val = 0;
	semctl(ZBX_SEM_LIST_ID, 0, IPC_RMID, semopts);

#endif /* _WINDOWS */
	
	*mutex = (ZBX_MUTEX)0;

	return 1;
}

