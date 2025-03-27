/* 
** GETPERF
** Copyright (C) 2009-2012 Getperf Ltd.
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/

import java.util.*;
import java.text.*;
import java.io.*;
import java.util.regex.PatternSyntaxException;
import java.net.URISyntaxException;
import com.sun.jvmstat.monitor.*;
import com.sun.jvmstat.monitor.event.*;
import com.sun.jvmstat.perf.Units;
import com.sun.jvmstat.perf.Variability;


public class JStatm {
    
    static String usage = "usage: java JStatm [-p [vm report file]] [interval] [count]";
    static String propertyFile = null;
    static int    interval     = 5;
    static int    ntimes       = 12;

    public static final String[] reportMetrics = new String[] {
        "java.vm.version",
        "sun.java.command",
        "hotspot.vm.args"
    };

    public class JvmStatMetric {
        String metricName;
        int formatLength;
    };

    public static final String[] statMetrics = new String[] {
        "hotspot.gc.generation.0.space.0.used",
        "hotspot.gc.generation.1.space.0.used",
        "hotspot.gc.generation.2.space.0.used",
        "hotspot.gc.collector.0.invocations",
        "hotspot.gc.collector.1.invocations",
        "hotspot.gc.collector.0.time",
        "hotspot.gc.collector.1.time",
    }; 

    public static final int[] reportColumnSize = new int[] {
        9, 9, 9, 6, 6, 9, 9
    };

    public MonitoredHost monitoredHost;
    public Set vmids;

    JStatm () 
        throws MonitorException, URISyntaxException 
    {
        vmids = null;
        monitoredHost =
            MonitoredHost.getMonitoredHost(new HostIdentifier((String)null));
        vmids = monitoredHost.activeVMs();
    }

    public void printJvmstatInfo (String propertyFile) 
        throws FileNotFoundException, MonitorException, URISyntaxException 
    {
        MonitoredHost monitoredHost = this.monitoredHost;
        Set vmids = this.vmids;

        PrintStream report = new PrintStream(new FileOutputStream(propertyFile));
        Iterator it = vmids.iterator();
        while (it.hasNext()) {
            Integer vmid = (Integer)it.next();
            MonitoredVM vm = null;
            String vmidString = "//" + vmid + "?mode=r";
//            String vmidString = "" + vmid;
            System.out.println(vmidString);           
            VMIdentifier id = new VMIdentifier(vmidString);
            System.out.println("vmid:" + id);
            try {
                vm = monitoredHost.getMonitoredVM(id, 0);
            System.out.println("monitor:" + id);
                
                report.println( new StringBuffer().append("\n- pid: ").append(vmid) );
                for ( int i = 0; i < reportMetrics.length; i++ ) {
                    Monitor m = vm.findByName( reportMetrics[i] );
                    report.println( new StringBuffer().append("  ").append( m.getName())
                        .append( ": " ).append( String.valueOf(m.getValue())).toString() );
                }
            } finally {
                if ( vm != null ) {
                    monitoredHost.detach(vm);
                }
            }
        }
    }

    private String jvmFormat(Object x,int ncol, boolean leftAlign) 
    {
        StringBuffer rtn = new StringBuffer(x.toString());
        ncol = ncol - rtn.length();
        for (int i = 0; i < ncol; i++) {
            if (leftAlign) {
                rtn.append(" ");                
            } else {
                rtn.insert(0," ");                
            }
        }
        return rtn.toString();
    }

    public void reportJvmstat () 
        throws FileNotFoundException, MonitorException, URISyntaxException 
    {
        MonitoredHost monitoredHost = this.monitoredHost;
        Set vmids = this.vmids;
        String header = "Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT";
        
        Date currentTime = new Date();
        SimpleDateFormat df = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
        String tms = new String(df.format(currentTime));

        System.out.println(header);
        Iterator it = vmids.iterator();
        while (it.hasNext()) {
            Integer vmid = (Integer)it.next();
            MonitoredVM vm = null;
            String vmidString = "//" + vmid + "?mode=r";           
            VMIdentifier id = new VMIdentifier(vmidString);

            try {
                StringBuffer ln = new StringBuffer();
                ln.append(tms);
                ln.append(" ");
                ln.append(jvmFormat(vmid, 5, true));
                vm = monitoredHost.getMonitoredVM(id, 0);
                for ( int i = 0; i < statMetrics.length; i++ ) {
                    Monitor m = vm.findByName( statMetrics[i] );
                    ln.append(" ");
                    ln.append( jvmFormat(m.getValue(), reportColumnSize[i], false) );
                }
                System.out.println(ln);
            } finally {
                if ( vm != null ) {
                    monitoredHost.detach(vm);
                }
            }
        }
    }

    public static void main( String[] args ) 
    {
        int argCount = 0;
        boolean parseNg = false;

        for ( int i = 0; i < args.length; i++ ) {
            if ("-p".equals(args[i]) ) {
                if ( i+1 >= args.length) {
                    parseNg = true; break;
                }
                propertyFile = args[++i];
            } else if ( args[i].matches("^[0-9]+$") ) {
                int val = Integer.parseInt(args[i]);
                if (argCount == 0) {
                    interval = val;
                } else if (argCount == 1) {
                    ntimes = val;
                } else {
                    parseNg = true; break;
                }
                argCount ++;
            } else {
                parseNg = true; break;
            }
        }
        if (parseNg) {            
            System.err.println(usage);
            System.exit(1);
        }

        try {
            JStatm statVms = new JStatm();

            if (statVms.vmids == null) {
                System.exit(0);
            }
            if (propertyFile != null) {
                statVms.printJvmstatInfo(propertyFile);
            }

            for ( int i = 0; i < ntimes; i ++) {
                statVms.reportJvmstat();
                if (i+1 < ntimes) {
                    try{
                        Thread.sleep(1000 * interval);
                    } catch (InterruptedException e) {}                    
                }
            }
        } catch (Exception e) {
            if (e.getMessage() != null) {
                System.err.println(e.getMessage());
            } else {
                Throwable cause = e.getCause();
                if ((cause != null) && (cause.getMessage() != null)) {
                    System.err.println(cause.getMessage());
                } else {
                    e.printStackTrace();
                }
            }
            System.exit(1);
        }
        System.exit(0);
    }
}
