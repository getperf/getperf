package com.getperf.perf;

import java.io.*;
import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;
import java.nio.file.*;

import net.arnx.jsonic.JSON;

import org.junit.*;
import mockit.*;

public class MIMEHandlerTest {
    private String test_config;
    private String test_config_out = "{home: '/tmp/test', access_key: 'access_key1'}";

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
        test_config_create();
    }

    @Test
    public void attachment1() {
        SiteConfig site_config = SiteConfig.getInstance();
        test_config = site_config.getSiteConfigRoot() + "/test1.json";
        MIMEHandler handler = new MIMEHandler();
        try {
            boolean ok = handler.extractAttachment(test_config, "test1.json");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    public void attachment2() {
        SiteConfig site_config = SiteConfig.getInstance();
        test_config = site_config.getSiteConfigRoot() + "/test1.json";
        MIMEHandler handler = new MIMEHandler();
        try {
            boolean ok = handler.appendAttachment(test_config);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}