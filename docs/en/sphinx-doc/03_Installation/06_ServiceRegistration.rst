Service automatic start setting
====================

It performs automatic start-up setting of the various services.

::

     sudo -E rex svc_auto
     rex svc_start

svc_auto is in the automatic start-up settings at the time of OS start-up, svc_start
There is a start-up command of each service. Other there is the following command, please use according to the application.

=============================== =================== =
Use the command
=============================== =================== =
Start-up of each service rex svc_start
Stop for each service rex svc_stop
Restart rex svc_restart of each service
Restart of management for Web services rex restart_ws_admin
Restart of data reception for the Web service rex restart_ws_data
=============================== =================== =
