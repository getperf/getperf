/* soapClient.c
   Generated by gSOAP 2.8.51 for GetperfServiceSoapcpp2.h

gSOAP XML Web services tools
Copyright (C) 2000-2017, Robert van Engelen, Genivia Inc. All Rights Reserved.
The soapcpp2 tool and its generated software are released under the GPL.
This program is released under the GPL with the additional exemption that
compiling, linking, and/or using OpenSSL is allowed.
--------------------------------------------------------------------------------
A commercial use license is available from Genivia Inc., contact@genivia.com
--------------------------------------------------------------------------------
*/

#if defined(__BORLANDC__)
#pragma option push -w-8060
#pragma option push -w-8004
#endif
#include "soapH.h"
#ifdef __cplusplus
extern "C" {
#endif

SOAP_SOURCE_STAMP("@(#) soapClient.c ver 2.8.51 2017-07-29 21:39:55 GMT")


SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__sendEventLog(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_lvl, char *_msg, char **_sendEventLogReturn)
{	struct ns1__sendEventLog soap_tmp_ns1__sendEventLog;
	struct ns1__sendEventLogResponse *soap_tmp_ns1__sendEventLogResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__sendEventLog._siteKey = _siteKey;
	soap_tmp_ns1__sendEventLog._hostname = _hostname;
	soap_tmp_ns1__sendEventLog._lvl = _lvl;
	soap_tmp_ns1__sendEventLog._msg = _msg;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__sendEventLog(soap, &soap_tmp_ns1__sendEventLog);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__sendEventLog(soap, &soap_tmp_ns1__sendEventLog, "ns1:sendEventLog", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__sendEventLog(soap, &soap_tmp_ns1__sendEventLog, "ns1:sendEventLog", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_sendEventLogReturn)
		return soap_closesock(soap);
	*_sendEventLogReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__sendEventLogResponse = soap_get_ns1__sendEventLogResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__sendEventLogResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_sendEventLogReturn && soap_tmp_ns1__sendEventLogResponse->_sendEventLogReturn)
		*_sendEventLogReturn = *soap_tmp_ns1__sendEventLogResponse->_sendEventLogReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__getPerfConfigFile(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_fileName, char **_getPerfConfigFileReturn)
{	struct ns1__getPerfConfigFile soap_tmp_ns1__getPerfConfigFile;
	struct ns1__getPerfConfigFileResponse *soap_tmp_ns1__getPerfConfigFileResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__getPerfConfigFile._siteKey = _siteKey;
	soap_tmp_ns1__getPerfConfigFile._hostname = _hostname;
	soap_tmp_ns1__getPerfConfigFile._fileName = _fileName;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__getPerfConfigFile(soap, &soap_tmp_ns1__getPerfConfigFile);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__getPerfConfigFile(soap, &soap_tmp_ns1__getPerfConfigFile, "ns1:getPerfConfigFile", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__getPerfConfigFile(soap, &soap_tmp_ns1__getPerfConfigFile, "ns1:getPerfConfigFile", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_getPerfConfigFileReturn)
		return soap_closesock(soap);
	*_getPerfConfigFileReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__getPerfConfigFileResponse = soap_get_ns1__getPerfConfigFileResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__getPerfConfigFileResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_getPerfConfigFileReturn && soap_tmp_ns1__getPerfConfigFileResponse->_getPerfConfigFileReturn)
		*_getPerfConfigFileReturn = *soap_tmp_ns1__getPerfConfigFileResponse->_getPerfConfigFileReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__reserveSendPerfData(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_onOff, char **_reserveSendPerfDataReturn)
{	struct ns1__reserveSendPerfData soap_tmp_ns1__reserveSendPerfData;
	struct ns1__reserveSendPerfDataResponse *soap_tmp_ns1__reserveSendPerfDataResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__reserveSendPerfData._siteKey = _siteKey;
	soap_tmp_ns1__reserveSendPerfData._hostname = _hostname;
	soap_tmp_ns1__reserveSendPerfData._onOff = _onOff;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__reserveSendPerfData(soap, &soap_tmp_ns1__reserveSendPerfData);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__reserveSendPerfData(soap, &soap_tmp_ns1__reserveSendPerfData, "ns1:reserveSendPerfData", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__reserveSendPerfData(soap, &soap_tmp_ns1__reserveSendPerfData, "ns1:reserveSendPerfData", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_reserveSendPerfDataReturn)
		return soap_closesock(soap);
	*_reserveSendPerfDataReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__reserveSendPerfDataResponse = soap_get_ns1__reserveSendPerfDataResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__reserveSendPerfDataResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_reserveSendPerfDataReturn && soap_tmp_ns1__reserveSendPerfDataResponse->_reserveSendPerfDataReturn)
		*_reserveSendPerfDataReturn = *soap_tmp_ns1__reserveSendPerfDataResponse->_reserveSendPerfDataReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__sendPerfData(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_fileName, char **_sendPerfData)
{	struct ns1__sendPerfData soap_tmp_ns1__sendPerfData;
	struct ns1__sendPerfDataResponse *soap_tmp_ns1__sendPerfDataResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__sendPerfData._siteKey = _siteKey;
	soap_tmp_ns1__sendPerfData._hostname = _hostname;
	soap_tmp_ns1__sendPerfData._fileName = _fileName;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__sendPerfData(soap, &soap_tmp_ns1__sendPerfData);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__sendPerfData(soap, &soap_tmp_ns1__sendPerfData, "ns1:sendPerfData", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__sendPerfData(soap, &soap_tmp_ns1__sendPerfData, "ns1:sendPerfData", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_sendPerfData)
		return soap_closesock(soap);
	*_sendPerfData = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__sendPerfDataResponse = soap_get_ns1__sendPerfDataResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__sendPerfDataResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_sendPerfData && soap_tmp_ns1__sendPerfDataResponse->_sendPerfData)
		*_sendPerfData = *soap_tmp_ns1__sendPerfDataResponse->_sendPerfData;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__reserveSender(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, int *_fileSize, char **_reserveSenderReturn)
{	struct ns1__reserveSender soap_tmp_ns1__reserveSender;
	struct ns1__reserveSenderResponse *soap_tmp_ns1__reserveSenderResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__reserveSender._siteKey = _siteKey;
	soap_tmp_ns1__reserveSender._hostname = _hostname;
	soap_tmp_ns1__reserveSender._fileSize = _fileSize;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__reserveSender(soap, &soap_tmp_ns1__reserveSender);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__reserveSender(soap, &soap_tmp_ns1__reserveSender, "ns1:reserveSender", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__reserveSender(soap, &soap_tmp_ns1__reserveSender, "ns1:reserveSender", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_reserveSenderReturn)
		return soap_closesock(soap);
	*_reserveSenderReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__reserveSenderResponse = soap_get_ns1__reserveSenderResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__reserveSenderResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_reserveSenderReturn && soap_tmp_ns1__reserveSenderResponse->_reserveSenderReturn)
		*_reserveSenderReturn = *soap_tmp_ns1__reserveSenderResponse->_reserveSenderReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__sendData(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char **_sendDataReturn)
{	struct ns1__sendData soap_tmp_ns1__sendData;
	struct ns1__sendDataResponse *soap_tmp_ns1__sendDataResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__sendData._siteKey = _siteKey;
	soap_tmp_ns1__sendData._hostname = _hostname;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__sendData(soap, &soap_tmp_ns1__sendData);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__sendData(soap, &soap_tmp_ns1__sendData, "ns1:sendData", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__sendData(soap, &soap_tmp_ns1__sendData, "ns1:sendData", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_sendDataReturn)
		return soap_closesock(soap);
	*_sendDataReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__sendDataResponse = soap_get_ns1__sendDataResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__sendDataResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_sendDataReturn && soap_tmp_ns1__sendDataResponse->_sendDataReturn)
		*_sendDataReturn = *soap_tmp_ns1__sendDataResponse->_sendDataReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__downloadCertificate(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, long *_timestamp, char **_downloadCertificateReturn)
{	struct ns1__downloadCertificate soap_tmp_ns1__downloadCertificate;
	struct ns1__downloadCertificateResponse *soap_tmp_ns1__downloadCertificateResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__downloadCertificate._siteKey = _siteKey;
	soap_tmp_ns1__downloadCertificate._hostname = _hostname;
	soap_tmp_ns1__downloadCertificate._timestamp = _timestamp;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__downloadCertificate(soap, &soap_tmp_ns1__downloadCertificate);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__downloadCertificate(soap, &soap_tmp_ns1__downloadCertificate, "ns1:downloadCertificate", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__downloadCertificate(soap, &soap_tmp_ns1__downloadCertificate, "ns1:downloadCertificate", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_downloadCertificateReturn)
		return soap_closesock(soap);
	*_downloadCertificateReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__downloadCertificateResponse = soap_get_ns1__downloadCertificateResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__downloadCertificateResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_downloadCertificateReturn && soap_tmp_ns1__downloadCertificateResponse->_downloadCertificateReturn)
		*_downloadCertificateReturn = *soap_tmp_ns1__downloadCertificateResponse->_downloadCertificateReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns1__sendMessage(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, int *_sererity, char *_msg, char **_sendMessageReturn)
{	struct ns1__sendMessage soap_tmp_ns1__sendMessage;
	struct ns1__sendMessageResponse *soap_tmp_ns1__sendMessageResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfPMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns1__sendMessage._siteKey = _siteKey;
	soap_tmp_ns1__sendMessage._hostname = _hostname;
	soap_tmp_ns1__sendMessage._sererity = _sererity;
	soap_tmp_ns1__sendMessage._msg = _msg;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns1__sendMessage(soap, &soap_tmp_ns1__sendMessage);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns1__sendMessage(soap, &soap_tmp_ns1__sendMessage, "ns1:sendMessage", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns1__sendMessage(soap, &soap_tmp_ns1__sendMessage, "ns1:sendMessage", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_sendMessageReturn)
		return soap_closesock(soap);
	*_sendMessageReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns1__sendMessageResponse = soap_get_ns1__sendMessageResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns1__sendMessageResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_sendMessageReturn && soap_tmp_ns1__sendMessageResponse->_sendMessageReturn)
		*_sendMessageReturn = *soap_tmp_ns1__sendMessageResponse->_sendMessageReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns2__checkAgent(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_accessKey, char **_checkAgentReturn)
{	struct ns2__checkAgent soap_tmp_ns2__checkAgent;
	struct ns2__checkAgentResponse *soap_tmp_ns2__checkAgentResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfCMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns2__checkAgent._siteKey = _siteKey;
	soap_tmp_ns2__checkAgent._hostname = _hostname;
	soap_tmp_ns2__checkAgent._accessKey = _accessKey;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns2__checkAgent(soap, &soap_tmp_ns2__checkAgent);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns2__checkAgent(soap, &soap_tmp_ns2__checkAgent, "ns2:checkAgent", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns2__checkAgent(soap, &soap_tmp_ns2__checkAgent, "ns2:checkAgent", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_checkAgentReturn)
		return soap_closesock(soap);
	*_checkAgentReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns2__checkAgentResponse = soap_get_ns2__checkAgentResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns2__checkAgentResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_checkAgentReturn && soap_tmp_ns2__checkAgentResponse->_checkAgentReturn)
		*_checkAgentReturn = *soap_tmp_ns2__checkAgentResponse->_checkAgentReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns2__registAgent(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_siteKey, char *_hostname, char *_accessKey, char **_registAgentReturn)
{	struct ns2__registAgent soap_tmp_ns2__registAgent;
	struct ns2__registAgentResponse *soap_tmp_ns2__registAgentResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfCMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns2__registAgent._siteKey = _siteKey;
	soap_tmp_ns2__registAgent._hostname = _hostname;
	soap_tmp_ns2__registAgent._accessKey = _accessKey;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns2__registAgent(soap, &soap_tmp_ns2__registAgent);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns2__registAgent(soap, &soap_tmp_ns2__registAgent, "ns2:registAgent", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns2__registAgent(soap, &soap_tmp_ns2__registAgent, "ns2:registAgent", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_registAgentReturn)
		return soap_closesock(soap);
	*_registAgentReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns2__registAgentResponse = soap_get_ns2__registAgentResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns2__registAgentResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_registAgentReturn && soap_tmp_ns2__registAgentResponse->_registAgentReturn)
		*_registAgentReturn = *soap_tmp_ns2__registAgentResponse->_registAgentReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns2__getLatestBuild(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_moduleTag, int *_majorVer, char **_getLatestBuildReturn)
{	struct ns2__getLatestBuild soap_tmp_ns2__getLatestBuild;
	struct ns2__getLatestBuildResponse *soap_tmp_ns2__getLatestBuildResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfCMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns2__getLatestBuild._moduleTag = _moduleTag;
	soap_tmp_ns2__getLatestBuild._majorVer = _majorVer;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns2__getLatestBuild(soap, &soap_tmp_ns2__getLatestBuild);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns2__getLatestBuild(soap, &soap_tmp_ns2__getLatestBuild, "ns2:getLatestBuild", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns2__getLatestBuild(soap, &soap_tmp_ns2__getLatestBuild, "ns2:getLatestBuild", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_getLatestBuildReturn)
		return soap_closesock(soap);
	*_getLatestBuildReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns2__getLatestBuildResponse = soap_get_ns2__getLatestBuildResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns2__getLatestBuildResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_getLatestBuildReturn && soap_tmp_ns2__getLatestBuildResponse->_getLatestBuildReturn)
		*_getLatestBuildReturn = *soap_tmp_ns2__getLatestBuildResponse->_getLatestBuildReturn;
	return soap_closesock(soap);
}

SOAP_FMAC5 int SOAP_FMAC6 soap_call_ns2__downloadUpdateModule(struct soap *soap, const char *soap_endpoint, const char *soap_action, char *_moduleTag, int *_majorVer, int *_build, char **_downloadUpdateModuleReturn)
{	struct ns2__downloadUpdateModule soap_tmp_ns2__downloadUpdateModule;
	struct ns2__downloadUpdateModuleResponse *soap_tmp_ns2__downloadUpdateModuleResponse;
	if (soap_endpoint == NULL)
		soap_endpoint = "https://getperf.moi:47443/axis2/services/GetperfCMService";
	if (soap_action == NULL)
		soap_action = "";
	soap_tmp_ns2__downloadUpdateModule._moduleTag = _moduleTag;
	soap_tmp_ns2__downloadUpdateModule._majorVer = _majorVer;
	soap_tmp_ns2__downloadUpdateModule._build = _build;
	soap_begin(soap);
	soap->encodingStyle = "";
	soap_serializeheader(soap);
	soap_serialize_ns2__downloadUpdateModule(soap, &soap_tmp_ns2__downloadUpdateModule);
	if (soap_begin_count(soap))
		return soap->error;
	if (soap->mode & SOAP_IO_LENGTH)
	{	if (soap_envelope_begin_out(soap)
		 || soap_putheader(soap)
		 || soap_body_begin_out(soap)
		 || soap_put_ns2__downloadUpdateModule(soap, &soap_tmp_ns2__downloadUpdateModule, "ns2:downloadUpdateModule", "")
		 || soap_body_end_out(soap)
		 || soap_envelope_end_out(soap))
			 return soap->error;
	}
	if (soap_end_count(soap))
		return soap->error;
	if (soap_connect(soap, soap_endpoint, soap_action)
	 || soap_envelope_begin_out(soap)
	 || soap_putheader(soap)
	 || soap_body_begin_out(soap)
	 || soap_put_ns2__downloadUpdateModule(soap, &soap_tmp_ns2__downloadUpdateModule, "ns2:downloadUpdateModule", "")
	 || soap_body_end_out(soap)
	 || soap_envelope_end_out(soap)
	 || soap_end_send(soap))
		return soap_closesock(soap);
	if (!_downloadUpdateModuleReturn)
		return soap_closesock(soap);
	*_downloadUpdateModuleReturn = NULL;
	if (soap_begin_recv(soap)
	 || soap_envelope_begin_in(soap)
	 || soap_recv_header(soap)
	 || soap_body_begin_in(soap))
		return soap_closesock(soap);
	if (soap_recv_fault(soap, 1))
		return soap->error;
	soap_tmp_ns2__downloadUpdateModuleResponse = soap_get_ns2__downloadUpdateModuleResponse(soap, NULL, "", NULL);
	if (!soap_tmp_ns2__downloadUpdateModuleResponse || soap->error)
		return soap_recv_fault(soap, 0);
	if (soap_body_end_in(soap)
	 || soap_envelope_end_in(soap)
	 || soap_end_recv(soap))
		return soap_closesock(soap);
	if (_downloadUpdateModuleReturn && soap_tmp_ns2__downloadUpdateModuleResponse->_downloadUpdateModuleReturn)
		*_downloadUpdateModuleReturn = *soap_tmp_ns2__downloadUpdateModuleResponse->_downloadUpdateModuleReturn;
	return soap_closesock(soap);
}

#ifdef __cplusplus
}
#endif

#if defined(__BORLANDC__)
#pragma option pop
#pragma option pop
#endif

/* End of soapClient.c */