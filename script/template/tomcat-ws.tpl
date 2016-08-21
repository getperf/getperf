/usr/local/tomcat-admin/logs/tomcat.log
/usr/local/tomcat-admin/logs/catalina.out
/usr/local/tomcat-data/logs/tomcat.log
/usr/local/tomcat-data/logs/catalina.out
{
    copytruncate
    daily
    rotate 7
    compress
    missingok
    create 0644 <%= $ws_tomcat_owner %> <%= $ws_tomcat_owner %>
}
