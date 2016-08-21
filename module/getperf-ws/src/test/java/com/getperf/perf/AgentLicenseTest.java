package com.getperf.perf;

import java.io.*;
import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;
import java.nio.file.*;

import net.arnx.jsonic.JSON;

import org.junit.*;
import mockit.*;

public class AgentLicenseTest {
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
        this.test_config_create();
    }

    @Test
    public void key_check1() {
        AgentLicense service = new AgentLicense();
        SiteConfig site_config = SiteConfig.getInstance();
        try {
            Thread.sleep(100);
        } catch (InterruptedException e){}
        SiteInfo site = site_config.getSiteInfo("cacti_cli");
        assertThat(service.getAgentStatus("hogehoge", site.getAccessKey(), "host1"), is("Site not found"));
        assertThat(service.getAgentStatus("cacti_cli", "hogepassword", "host1"), is("Site auth error"));
        assertThat(service.getAgentStatus("cacti_cli", site.getAccessKey(), "host2"), is("Host not found"));
    }

    @Test
    public void download1() {
        AgentLicense service = new AgentLicense();
        SiteConfig site_config = SiteConfig.getInstance();

//        assertThat(service.downloadUpdateModule("Ubuntu14-x86_64", 2, 4), is("NG"));
        assertThat(service.downloadUpdateModule("Hoge", 2, 4), is("module not found"));
    }
}