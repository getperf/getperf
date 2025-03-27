/**
 * JStatm
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

import java.net.URISyntaxException;
import java.util.*;
import java.io.*;
import java.text.*;
import sun.jvmstat.monitor.*;

public class JStatm {
    
    static String usage = "usage: java JStatm [-p [vm report file]] [-d debug.log] [-o report.txt] [interval] [count]";
    static String propertyFile = null;
    static String debugFile    = null;
    static String reportFile   = null;
    static int    interval     = 5;
    static int    ntimes       = 12;

    public static final String[] reportMetrics = new String[] {
        "java.property.java.version",
        "sun.rt.javaCommand",
        "java.rt.vmArgs"
    };

    public class JvmStatMetric {
        String metricName;
        int formatLength;
    };

    public static final String[] statMetrics = new String[] {
        "sun.gc.generation.0.space.0.used",
        "sun.gc.generation.1.space.0.used",
        "sun.gc.generation.2.space.0.used",
        "sun.gc.collector.0.invocations",
        "sun.gc.collector.1.invocations",
        "sun.gc.collector.0.time",
        "sun.gc.collector.1.time",
        "java.threads.live",
    }; 

    public static final int[] reportColumnSize = new int[] {
        9, 9, 9, 6, 6, 9, 9, 6
    };

    public MonitoredHost monitoredHost;
    public Set <Integer> vmids;

    JStatm () 
        throws MonitorException, URISyntaxException 
    {
        monitoredHost =
            MonitoredHost.getMonitoredHost(new HostIdentifier((String)null));
        vmids = monitoredHost.activeVms();
    }

    public void debugLog (String msg) 
        throws FileNotFoundException, IOException
    {
        if (debugFile == null) {
            return;
        }

        PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(debugFile, true)));
        out.println(msg);
        out.close();
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
            MonitoredVm vm = null;
            String vmidString = "//" + vmid + "?mode=r";           
            VmIdentifier id = new VmIdentifier(vmidString);
            try {
                vm = monitoredHost.getMonitoredVm(id, 1000);
                
                report.println( new StringBuilder().append("\n- pid: ").append(vmid) );
                for ( int i = 0; i < reportMetrics.length; i++ ) {
                    Monitor m = vm.findByName( reportMetrics[i] );
                    String value = String.valueOf(m.getValue());
                    report.println( new StringBuilder().append("  ").append( m.getName())
                        .append( ": " ).append( (value.equals("")) ? "null" : value ).toString() );
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
        throws FileNotFoundException, MonitorException, URISyntaxException, IOException 
    {
        MonitoredHost monitoredHost = this.monitoredHost;
        Set vmids = this.vmids;
        String header = "Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD ";
        PrintStream report = new PrintStream(new FileOutputStream(reportFile, true));
        Date currentTime = new Date();
        SimpleDateFormat df = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
        String tms = new String(df.format(currentTime));

        this.debugLog("[reportJvmstat] tms = " + tms);
        report.println( header );
        Iterator it = vmids.iterator();
        while (it.hasNext()) {
            Integer vmid = (Integer)it.next();
            MonitoredVm vm = null;
            String vmidString = "//" + vmid + "?mode=r";           
            VmIdentifier id = new VmIdentifier(vmidString);

            this.debugLog("[reportJvmstat] id = " + id);
            try {
            	try {
	                vm = monitoredHost.getMonitoredVm(id, 1000);
            	} catch (Exception e) {
            		continue;
            	}
                StringBuffer ln = new StringBuffer();
                ln.append(tms);
                ln.append(" ");
                ln.append(jvmFormat(vmid, 5, true));

                // List<Monitor> r = vm.findByPattern("");
                // for (Monitor m : r) {
                //     System.out.println(m.getName() + "\t" + m.getValue().toString());
                // }
            	for ( int i = 0; i < statMetrics.length; i++ ) {
                    Monitor m = vm.findByName( statMetrics[i] );
                    ln.append(" ");
                    if (m == null) {
                        ln.append( jvmFormat(0, reportColumnSize[i], false) );
                    } else {
                        ln.append( jvmFormat(m.getValue(), reportColumnSize[i], false) );
                    }
                }
                report.println( ln );
                this.debugLog("[reportJvmstat] ln = " + ln);
            } finally {
                if ( vm != null ) {
                    monitoredHost.detach(vm);
                }
            }
        }
        report.close();
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
            } else if ("-d".equals(args[i]) ) {
                if ( i+1 >= args.length) {
                    parseNg = true; break;
                }
                debugFile = args[++i];
            } else if ("-o".equals(args[i]) ) {
                if ( i+1 >= args.length) {
                    parseNg = true; break;
                }
                reportFile = args[++i];
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
        if (reportFile == null) {
            parseNg = true;
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
            statVms.debugLog("[START] printJvmstatInfo");
            if (propertyFile != null) {
                statVms.printJvmstatInfo(propertyFile);
            }
            statVms.debugLog("[END] printJvmstatInfo");

            for ( int i = 0; i < ntimes; i ++) {
                statVms.debugLog("[START] reportJvmstat");
                statVms.reportJvmstat();
                if (i+1 < ntimes) {
                    try{
                        Thread.sleep(1000 * interval);
                    } catch (InterruptedException e) {}                    
                }
                statVms.debugLog("[END] reportJvmstat");
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
