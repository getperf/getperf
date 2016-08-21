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

#ifndef GETPERF_GETPERF_SERVICE_SOAPCPP2_H
#define GETPERF_GETPERF_SERVICE_SOAPCPP2_H

//gsoap ns1  service name:	GetperfService
//gsoap ns1  service location:	https://getperf.moi:47443/axis2/services/GetperfPMService
//gsoap ns1  service namespace:	http://perf.getperf.com

//gsoap ns1  service style:	rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action:	sendEventLog  ""
int ns1__sendEventLog(
    char*				_siteKey,
    char*				_hostname,
    char*				_lvl,
    char*				_msg,
    char*				*_sendEventLogReturn
);

//gsoap ns1  service style:	rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action:	getPerfConfigFile  ""
int ns1__getPerfConfigFile(
    char*				_siteKey,
    char*				_hostname,
    char*				_fileName,
    char*				*_getPerfConfigFileReturn
);

//gsoap ns1  service style:	rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action:	reserveSendPerfData  ""
int ns1__reserveSendPerfData(
    char*				_siteKey,
    char*				_hostname,
    char*				_onOff,
    char*				*_reserveSendPerfDataReturn
);

//gsoap ns1  service style:	rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action:	sendPerfData  ""
int ns1__sendPerfData(
    char*				_siteKey,
    char*				_hostname,
    char*				_fileName,
    char*				*_sendPerfData
);

//gsoap ns1  service style: rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action: reserveSender  ""
int ns1__reserveSender(
    char*               _siteKey,
    char*               _hostname,
    int*                _fileSize,
    char*               *_reserveSenderReturn
);

//gsoap ns1  service style: rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action: sendData  ""
int ns1__sendData(
    char*               _siteKey,
    char*               _hostname,
    char*               *_sendDataReturn
);

//gsoap ns1  service style: rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action: downloadCertificate  ""
int ns1__downloadCertificate(
    char*               _siteKey,
    char*               _hostname,
    long*               _timestamp,
    char*               *_downloadCertificateReturn
);

//gsoap ns1  service style: rpc
//gsoap ns1  service encoding: encoded
//gsoap ns1  service method-action: sendMessage  ""
int ns1__sendMessage(
    char*               _siteKey,
    char*               _hostname,
    int*                _sererity,
    char*               _msg,
    char*               *_sendMessageReturn
);

//gsoap ns2  service name:	GetperfService
//gsoap ns2  service location:	https://getperf.moi:47443/axis2/services/GetperfCMService
//gsoap ns2  service namespace:	http://perf.getperf.com

//gsoap ns2  service style:	rpc
//gsoap ns2  service encoding: encoded
//gsoap ns2  service method-action:	registHost  ""
int ns2__registHost(
    char*				_user,
    char*				_password,
    int					_siteId,
    char*				_category,
    int					_domainId,
    char*				_hostname,
    char*				_osname,
    char*				*_registHostReturn
);

//gsoap ns2  service style: rpc
//gsoap ns2  service encoding: encoded
//gsoap ns2  service method-action: registAgent  ""
int ns2__registAgent(
    char*               _siteKey,
    char*               _hostname,
    char*               _accessKey,
    char*               *_registAgentReturn
);

//gsoap ns2  service style: rpc
//gsoap ns2  service encoding: encoded
//gsoap ns2  service method-action: getLatestBuild  ""
int ns2__getLatestBuild(
    char*               _moduleTag,
    int*                _majorVer,
    char*               *_getLatestBuildReturn
);

//gsoap ns2  service style: rpc
//gsoap ns2  service encoding: encoded
//gsoap ns2  service method-action: downloadUpdateModule  ""
int ns2__downloadUpdateModule(
    char*               _moduleTag,
    int*                _majorVer,
    int*                _build,
    char*               *_downloadUpdateModuleReturn
);

#endif
