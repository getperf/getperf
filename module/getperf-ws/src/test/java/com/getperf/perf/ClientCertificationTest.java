package com.getperf.perf;

import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

import java.io.*;
import net.arnx.jsonic.JSON;

import org.junit.Test;
import org.junit.Before;
import mockit.Mocked;
import mockit.Expectations;

import java.nio.file.*;
import java.io.*;

public class ClientCertificationTest {
    @Test
	public void runtime_exec1() {
		String[] cmd = {"java","-version"};
		RuntimeExec re = new RuntimeExec();
		int rc = -1;
		try {
			rc = re.execCmd(cmd);
		} catch(Exception e) {
			e.printStackTrace();  
		}
		assertThat(rc, is(0));
	}

    @Test
    public void cert1() {
        ClientCertification cert = new ClientCertification("site1", "host1");
        boolean cert_ok = cert.create();
        assertThat(cert_ok, is(true));
    }

}