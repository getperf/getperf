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
import net.arnx.jsonic.JSON;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.typesafe.config.*;
import java.nio.file.*;

/**
 * Getperf site config repository. Read config/site/*.conf, check
 * when these file updated.
 * Get instance :
 *   SiteConfig repos = SiteConfig.getInstance();
 * Select site : 
 *   SiteInfo site_info = repos.getSiteInfo("kawasaki");
 * You can get site attribute by : 
 *   site_info.getHome()      // Get site home directory
 *   site_info.setAccessKey() // Get site access key
 */

public class SiteConfig {
	private static final Logger LOG = LoggerFactory.getLogger(SiteConfig.class);
//    private static final Config CONF = ConfigFactory.load("getperf_site.json");
    private static final Config CONF = ConfigFactory.load();
    private static SiteConfig instance = new SiteConfig();
    private static HashMap<String,SiteInfo> site_infos;

    private static String  role;
    private static String  home;
    private static String  site_config_root;
    private static String  staging_root;
    private static boolean zip_purge_enable;
    private static int     zip_purge_hour;
    private static String  agent_major_version;
    private static String  admin_ssl_dir;
    private static String  admin_ssl_client_dir;
    private static String  agent_tar;

    /**
     * Getperf config initializer. Read site config file form $GETPERF_HOME/config/site/*
     * Store repository. 
     */

    private SiteConfig() {
        zip_purge_enable    = CONF.getBoolean("GETPERF_ZIP_PURGE_ENABLE");
        zip_purge_hour      = CONF.getInt("GETPERF_ZIP_PURGE_HOUR");
        agent_major_version = String.valueOf(CONF.getInt("GETPERF_AGENT_MAJOR_VERSION"));
        home                = CONF.getString("GETPERF_HOME");
        staging_root        = CONF.getString("GETPERF_STAGING_DIR");
        admin_ssl_dir       = CONF.getString("GETPERF_ADMIN_SSL_DIR");
        agent_tar           = CONF.getString("GETPERF_AGENT_TAR");

        admin_ssl_client_dir = admin_ssl_dir + "/client";

        // Get access controle role; admin or data.
        role = System.getProperty("GETPERF_WS_ROLE");
        if (role == null) {
            role = "admin";
        }

        File site_root_dir = new File(CONF.getString("GETPERF_HOME"), "/config/site");
        site_config_root = site_root_dir.getPath();
        site_infos = new HashMap<String,SiteInfo>();
        LOG.info("Read site config from '{}'", site_config_root);

        File[] site_configs = site_root_dir.listFiles();
        if (site_configs != null) {
            for (int i = 0 ; i < site_configs.length ; i++){
                if (site_configs[i].isFile()){
                    File site_config = site_configs[i];
                    if (putSiteInfo(site_config) == false) {
                        LOG.warn("Read Error, Skip : {}", site_config);
                    }
                }
            }
        }
        Thread thread = new Thread(new Runnable(){
            public void run() {
                boolean recursive = false;
                LOG.info("WatchDir create {}", Thread.currentThread().getId());
                Path dir = Paths.get(site_config_root);
                try {
                    new WatchDir(dir, recursive).processEvents();
                } catch (IOException e) {
                    System.out.println(e);
                }
            }
        });
        thread.start();
        this.site_config_root = site_config_root;
    }

    public static SiteConfig getInstance() {
        return instance;
    }

    /**
     * Get site config from site_key
     */

    public static SiteInfo getSiteInfo(String site_key) {
        return site_infos.get(site_key);
    }

    /**
     * Put site config from site_config_file. Read "{sitekey}.json" config file,
     * decode JSON, store site_infos hash. If success, it return true.
     */

    public static boolean putSiteInfo(File site_config) {
        // extract "{sitekey}.json"
        boolean read_flag = false;
        String fileName = site_config.getName();
        LOG.info("Parse site config file : '{}'", fileName);
        String[] tokens = fileName.split("\\.(?=[^\\.]+$)");
        if (tokens.length == 2) {
            if (tokens[1].equals("json")) {
                String site_key = tokens[0];
                try {
                    SiteInfo site_info = JSON.decode(new FileReader(site_config), SiteInfo.class);
                    if (site_info != null) {
                        LOG.info("Store site config : '{}'", site_key);
                        site_infos.put(site_key, site_info);
                        read_flag = true; 
                        createSiteStagingDir(site_key);
                    }
                }catch(FileNotFoundException e){
                    System.out.println(e);
                }catch(IOException e){
                    System.out.println(e);
                }
            }
        }
        return read_flag;
    }

    /**
     * Create site directory : ${staging_tar}/json, ${staging_tar}/$site_key
     */

    public static boolean createSiteStagingDir(String site_key) {
        String[] staging_dirs = {"json", site_key};

        for (String staging_dir : staging_dirs) {
            File site_root_dir = new File(staging_root, staging_dir);
            LOG.debug("Check site_root_dir {}", site_root_dir);
            try {
                if (!site_root_dir.exists()) {
                    LOG.info("Create site_root_dir {}", site_root_dir);
                    site_root_dir.mkdirs();
                }
            } catch (Exception e) {
                System.out.println(e);
            }            
        }
        return true;
    }

    /**
     * Get agent latest build : ${agent_tar}/update/$major_ver/$build
     * If not found, return "0".
     */

    public int getLatestBuild(String moduleTag, int majorVer) { 

        Path agentBinPath = Paths.get(agent_tar, "update", moduleTag, String.valueOf(majorVer));

        int latest = 0;
        LOG.info("check buid {}", agentBinPath);
        try (DirectoryStream<Path> d = Files.newDirectoryStream(agentBinPath)) {
            for (Path path : d) {
                try {
                    Path buildPath = path.getFileName();
                    LOG.debug("parse buid {}", buildPath);
                    int build = Integer.parseInt(buildPath.toString());
                    if (latest < build) {
                        latest = build;
                    }
                } catch(NumberFormatException e) {
                    LOG.info("parse error {}, skip", path);
                }
            }
        } catch (IOException ex) {}
        if (latest == 0) {
            LOG.info("build not found");
        }
        return latest;
    }

    public static void removeSiteInfo(String site_key) {
        site_infos.remove(site_key);
    }

    public String getHome() { 
        return home; 
    }

    public String getSiteConfigRoot() { 
        return site_config_root; 
    }

    public String getStagingRoot() { 
        return staging_root; 
    }

    public boolean getZipPurgeEnable() { 
        return zip_purge_enable; 
    }

    public int getZipPurgeHour() { 
        return zip_purge_hour; 
    }

    public String getAgentMajorVersion() { 
        return agent_major_version; 
    }

    public String getAdminSSLDir() { 
        return admin_ssl_dir;
    }

    public String getAdminSSLClientDir() { 
        return admin_ssl_client_dir;
    }

    public String getAgentTarDir() {
        return agent_tar;
    }
}
