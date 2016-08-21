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

/**
 * Getperf site infomation base class.
 */
public class SiteInfo {
    private static final Config CONF = ConfigFactory.load();

    private String site_key;
	private String home;
    private String staging_dir;
    private String[] domains;
	private String access_key;

	public SiteInfo(){ super();}
	public SiteInfo(String home, String access_key) {
		this.home = home;
		this.access_key = access_key;
	}

	public boolean equals(Object obj) {
		if (obj instanceof SiteInfo) {
			SiteInfo site_info = (SiteInfo) obj;
			return this.home.equals(site_info.home) && 
				this.access_key.equals(site_info.access_key) &&
				this.staging_dir.equals(site_info.staging_dir);
		} else {
			return false;
		}
	}

	public boolean checkAccessKey(String access_key) {
        String key = this.access_key;
        if (key == null || !key.equals(access_key)) {
			return false;
        }
        return true;
	} 

	public String getHome()       { return home; }
	public String getStagingDir() { return staging_dir; }
	public String getAccessKey()  { return access_key; }
	public String[] getDomains()  { return domains; }

	public void setHome(String data)       { home = data; }
	public void setStagingDir(String data) { staging_dir = data; }
	public void setAccessKey(String data)  { access_key = data; }
	public void setDomains(String[] data)  { domains = data; }
}
