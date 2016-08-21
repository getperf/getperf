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
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.text.*;
import net.arnx.jsonic.JSON;
import org.slf4j.*;
import com.typesafe.config.*;

/**
 * Staging file handler. 
 * - Purge the staging file which is last specified hour.
 * - Update zipfile list : $STAGING_DIR/json/$staging_key.json.
 * - Each process based on the key of "site_key:hostname:stat_id".
 */
public class StagingFileHandler {
    private static final Logger LOG = LoggerFactory.getLogger(StagingFileHandler.class);
    private static final Config CONF = ConfigFactory.load();

    private static String stagingFileDir = CONF.getString("GETPERF_STAGING_DIR");

    public StagingFileHandler(){ super(); }

    /**
     * Read Starging file list : $STAGING_DIR/json/$staging_key.json
     */
    @SuppressWarnings("unchecked")  // Walk around of JSON.decode() unchecked warning.
    private static List<String> readStagingFileLists(String siteKey, String stagingFileKey) {
        List<String> stagingFiles = new ArrayList<String>();
        String stagingFilelistJson = "json/" + siteKey + "/" + stagingFileKey + ".json";
        File filelists = new File(stagingFileDir, stagingFilelistJson);
        LOG.debug("read {}", filelists);
        try (
            FileReader reader = new FileReader(filelists); 
            ){
            stagingFiles = (List<String>)JSON.decode(reader, stagingFiles.getClass());
            LOG.debug("json data {}", stagingFiles);
        }catch(FileNotFoundException e){
            LOG.info("File not found, skip as first creation : {}", stagingFilelistJson);
            System.out.println(e);
        }catch(IOException e){
            System.out.println(e);
        }
        return stagingFiles;
    }

    /**
     * Write Starging file list : $STAGING_DIR/json/$staging_key.json
     */
    private static boolean writeStagingFileLists(String siteKey, String stagingFileKey, String buffer) {
        String targetPath = stagingFileDir + "/json/" + siteKey + "/" + stagingFileKey + ".json";
        String jsonTemp   = targetPath + ".tmp";
        String jsonBackup = targetPath + ".bak";

        try (
            FileWriter file = new FileWriter(jsonTemp);
            ){
            file.write(buffer);
        }catch(IOException e){
            System.out.println(e);
            return false;
        }

        try {
            Path target = Paths.get(targetPath);
            if (Files.exists(target)) {
                Files.move(target, Paths.get(jsonBackup), StandardCopyOption.REPLACE_EXISTING);
            }
            Files.move(Paths.get(jsonTemp), target);
        }catch(IOException e){
            System.out.println(e);
            return false;
        }

        return true;
    }

    /**
     * Purge older staging files, and add new one.
     */
    public static boolean circulate(String siteKey, String filename, int purgeHour) {
        String configDir = stagingFileDir + "/json/" + siteKey;
        File configDirFile = new File(configDir);
        if (!configDirFile.mkdir()) {
            LOG.debug("mkdir '{}', Skip.", configDir);
        }

        // Extract the key "siteKey:host:statId" from siteKey, filename.
        StagingFileInfo stagingFileInfo = new StagingFileInfo(siteKey, filename);
        if (stagingFileInfo == null) {
            LOG.error("Invarid args, siteKey:{}, filename:{}" ,siteKey, filename);
            return false;
        }
        String stagingFileKey = stagingFileInfo.getKey();

        // Read "{siteKey}__{host}__{statId}.json", and remove duplicate rows.
        List<String> stagingFiles = new ArrayList<String>(new HashSet<String>(
            readStagingFileLists(siteKey, stagingFileKey)));

        String stagingFile = null;
        if (stagingFiles != null) {
            // Sort staging file list by timestamp
            String purgeFile = stagingFileInfo.getPurgeFilename(purgeHour);
            LOG.debug("check[{}] purge target = {}", stagingFileKey, purgeFile);
            Collections.sort(stagingFiles);
            // Delete older file of last specified hour.
            for(Iterator<String> ite = stagingFiles.iterator(); ite.hasNext(); ){
                stagingFile = ite.next();
                LOG.debug("check[{}] {}", stagingFileKey, stagingFile);
                if (stagingFile.compareTo(purgeFile) < 0) {
                    LOG.debug("remove {}", stagingFile);
                    try {
                        Path purgeTarget = Paths.get(stagingFileDir, siteKey, stagingFile);
                        Files.delete(purgeTarget);
                    } catch (NoSuchFileException e) {
                        LOG.warn("File not found {}/{}, skip.", siteKey, stagingFile);
                    } catch (IOException e) {
                        System.out.println(e);
                        return false;
                    }
                    ite.remove();
                }
            }
        }
        // Add new staging file.
        if (stagingFile == null || stagingFile.compareTo(filename) < 0) {
            stagingFiles.add(filename);
        }

        return writeStagingFileLists(siteKey, stagingFileKey, JSON.encode(stagingFiles));
    }

	public boolean purge() {
		return true;
	}
}
