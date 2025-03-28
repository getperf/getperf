<?xml version="1.0" encoding="ISO-8859-1"?>

<!--
  ~ Licensed to the Apache Software Foundation (ASF) under one
  ~ or more contributor license agreements. See the NOTICE file
  ~ distributed with this work for additional information
  ~ regarding copyright ownership. The ASF licenses this file
  ~ to you under the Apache License, Version 2.0 (the
  ~ "License"); you may not use this file except in compliance
  ~ with the License. You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied. See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  -->

<!DOCTYPE web-app PUBLIC "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN" "http://java.sun.com/dtd/web-app_2_3.dtd">

<web-app>
    <display-name>Apache-Axis2</display-name>
    <servlet>
        <servlet-name>AxisServlet</servlet-name>
        <display-name>Apache-Axis Servlet</display-name>
        <servlet-class>org.apache.axis2.transport.http.AxisServlet</servlet-class>
        <init-param>
        <param-name>axis2.xml.path</param-name>
        <param-value>[% ws_tomcat_dir %]/webapps/axis2/WEB-INF/conf/axis2.xml</param-value>
        <!--<param-name>axis2.xml.url</param-name>-->
        <!--<param-value>http://localhost/myrepo/axis2.xml</param-value>-->
        <!--<param-name>axis2.repository.path</param-name>-->
        <!--<param-value>/WEB-INF</param-value>-->
        <!--<param-name>axis2.repository.url</param-name>-->
        <!--<param-value>http://localhost/myrepo</param-value>-->
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet>
        <servlet-name>AxisAdminServlet</servlet-name>
        <display-name>Apache-Axis AxisAdmin Servlet (Web Admin)</display-name>
        <servlet-class>
            org.apache.axis2.webapp.AxisAdminServlet</servlet-class>
    </servlet>
    
    <!-- servlet>
        <servlet-name>SOAPMonitorService</servlet-name>
        <display-name>SOAPMonitorService</display-name>
        <servlet-class>org.apache.axis2.soapmonitor.servlet.SOAPMonitorService</servlet-class>
        <init-param>
            <param-name>SOAPMonitorPort</param-name>
            <param-value>5001</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet -->
    
    <servlet-mapping>
        <servlet-name>AxisServlet</servlet-name>
        <url-pattern>/servlet/AxisServlet</url-pattern>
    </servlet-mapping>

    <servlet-mapping>
        <servlet-name>AxisServlet</servlet-name>
        <url-pattern>*.jws</url-pattern>
    </servlet-mapping>

    <servlet-mapping>
        <servlet-name>AxisServlet</servlet-name>
        <url-pattern>/services/*</url-pattern>
    </servlet-mapping>

    <servlet-mapping>
        <servlet-name>AxisAdminServlet</servlet-name>
        <url-pattern>/axis2-admin/*</url-pattern>
    </servlet-mapping>

    <!-- servlet-mapping>
        <servlet-name>SOAPMonitorService</servlet-name>
        <url-pattern>/SOAPMonitor</url-pattern>
    </servlet-mapping -->
    
    <mime-mapping>
        <extension>inc</extension>
        <mime-type>text/plain</mime-type>
    </mime-mapping>

   <welcome-file-list>
      <welcome-file>index.jsp</welcome-file>
      <welcome-file>index.html</welcome-file>
      <welcome-file>/axis2-web/index.jsp</welcome-file>
    </welcome-file-list>

    <error-page>
      <error-code>404</error-code>
      <location>/axis2-web/Error/error404.jsp</location>
    </error-page>

    <error-page>
        <error-code>500</error-code>
        <location>/axis2-web/Error/error500.jsp</location>
    </error-page>

    <context-param>
        <param-name>logbackDisableServletContainerInitializer</param-name>
        <param-value>true</param-value>
    </context-param>

</web-app>
