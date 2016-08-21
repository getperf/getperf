/*
 * Getperf
 * Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
package com.getperf.perf;

import java.io.*;
import java.util.*;
import java.util.zip.*;
import java.util.Calendar;
import java.util.regex.*;
import java.nio.channels.FileChannel;

//import javax.xml.soap.AttachmentPart;
import javax.activation.DataHandler;
import javax.activation.FileDataSource;

import org.slf4j.*;
import org.apache.axis2.AxisFault;
import org.apache.axis2.context.*;
import org.apache.axis2.wsdl.WSDLConstants;
import org.apache.axiom.attachments.*;
import org.apache.axiom.om.*;

/**
 * Axis2 SOAP with attachment. Extract and append attachment file.
 */

public class MIMEHandler {
	static final Logger LOG = LoggerFactory.getLogger(MIMEHandler.class);

	/**
	 *  Get attachment file from MIME envelope.
	 *  In principle, attachementID is a filename.
	 */

	public boolean extractAttachment(String target, String attachementID) 
		throws java.rmi.RemoteException {
		boolean success = false;

		MessageContext ctx = MessageContext.getCurrentMessageContext();
		if (ctx == null) {
			throw new AxisFault("NO Message");
		}

        Attachments attachment = ctx.getAttachmentMap();
		if(attachment == null){
			throw new AxisFault("NO Attachments");
		}

		DataHandler dataHandler = attachment.getDataHandler(attachementID);
		if(dataHandler == null){
			throw new AxisFault("NO Attachment ID " + attachementID);
		}

        File file = new File(target);
		try (
			FileOutputStream fileOutputStream = new FileOutputStream(file);
			){
			dataHandler.writeTo(fileOutputStream);
			fileOutputStream.flush();
			success = true;
			LOG.debug("Get Attachment {}", attachementID);
		}
		catch(Exception e){
			e.printStackTrace();
			throw new AxisFault("Attachment file write error.");
		}
		return success;		
	}
	
	/**
	 *  Append attachment file to MIME envelope.
	 */

	public boolean appendAttachment(String source) 
		throws java.rmi.RemoteException {
		boolean success = false;

		File file =  new File(source);
		if (file.exists()) {
			try {
				MessageContext ctx = MessageContext.getCurrentMessageContext();
				if (ctx == null) {
					throw new AxisFault("NO Message");
				}
				OperationContext operationContext = ctx.getOperationContext();
				MessageContext outMessageContext = operationContext
					.getMessageContext(WSDLConstants.MESSAGE_LABEL_OUT_VALUE);

				FileDataSource dataSource  = new FileDataSource(source);
				DataHandler dataHandler = new DataHandler(dataSource);
				String graphCID = outMessageContext.addAttachment(dataHandler);

				OMFactory factory = OMAbstractFactory.getOMFactory();
				OMNamespace omNs = factory.createOMNamespace("http://service.sample/xsd", "swa");
				OMElement wrapperElement = factory.createOMElement("getStatsResponse", omNs);
				OMElement graphElement   = factory.createOMElement("graph", omNs, wrapperElement);
		        graphCID = "cid:" + graphCID;
				graphElement.addAttribute("href", graphCID, null);
				success = true;

				LOG.info("Get Attachment");
			}
			catch(Exception e){
				e.printStackTrace();
				throw new AxisFault("Attachment file write error.");
			}
		} else {
			LOG.error("File not found : " + source);
		}
		return success;		
	}
}
