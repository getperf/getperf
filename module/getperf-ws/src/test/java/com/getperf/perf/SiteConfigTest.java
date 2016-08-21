package com.getperf.perf;

import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

import java.io.*;
import net.arnx.jsonic.JSON;

import org.junit.Test;
import mockit.Mocked;
import mockit.Expectations;

import java.nio.file.*;

public class SiteConfigTest {

//    @Mocked private SiteConfig repos;

    @Test
    public void jsonic1() {
        String[] domains = {"AAA", "BBB", "CCC", "AA2"};
        File file = new File("../../../../resources/config/site/kawasaki.json");
        try {
            SiteInfo site_info = JSON.decode(new FileReader(file), SiteInfo.class);
            assertThat(site_info.getHome(), is("/tmp/kawasaki"));
            // assertThat(site_info.getDomains(), is(domains));
        }catch(FileNotFoundException e){
            System.out.println(e);
        }catch(IOException e){
            System.out.println(e);
        }
    }

    @Test
    public void setter1() {
        SiteInfo site_info = new SiteInfo("home", "key01");
        assertThat(site_info.getHome(), is("home"));
    }

    @Test
    public void setter2() {
        SiteConfig repos = SiteConfig.getInstance();
        SiteInfo site_info = repos.getSiteInfo("cacti_cli");
        assertThat(site_info, is(notNullValue()));
        // assertThat(site_info.getHome(), is("/tmp/cacti_cli"));
        repos.removeSiteInfo("cacti_cli");
        SiteInfo site_info2 = repos.getSiteInfo("cacti_cli");
        assertThat(site_info2, is(nullValue()));
        repos.removeSiteInfo("cacti_cli");
    }

    @Test
    public void setter3() {
        SiteConfig repos = SiteConfig.getInstance();
        File site_config = new File(repos.getSiteConfigRoot(), "cacti_cli.json");
        boolean put_ok = repos.putSiteInfo(site_config);
        assertThat(put_ok, is(true));
    }

//    @Test(timeout=3000)
    @Test
    public void watch1() {
        boolean recursive = false;
        SiteConfig repos = SiteConfig.getInstance();
        String site_config_root = repos.getSiteConfigRoot();

        assertThat(site_config_root, is("/home/psadmin/getperf/config/site"));

        // register directory and process its events
        Path dir = Paths.get(site_config_root);
        try {
            WatchDir watch = new WatchDir(dir, recursive);
//            new WatchDir(dir, recursive).processEvents();
        } catch (IOException e) {
            System.out.println(e);
        }

    }

    @Test
    public void build1() {
        SiteConfig repos = SiteConfig.getInstance();

//        assertThat(repos.getLatestBuild("Ubuntu14-x86_64", 2), is(4));
        assertThat(repos.getLatestBuild("Ubuntu14-x86_64", 1), is(0));
        assertThat(repos.getLatestBuild("Hoge", 2), is(0));
    }

}