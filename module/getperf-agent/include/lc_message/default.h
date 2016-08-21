/* 
** GETPERF
** Copyright (C) 2009-2012 Getperf Ltd.
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

#ifndef GETPERF_LC_MESSAGE_H

#define GPF_MSG001E "message test"
#define GPF_MSG002E "Load Error. Check the error message or run 'getperfctl.exe setup'"
#define GPF_MSG003E "Process pid=%d is running"
#define GPF_MSG004E "Waiting %d sec for shutting down the getperf process"
#define GPF_MSG005E "Terminate the process pid=%d"
#define GPF_MSG006E "No running process"
#define GPF_MSG008E "Stop the process or check {GETPERF_HOME}/_wk/_pid file"
#define GPF_MSG011E "Unable to find the host info. Register your host site."
// #define GPF_MSG012E "Verify monitoring commands. Please continue referring to the execution result at the portal (https://cm.getperf.com/cm/). "
// #define GPF_MSG013E "Available metrics(amount)%s"
// #define GPF_MSG014E "Domains%s"
#define GPF_MSG015E "Getperf module [build: %d < %d] is Not the latest. Please update."
// #define GPF_MSG016E "%s script module [build: %d < %d] is Not the latest. Please update."
// #define GPF_MSG017E "Enter new host configuration."
#define GPF_MSG018E "Transmit to register the following host information on '%s'\n%s"
// #define GPF_MSG019E "gpfSendVerifyResult : [ZIP] rc=%d"
// #define GPF_MSG020E "\n[%d]test command : %s"
// #define GPF_MSG021E "Verifying the result on 'Getperf.com'. Please wait."
// #define GPF_MSG022E "Press return key if you exit"
// #define GPF_MSG023E "Client SSL certificate ... %s"
// #define GPF_MSG024E "Verify command result ... %s"
// #define GPF_MSG025E "Partially failed in the formatting analysis."
// #define GPF_MSG026E "Please confirm the error item and check the FAQ on the portal site (http://cm.getperf.com/). Available to monitor the item which has been analyzed successfully."
// #define GPF_MSG027E "Analysis results : \n\n%s"
#define GPF_MSG029E "This command is only available for Windows. Please read readme.txt."
// #define GPF_MSG030E "Enter user id  "
#define GPF_MSG031E "Enter password "
#define GPF_MSG032E "Enter site key "
// #define GPF_MSG033E "Enter the collection metrics. Cancel : 'q' key."
#define GPF_MSG034E "Setup canceled."
#define GPF_MSG035E "No avalable license could be found."
// #define GPF_MSG036E "Select the domains.  Cancel : 'q' key."
#define GPF_MSG037E "Enter the number between 1to %d."
#define GPF_MSG038E "Update module (y/n) ?"
#define GPF_MSG040E "Regist host (y/n) ?"
// #define GPF_MSG041E "Command %s could not be found in %s directory."
// #define GPF_MSG042E "Enter the correct path. Skip : Enter key."
// #define GPF_MSG043E "Execution path could not be found. Skip command verification."
#define GPF_MSG044E "Enter '%s stop' command, if you stop Agent."
#define GPF_MSG045E "Login failed. Please enter the correct ID or Password or republish your ID on the portal site."
#define GPF_MSG046E "Host registration failed."
#define GPF_MSG047E "License expired : %s, Regist new license."
#define GPF_MSG048E "Send a SSL Client certificate request (y/n) ?"
#define GPF_MSG049E "Module updates check failed. Continue (y/n) ?"
// #define GPF_MSG050E "Send verify command result. continue(y/n) ?"
#define GPF_MSG051E "Download and unzip configuration file. OK(y/n) ?"
#define GPF_MSG052E "Continue (y/n) ?"
#define GPF_MSG053E "Unable to find the host info. Run 'getperfctl setup' command."
// #define GPF_MSG054E "Host verify not complete. Run 'getperfctl setup' command."
// #define GPF_MSG055E "Metric [%s,%s] ver %s"
#define GPF_MSG056E "Detect http_proxy. Use this proxy configuration: %s."
#define GPF_MSG057E "Backup configuration files under %s to %s."
#define GPF_MSG058E "Update %s configuration files"
#define GPF_MSG059E "OS restart required, if the service is delete mark. See http://support.microsoft.com/kb/823942."
#define GPF_MSG060E "Initialize SSL license file"
#define GPF_MSG061E "Unavailable to use the directory include blank for Home directory"
// #define GPF_MSG062E "Domain check failed. Need at least 1domain. Register your domain on the GetPerf portal site."
#define GPF_MSG063E "SSL connection error. Terminate the process %s"
// #define GPF_MSG064E "The metric %s does not support %s platform"
#define GPF_MSG065E "The application already start"
#define GPF_MSG066E "Update URL and sitekey"
#define GPF_MSG067E "Update command list"
#define GPF_MSG068E "Update SSL Cert file"
#define GPF_MSG069E "An agent scans a system log file as follows, and transmits to a monitoring site.\n\n- A log is scanned at intervals of 5 minutes, and difference is transmitted to a total server.\n- The transmission line per time has the restrictions up to %d lines. The record beyond it is skipped from the past line.\n- Log scan target is %s."
#define GPF_MSG070E "Verification is started. Continue (y/n) ?"
#define GPF_MSG071E "%s seems that %s does not have reading authority.\nPlease rerun after giving reading permittion to a %s user in a procedure below. \n\n    ls -l %s\n/usr/sbin/usermod -G root %s\n\n    vi /etc/logrotate.d/syslog\n    postrotate\n    /bin/chmod 640 %s\n\n    cd /var/log\n    /bin/chmod 640 %s"
#define GPF_MSG072E "Please rerun after performing the above by a root user. Do you rerun(y/n) ?"
#define GPF_MSG073E "%s seems not have reading authority."
#define GPF_MSG074E "Please add reading permittion. Do you rerun(y/n) ?"
#define GPF_MSG075E "In the case of Windows event log monitoring, Please run as administrator user."
#define GPF_MSG076E "Management Web service connection failed: %s"
#define GPF_MSG077E "\n%s\n is new update module. Extract this zipfile and rerun setup.\n\ncd %s\nunzip %s"
#define GPF_MSG078E "Regist host (y/n) ?"
#define GPF_MSG079E "%s core module check failed"
#define GPF_MSG080E "Invarid license file, Regist new license."
#define GPF_MSG081E "The host already registed"

#endif
