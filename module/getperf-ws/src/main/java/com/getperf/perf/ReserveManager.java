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
import org.slf4j.*;
import com.typesafe.config.*;
import java.text.SimpleDateFormat;

/**
 * Web service reserve manage singleton class.
 *
 * Before the client to send the file , this reservation process is required.
 * Implement simple reservation algolithm.　If the reservation size exceeds 
 * the max_servers, It return a NOT OK.
 */

public class ReserveManager {
	private static final Logger LOG = LoggerFactory.getLogger(ReserveManager.class);
    private static final Config CONF = ConfigFactory.load();
    private static final int A_DAY_MSEC = 24 * 3600 * 1000;
    private static int maxServers = 0;
    private static ReserveManager instance = new ReserveManager();
    private static HashMap<String,StagingFileInfo> reserves;

    /**
     * @trhows NullPointerException if the GETPERF_WS_MAX_SERVERS does not set.
     */

    private ReserveManager() {
        maxServers = CONF.getInt("GETPERF_WS_MAX_SERVERS");
        if (maxServers >= 1) {
            this.maxServers = maxServers;
        } else {
            throw new NullPointerException("Invarid parameter : GETPERF_WS_MAX_SERVERS");
        }
        reserves = new HashMap<String,StagingFileInfo>();

        Thread thread = new Thread(new Runnable(){
            public void run() {
                LOG.info("Watch reserves create {}", Thread.currentThread().getId());
                try {
                    while (true) {
                        Thread.sleep(60000);
                        purge_timeout();
                    }
                } catch (InterruptedException e) {
                    System.out.println(e);
                }
            }
        });
        thread.start();
    }

    public static ReserveManager getInstance() {
        return instance;
    }

    /**
     * Register in the reservation hash . Returns a OK if the number of reservations
     * is under maxServers.
     */

    public static String regist(String siteKey, String stagingFile) {
        StagingFileInfo stagingFileInfo = new StagingFileInfo(siteKey, stagingFile);
        if (stagingFileInfo == null) {
            return "Invarid filename";
        }
        String stagingFileKey = stagingFileInfo.getKey();
        LOG.debug("check hash key {}", stagingFileKey);
        if (!reserves.containsKey(stagingFileKey)) {
            if (reserves.size() >= maxServers) {
                LOG.warn("max servers exceed {}, faild reserve '{}'", maxServers, stagingFileKey);
                return "Max Servers exceed";
            } else {
                LOG.debug("reserve {}", stagingFileKey);
                reserves.put(stagingFileKey, stagingFileInfo);
            }
        }
        return "OK";
    }

    /**
     * Remove in the reservation hash. Return OK if success.
     */

    public static String remove(String siteKey, String stagingFile) {
        StagingFileInfo stagingFileInfo = new StagingFileInfo(siteKey, stagingFile);
        if (stagingFileInfo == null) {
            return "Invarid filename";
        }
        String stagingFileKey = stagingFileInfo.getKey();
        reserves.remove(stagingFileKey);
        return "OK";
    }

    /**
     * Remove the hash that was reserved for 1 day.
     */

    public void purge_timeout() {
        Date now = new Date();
        long current_timestamp = now.getTime();
        for (Map.Entry<String, StagingFileInfo> entry : reserves.entrySet()) {
            String stagingFileKey = entry.getKey();
            StagingFileInfo stagingFileInfo = entry.getValue();
            long timestamp = stagingFileInfo.getTimestamp();
            if (timestamp < current_timestamp - A_DAY_MSEC) {
                reserves.remove(stagingFileKey);
            }
        }
    }

    public void truncate() {
        reserves = new HashMap<String,StagingFileInfo>();
    }

    public int get_max_servers() {
        return maxServers;
    }

    public int get_size() {
        return reserves.size();
    }
}
