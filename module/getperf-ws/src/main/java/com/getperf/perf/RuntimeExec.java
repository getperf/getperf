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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Command line interface.
 *
 * Run the command , returns an exit code.
 */

public class RuntimeExec {
	static final Logger LOG  = LoggerFactory.getLogger(GetperfService.class);
	
	private InputStream    in  = null;   	
	private InputStream    ein = null;
	private OutputStream   out = null;
	private BufferedReader br  = null;
	private BufferedReader ebr = null;
	private Process process = null;
	private String line     = null;
	private String errLine  = null;
	private Thread stdRun   = null;
	private Thread errRun   = null;    

	/**
	 * The time-out processing in a non- implementation , I will wait until the 
	 * command is finished. Standard output logging to the INFO log level.
	 * Error output logging to the ERROR level log.
	 */

	public int execCmd(String[] cmd) throws IOException, InterruptedException {	 
		int rc = -1;

		process = Runtime.getRuntime().exec(cmd);
		in  = process.getInputStream(); 
		ein = process.getErrorStream();
		out = process.getOutputStream();

		try {
			Runnable inputStreamThread = new Runnable() {
				public void run() {		
					try {
						LOG.debug("Thread stdRun start");
						br = new BufferedReader(new InputStreamReader(in));
						while ((line = br.readLine()) != null) {
							LOG.info("stdout : {}", line);
						}
						LOG.debug("Thread stdRun end");
					} catch (Exception e) {		
						e.printStackTrace();      	
					}
				}
			};

			Runnable errStreamThread = new Runnable(){
				public void run(){		
					try {
						LOG.debug("Thread errRun start");
						ebr = new BufferedReader(new InputStreamReader(ein));
						while ((errLine = ebr.readLine()) != null) {
							LOG.error("stderr : {}", errLine);
						}          	
						LOG.debug("Thread errRun end");
					} catch (Exception e) {		
						e.printStackTrace();      	
					}          
				}
			};

			stdRun = new Thread(inputStreamThread);
			errRun = new Thread(errStreamThread);

			stdRun.start();        
			errRun.start();

			rc = process.waitFor();

			stdRun.join();
			errRun.join();

			LOG.info("return code={}", rc);
		} catch (Exception e) {		
			e.printStackTrace();		
		} finally {
			if(br!=null)br.close();
			if(ebr!=null)ebr.close();
			if(in!=null)in.close();
			if(ein!=null)ein.close();
			if(out!=null)out.close();		
		}
		return rc;
	}
}
