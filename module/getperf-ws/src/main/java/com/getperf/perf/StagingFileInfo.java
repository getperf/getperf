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

import java.util.regex.*;
import java.text.*;
import java.util.Date;


/**
 * Staging file information class. 
 * - Parse staging filename 'arc_{host}__{stat}_{date}_{time}.zip'.
 * - {date},{time} string convert to long epoch timestamp(msec).
 * - Each instance is unique in the key '{site_key}:{host}:{stat}'.
 */
public class StagingFileInfo {
	private final String STAGING_FILE_KEY_SEPARATOR = "__";
	private String site_key;
	private String filename;

	private String key;
	private String hostname;
	private String stat_id;
	private String date_str;
	private String time_str;
	private long timestamp;

    /**
     * Site information constructor.
     * site_key and filename must not be null. In the case of the parse 
     * error of filename, an IllegalArgumentException occurs.
     */
    public StagingFileInfo(){ super(); }
	public StagingFileInfo(String site_key, String filename) {
		site_key = site_key;
		filename = filename;

		// parse 'arc_{host}__{stat}_{date}_{time}.zip'
		String pattern = "^arc_(.+?)__(.+?)_(\\d+)_(\\d+)\\.zip$";
		Pattern r = Pattern.compile(pattern);

		Matcher m = r.matcher(filename);
		if (m.find( )) {
			hostname = m.group(1);
			stat_id  = m.group(2);
			date_str = m.group(3);
			time_str = m.group(4);
		} else {
			throw new IllegalArgumentException("regex parse error arc_{host}__{stat}_{date}_{time}.zip");
		}

		String DATE_PATTERN = getDatePattern("yyyyMMddHHmmss");
	    SimpleDateFormat sdf = new SimpleDateFormat(DATE_PATTERN);  
        try {  
 			Date ta = sdf.parse(date_str + time_str);
 	        timestamp = ta.getTime();  
		} catch (ParseException e) {  
			throw new IllegalArgumentException("time format error");
	    }  

	    key = site_key + STAGING_FILE_KEY_SEPARATOR + hostname + STAGING_FILE_KEY_SEPARATOR + stat_id;
	}

	/**
	 *  Get timestamp format, handle time string length. 
	 */
	private String getDatePattern(String date_pattern) {
		String pattern = null;
		// In case "HHmm" without second, trim "ss".
		if (time_str.length() == 4) {
			pattern = date_pattern.replaceAll("ss", "");
		} else if (time_str.length() == 6) {
		    pattern = date_pattern;  
		} else {
			throw new IllegalArgumentException("time format error");
		}
		return pattern;
	}

	/**
	 *  Get the zip filename that you specify last hour
	 */
	public String getPurgeFilename(int purge_hour) {
		String DATE_PATTERN = getDatePattern("yyyyMMdd_HHmmss");

		String filename = null;
		long purge_timestamp = timestamp - purge_hour * 3600 * 1000;
		Date date = new Date(purge_timestamp);
		String file_time = new SimpleDateFormat(DATE_PATTERN).format(date);

		if (file_time == null) {
			throw new IllegalArgumentException("time convert error : " + purge_timestamp);
		} else {
			// arc_{hostname}__{stat_id}_{date}_{time}.zip
			filename = "arc_" + hostname + "__" + stat_id + "_" + file_time + ".zip";
		}
		return filename;
	}

	/**
	 * Site information matcher.
	 */
	public boolean equals(Object obj) {
		if (obj instanceof StagingFileInfo) {
			StagingFileInfo staging_file_info = (StagingFileInfo) obj;
			return this.site_key.equals(staging_file_info.site_key) && 
				this.filename.equals(staging_file_info.filename);
		} else {
			return false;
		}
	}

	public String getKey()       { return key; }
	public long   getTimestamp() { return timestamp; }
}
