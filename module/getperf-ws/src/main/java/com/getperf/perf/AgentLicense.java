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
import java.nio.file.attribute.*;
import com.typesafe.config.*;
import org.slf4j.*;

/**
 * Management of agent client certificate.
 *　License authentication , SSL client certificate issuance , update.
 */

public class AgentLicense {
    static final Logger LOG  = LoggerFactory.getLogger(AgentLicense.class);
    static final Config CONF = ConfigFactory.load();

    /**
     * License authentication bye access key.
     */

    public String getAgentStatus(String siteKey, String accessKey, String hostname) {
        SiteConfig repos = SiteConfig.getInstance();
        SiteInfo siteInfo = repos.getSiteInfo(siteKey);
        if (siteInfo == null) {
            return "Site not found";
        }
        if (!siteInfo.checkAccessKey(accessKey)) {
            LOG.info("Site {} access key check failed.", siteKey);
            return "Site auth error";
        }
        ClientCertification cert = new ClientCertification(siteKey, hostname);
        if (!cert.exists()) {
            return "Host not found";
        }

        return "OK";
    }

    /**
     * Create SSL client certificate. Attach archive; sslconf.zip.
     */

    public String registAgent(String siteKey, String accessKey, String hostname) {
        boolean ok = false;

        SiteConfig repos = SiteConfig.getInstance();
        SiteInfo siteInfo = repos.getSiteInfo(siteKey);
        if (siteInfo == null) {
            return "Site config not found.";
        }
        if (!siteInfo.checkAccessKey(accessKey)) {
            LOG.info("Site {} access key check failed.", siteKey);
            return "Site accessKey check error.";
        }
        ClientCertification cert = new ClientCertification(siteKey, hostname);

        if (!cert.create()) {
            return "Certification create error";
        }
        String admin_ssl_dir = repos.getAdminSSLClientDir();
        Path sslConfig = Paths.get(admin_ssl_dir, siteKey, hostname, "sslconf.zip");

        MIMEHandler handler = new MIMEHandler();
        try {
            ok = handler.appendAttachment(sslConfig.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }

        return (ok) ? "OK" : "NG";
    }

    /**
     * Download SSL client certificate.
     */

    public String downloadCertificate(String siteKey, String hostname, long timestamp) {
        boolean ok = false;

        // Get SSL archive : ${admin_ssl_dir}/$siteKey/$hostname/sslconf.zip
        SiteConfig repos = SiteConfig.getInstance();
        String admin_ssl_dir = repos.getAdminSSLClientDir();
        Path sslConfig = Paths.get(admin_ssl_dir, siteKey, hostname, "sslconf.zip");
        LOG.debug("sslConfig {}", sslConfig);

        long lastModifytime = 0;
        try {
            FileTime time = Files.getLastModifiedTime(sslConfig);
            lastModifytime = time.toMillis();
        } catch (Exception e) {
            LOG.error("Not found {}", sslConfig);
            return "sslconf.zip extract error";
        }
        // If the update date is newer than the last time , download.
        if (timestamp < lastModifytime) {
            MIMEHandler handler = new MIMEHandler();
            try {
                ok = handler.appendAttachment(sslConfig.toString());
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else {
            return "sslconf.zip is the latest.";
        }

        return (ok) ? "OK" : "NG";
    }

    /**
     * Get agent major version number.
     */

    public String getLatestVersion() {
        SiteConfig repos = SiteConfig.getInstance();
        return repos.getAgentMajorVersion();
    }

    /**
     * Get agent module build.
     */

    public int getLatestBuild(String moduleTag, int majorVer) {
        SiteConfig repos = SiteConfig.getInstance();
        return repos.getLatestBuild(moduleTag, majorVer);
    }

    /**
     * Download SSL client certificate.
     */

    public String downloadUpdateModule(String moduleTag, int majorVer, int build) {
        boolean ok = false;

        // Get agent update : ${agent_tar}/update/$major_ver/$build/getperf-bin.zip
        SiteConfig repos = SiteConfig.getInstance();
        String agentTar = repos.getAgentTarDir();

        // Get zip file. (ex) getperf-bin-Ubuntu14-x86_64-4.zip
        String agentBinZip = "getperf-bin-" + moduleTag + "-" + build + ".zip";
        Path agentBinPath = Paths.get(agentTar, "update", moduleTag, String.valueOf(majorVer), String.valueOf(build), agentBinZip);
        LOG.debug("download agentBin {}", agentBinPath);

        try {
            FileTime time = Files.getLastModifiedTime(agentBinPath);
        } catch (Exception e) {
            LOG.error("Not found {}", agentBinPath);
            return "module not found";
        }
        MIMEHandler handler = new MIMEHandler();
        try {
            ok = handler.appendAttachment(agentBinPath.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }

        return (ok) ? "OK" : "NG";
    }
}
