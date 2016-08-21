SSL Settings
=======

And create a variety of SSL certificate. Certificates are created under the / etc / getperf / ssl.

Creating the SSH key
-------------

Create the SSH key file in under the $ HOME / .ssh directory administrator user for Git communication.
Using Git, if you want to replicate the external Getperf site, use the .ssh / id_rsa.pub file that was created as a public key file. For more information, `FAQ (replica of the external site) <docs / ja / docs />` _ Please refer to.

::

    cd $ GETPERF_HOME
    rex install_ssh_key

Creating an SSL certificate
---------------

Create a private certificate authority for HTTPS communication of the agent Web service. Under the / etc / getperf / ssl / ca save each certificate.

::

    rex create_ca # create a root certificate authority
    rex create_inter_ca # create intermediate certificate authority

.. Note ::

Getperf is configured in the certificate authority of the two-stage configuration of plug-Bate root certificate authority and the intermediate certificate authority. Create a root certificate authority in monitoring server one, and the other server is able to share the root certificate authority to copy the root certificate authority that you have created. For the certificate authority procedure for constructing at multiple monitoring servers, other `SSL root certificate authority shared by multiple servers <../ 10_Miscellaneous / 04_SSLCertificateInstration.html>` _ Please refer to. Here, we give some steps to create two of the root certificate authority and the intermediate certificate authority to one.

Creating a server certificate
------------------

Create an SSL certificate for the Apache server agent Web service. Under the / etc / getperf / ssl / server and save each certificate. You set this certificate in the installation of the Apache HTTP server which will be described later.

::

    rex server_cert
    