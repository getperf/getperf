package com.getperf.perf;

import java.io.*;
import java.nio.file.*;
import net.arnx.jsonic.JSON;

import org.junit.Test;
import org.junit.Before;
import mockit.Mocked;
import mockit.Expectations;
import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

public class WatchDirTest {
    private String test_config;
    private String test_config_out = "{site_key: 'test', home: '/tmp/test', access_key: 'access_key1'}";

    public void test_config_create() {
        try {
            File file = new File(this.test_config);
            PrintWriter pw = new PrintWriter(new BufferedWriter(new FileWriter(file)));
            pw.println(test_config_out);
            pw.close();
        } catch (IOException e) {
            System.out.println(e);
        }
    }

    @Before
    public void before() {
        SiteConfig site_config = SiteConfig.getInstance();
        test_config = site_config.getSiteConfigRoot() + "/test1.json";
        File file = new File(test_config);
        if (file.exists()) {
            file.delete();
        }
    }

    @Test
    public void watch1() {
        SiteConfig site_config = SiteConfig.getInstance();
        SiteInfo site_info = site_config.getSiteInfo("cacti_cli");

        assertThat(site_info, is(notNullValue()));
        try {
            Thread.sleep(100);
        } catch (InterruptedException e){}

        this.test_config_create();

        try {
            Thread.sleep(100);
        } catch (InterruptedException e){}

        SiteInfo site_info2 = site_config.getSiteInfo("test1");
        assertThat(site_info2, is(notNullValue()));
        assertThat(site_info2.getHome(), is("/tmp/test"));
    }

}