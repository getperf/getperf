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

import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;
import com.typesafe.config.*;
import org.slf4j.*;
import redis.clients.jedis.*;

public class GetperfService {
	static final Logger LOG  = LoggerFactory.getLogger(GetperfService.class);
	static final Config CONF = ConfigFactory.load();
	static final String role = nvl(System.getProperty("GETPERF_WS_ROLE"), "admin");

    private static String nvl( String inValue, String defaultValue ) {
        if ( inValue == null ) {
            return defaultValue;
        }
        return inValue;
    }

	public String  helloService(String msg){
        SiteConfig repos = SiteConfig.getInstance();
        SiteInfo site_info = repos.getSiteInfo("kawasaki");

        LOG.info("site home {} = {}", "kawasaki", site_info.getHome());
		return "Hello "+ msg;
	}

    public String  helloJedis(String msg){
		JedisPool pool = new JedisPool(new JedisPoolConfig(), "localhost");
		Jedis jedis = pool.getResource();
		try {
		  jedis.set("mykey", "Hello");
		  LOG.info("keys(*)=" + jedis.keys("*"));
		  LOG.info("get(mykey)=" + jedis.get("mykey"));
		  jedis.del("mykey");
		  LOG.info("keys(*)=" + jedis.keys("*"));
		} finally {
		  pool.returnResource(jedis);
		}
		pool.destroy();
        return "HelloJedis "+ msg;
    }

	public String testGetAttachedFile() 
		throws java.rmi.RemoteException{
		// FileManageService res = new FileManageService();		
		// if (!res.writeAttachedBinaryFile("/tmp/", "test.txt")) {
		// 		return "Error";
		// }
		return "OK";
	}

	public String checkAgent(String siteKey, String hostname, String accessKey)
		throws java.rmi.RemoteException {
		if (role.equals("admin")) {
			AgentLicense res = new AgentLicense();
			return(res.getAgentStatus( siteKey, accessKey, hostname));
		} else {
			return "Invarid role";
		}
	}

	public String registAgent(String siteKey, String hostname, String accessKey)
		throws java.rmi.RemoteException {
		if (role.equals("admin")) {
			AgentLicense res = new AgentLicense();
			return(res.registAgent(siteKey, accessKey, hostname));
		} else {
			return "Invarid role";
		}
	}

	public String getLatestVersion()
		throws java.rmi.RemoteException {
		if (role.equals("admin")) {
			AgentLicense res = new AgentLicense();
			return(res.getLatestVersion());
		} else {
			return "Invarid role";
		}
	}

	public String getLatestBuild(String moduleTag, int majorVer)
		throws java.rmi.RemoteException {
		if (role.equals("admin")) {
			AgentLicense res = new AgentLicense();
			int build = res.getLatestBuild(moduleTag, majorVer);
			return(new Integer(build).toString());
		} else {
			return "Invarid role";
		}
	}

	public String downloadUpdateModule(String moduleTag, int majorVer, int build)
		throws java.rmi.RemoteException {
		if (role.equals("admin")) {
			AgentLicense res = new AgentLicense();
			return(res.downloadUpdateModule(moduleTag, majorVer, build));
		} else {
			return "Invarid role";
		}
	}

	public String downloadCertificate(String siteKey, String hostname, long timestamp)
		throws java.rmi.RemoteException {
		if (role.equals("data")) {
			AgentLicense res = new AgentLicense();
			return(res.downloadCertificate(siteKey, hostname, timestamp));
		} else {
			return "Invarid role";
		}
	}

	public String reserveSender(String siteKey, String filename, int size)
		throws java.rmi.RemoteException {
		if (role.equals("data")) {
			StagingData res = new StagingData();
			return(res.reserveSender(siteKey, filename, size));
		} else {
			return "Invarid role";
		}
	}

	public String sendData(String siteKey, String filename)
		throws java.rmi.RemoteException {
		if (role.equals("data")) {
			StagingData res = new StagingData();
			return(res.sendData(siteKey, filename));
		} else {
			return "Invarid role";
		}
	}

    public String sendMessage(String siteKey, String hostname, int severity, String message) throws java.rmi.RemoteException {
		if (role.equals("data")) {
			EventManager res = new EventManager();
			return(res.sendMessage(siteKey, hostname, severity, message));
		} else {
			return "Invarid role";
		}
	}

}
