package com.getperf.perf;

import java.util.Date;
import java.text.*;
import java.io.*;
import java.nio.file.*;
import net.arnx.jsonic.JSON;

import org.junit.Test;
import org.junit.Before;
import mockit.Mocked;
import mockit.Expectations;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;


public class StagingFileInfoTest {
    @Test
	public void matcher1() {
		String[] zips = {
			"arc_host001__22977_01_20150127_1000.zip"
		};

		for (String zipfile: zips) {
			StagingFileInfo staging_file = new StagingFileInfo("site1", zipfile);
			Date expected = null;
			try {
				DateFormat df = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
				expected = df.parse("2015/01/27 10:00:00");
	       	} catch (ParseException e) {
	         	e.printStackTrace();
	        }
			assertThat(staging_file.getTimestamp(), is(expected.getTime()));
			assertThat(staging_file.getKey(), is("site1__host001__22977_01"));

			String last_file = staging_file.getPurgeFilename(1);
			assertThat(last_file, is("arc_host001__22977_01_20150127_0900.zip"));
		}
	}

    @Test
	public void matcher2() {
		String[] zips = {
			"arc_host001__22977_01_20150127_100000.zip"
		};
		for (String zipfile: zips) {
			StagingFileInfo staging_file = new StagingFileInfo("site1", zipfile);
			Date expected = null;
			try {
				DateFormat df = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
				expected = df.parse("2015/01/27 10:00:00");
	       	} catch (ParseException e) {
	         	e.printStackTrace();
	        }
			assertThat(staging_file.getTimestamp(), is(expected.getTime()));
			assertThat(staging_file.getKey(), is("site1__host001__22977_01"));

			String last_file = staging_file.getPurgeFilename(1);
			assertThat(last_file, is("arc_host001__22977_01_20150127_090000.zip"));
		}
	}
}