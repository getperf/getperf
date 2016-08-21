Alias /docs <%= $home %>/var/docs
<Directory <%= $home %>/var/docs>
  Options Indexes FollowSymLinks
  order deny,allow
  Allow from all
</Directory>
