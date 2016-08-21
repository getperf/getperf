SSL root certificate authority shared by multiple servers
=========================

Monitoring server is there more than one, can be configured to share a root certificate authority between each server. Monitoring server one to create a root certificate authority, otherwise the server will create from the intermediate certificate authority to copy the root certificate authority that you have created. You do not have to create for each server certificate authority certificate to be distributed to the agent by sharing the root certificate authority. Here you already noted the steps to create a with a copy of the server that created the root certificate authority intermediate certificate authority.

Copy of an existing SSL root certificate authority
--------------------------

Already it takes a backup of the directory of private root certificate authority in the monitoring server of building loading the SSL certificate authority. / Etc / getperf / Archive ssl / under ca files to the $ GETPERF_HOME / var / ssl / ca.tar.gz.

::

ssladmin.pl archive_ca

And copy it to the monitoring server that you want to create a new archive file.

::

scp $ GETPERF_HOME / var / ssl / ca.tar.gz {getperf user} @ {monitoring server}: / tmp / ca.tar.gz

Creating an SSL intermediate certificate authority
--------------------------

And a certificate authority that you copied in monitoring server to create a new to the root certificate authority to create from the intermediate certificate authority.

Create a directory for the SSL certificate authority in the beginning.

::

sudo mkdir -p / etc / getperf / ssl
sudo chown -R {getperf user} / etc / getperf

It copied the root certificate authority archive and unzip the bottom of the / etc / getperf / ssl.

::

cd / etc / getperf / ssl
tar xvf /tmp/ca.tar.gz

Create an intermediate certificate authority.

::

cd $ GETPERF_HOME
rex create_inter_ca

Intermediate certificate authority will be created under the / etc / getperf / ssl / inter above.
Created certificate will check with the following command.

::

openssl x509 -text -in /etc/getperf/ssl/inter/ca.crt

The execution result of Issuer: When you copy the root certificate authority, Subject: Make sure that you have become the name of the intermediate certificate authority that created.
