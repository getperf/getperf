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

import com.typesafe.config.*;
import org.slf4j.*;

public class StagingData {
    static final Logger LOG  = LoggerFactory.getLogger(StagingData.class);
    static final Config CONF = ConfigFactory.load();

    public String reserveSender(String siteKey, String filename, int size) {
        return ReserveManager.getInstance().regist(siteKey, filename);
    }

    public String sendData(String siteKey, String filename) {
        SiteConfig repos = SiteConfig.getInstance();

        String stagingFilePath = repos.getStagingRoot() + "/" + siteKey + "/" + filename;
        try {
            MIMEHandler handler = new MIMEHandler();
            handler.extractAttachment(stagingFilePath, filename);
        } catch (Exception e) {
            e.printStackTrace();
            ReserveManager.getInstance().remove(siteKey, filename);
            return "Attachemnt error";
        } finally {
            if (repos.getZipPurgeEnable()) {
                int zipPurgeHour = repos.getZipPurgeHour();
                StagingFileHandler.circulate(siteKey, filename, zipPurgeHour);
            }
        }

        return ReserveManager.getInstance().remove(siteKey, filename);
    }
}
