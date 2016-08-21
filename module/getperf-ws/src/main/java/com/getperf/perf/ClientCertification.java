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
import java.nio.*;
import java.nio.file.*;
import com.typesafe.config.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Run the perl script , it create the client SSL certificate.
 * The perl script use openssl command, it needs SUDO permittion.
 */

public class ClientCertification {
	static final Logger LOG  = LoggerFactory.getLogger(GetperfService.class);
	private String siteKey;
	private String hostname;
	
	public ClientCertification(){ super();}
	public ClientCertification(String siteKey, String hostname) {
        this.siteKey = siteKey;
        this.hostname = hostname;
	}

	/**
	 * Check agent ssl directory exists ; /etc/getperf/ssl/client/{site}/{host}/
	 */
	public boolean exists() {
        SiteConfig repos = SiteConfig.getInstance();

        Path agentSSL = Paths.get(repos.getAdminSSLDir(), "client", this.siteKey, this.hostname);
        return Files.exists(agentSSL);
	}

	/**
	 * Create client SSL certificate to /etc/getperf/ssl/client/{site}/{host}/
	 * Archive these file to sslconf.zip, and store the same directory.
	 * 
	 * sudo perl $GETPERF_HOME/script/ssladmin.pl client_cert --sitekey={site} --agent={hostname}
	 */

	public boolean create() {
        SiteConfig repos = SiteConfig.getInstance();
        File ssladmin = new File(repos.getHome(), "/script/ssladmin.pl");

		String[] cmd = {
			"perl",
			ssladmin.toString(),
			"client_cert",
			"--sitekey=" + this.siteKey,
			"--agent=" + this.hostname
		};
		StringBuilder sb = new StringBuilder();
		for (String str : cmd) {
		    if (sb.length() > 0) {
    		    sb.append(" ");
		    }
		    sb.append(str);
		}
        LOG.info("Exec: {}", sb);

        try {
        	RuntimeExec re = new RuntimeExec();
        	int exitVal = re.execCmd(cmd);
	        LOG.info ("ExitValue: {}", exitVal); 
        } catch (Exception e) {
			e.printStackTrace();
			return false;
        }

		return true;
	}

}
