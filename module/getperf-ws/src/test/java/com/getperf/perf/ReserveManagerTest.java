package com.getperf.perf;

import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

import java.io.*;
import net.arnx.jsonic.JSON;

import org.junit.Test;
import mockit.Mocked;
import mockit.Expectations;

import java.nio.file.*;

public class ReserveManagerTest {

    @Test
    public void setter1() {
        ReserveManager reserves = ReserveManager.getInstance();
        {
            String result = reserves.regist("site1", "arc_host001__22977_01_20150127_1000.zip");
            assertThat(reserves.get_size(), is(1));
            assertThat(result, is("OK"));
        }
        {
            String result = reserves.regist("site1", "arc_host001__22977_01_20150127_1000.zip");
            assertThat(reserves.get_size(), is(1));
            assertThat(result, is("OK"));
        }
        {
            String result = reserves.regist("site1", "arc_host001__22977_02_20150127_1000.zip");
            assertThat(reserves.get_size(), is(2));
            assertThat(result, is("OK"));
        }
    }

    @Test
    public void setter2() {
        ReserveManager reserves = ReserveManager.getInstance();
        reserves.truncate();
        int n = reserves.get_max_servers();
        for (int i = 0; i < n; i++) {
            String host = "host" + i;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(i+1));
            assertThat(result, is("OK"));
        }
        {
            String host = "host" + n;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(n));
            assertThat(result, is(not("OK")));
        }
        {
            String host = "host" + 0;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.remove("site1", filename);
            assertThat(reserves.get_size(), is(n-1));
            assertThat(result, is("OK"));
        }
        {
            String host = "host" + n;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(n));
            assertThat(result, is("OK"));
        }
    }

    @Test
    public void setter3() {
        ReserveManager reserves = ReserveManager.getInstance();
        reserves.truncate();
        int n = reserves.get_max_servers();
        for (int i = 0; i < n; i++) {
            String host = "host" + i;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(i+1));
            assertThat(result, is("OK"));
        }
        {
            String host = "host" + n;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(n));
            assertThat(result, is(not("OK")));
        }
        try {
            Thread.sleep(61000);
        } catch (InterruptedException e) {
            System.out.println(e);
        }
        {
            String host = "host" + n;
            String filename = "arc_" + host + "__22977_02_20150127_1000.zip";
            String result = reserves.regist("site1", filename);
            assertThat(reserves.get_size(), is(n));
            assertThat(result, is("OK"));
        }
    }
}