package com.getperf.perf;

import java.util.Date;
import java.io.*;
import java.nio.file.*;
import net.arnx.jsonic.JSON;
import com.typesafe.config.*;

import org.junit.*;
import mockit.*;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;


public class StagingFileHandlerTest {
    private static final Config CONF = ConfigFactory.load();
    private String test_config = "json/kawasaki/kawasaki__host001__22977_01.json";
    private String test_config_out = 
    	"[\"arc_host001__22977_01_20150127_0500.zip\","+
    	" \"arc_host001__22977_01_20150127_0600.zip\","+
    	" \"arc_host001__22977_01_20150127_0700.zip\","+
    	" \"arc_host001__22977_01_20150127_0800.zip\","+
    	" \"arc_host001__22977_01_20150127_0900.zip\"]";

	@Test
	public void handler1() {
        File file = new File(CONF.getString("GETPERF_STAGING_DIR"), test_config);
        System.out.println(file);
        try {
            File fileDir = new File(CONF.getString("GETPERF_STAGING_DIR"), "json/kawasaki");
            fileDir.mkdir();
            PrintWriter pw = new PrintWriter(new BufferedWriter(new FileWriter(file)));
            pw.println(test_config_out);
            pw.close();
        } catch (IOException e) {
            System.out.println(e);
        }
		String filename = "arc_host001__22977_01_20150127_1000.zip";
		boolean ok = StagingFileHandler.circulate("kawasaki", filename, 3);
		assertThat(ok, is(true));
	}

	@Test
	public void handler2() {
        File fileDir = new File(CONF.getString("GETPERF_STAGING_DIR"), "json/test");
        fileDir.mkdir();
		String filename = "arc_host001__22977_01_20150127_1000.zip";
		boolean ok = StagingFileHandler.circulate("test", filename, 3);
		assertThat(ok, is(true));
	}
}