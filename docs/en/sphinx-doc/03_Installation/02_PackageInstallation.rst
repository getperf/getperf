Installation of the basic package
============================

First install the basic package. ** Sudo -E yum ** in the management user
You install the command. -E Is optional to read the environment variables sudo user, you will need to enable the proxy settings that you set in the previous section.

::

    sudo -E yum -y groupinstall "Development Tools"
    sudo -E yum -y install kernel-devel kernel-headers
    sudo -E yum -y install libssh2-devel expat expat-devel libxml2-devel
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
    sudo -E yum -y update

And decompression Download Getperf module
======================================

Download the Getperf module, unzip the bottom of the home directory ※
Provisional public version

::

    (Download 'getperf.tar.gz' from the provisional site)
    cd $ HOME
    tar xvf getperf.tar.gz

**Notes**

    Installation of Getperf is 'getperf.tar.gz'
    Done by downloading a set of modules, since the license of the still limited public, there is no formal download site. If the download module is required to download the `module <docs / ja / docs /../ docs / faq.md>` Please get from _ of Contact

Installation of Perl library
============================

Use the Perl library management software cpanm.
Install the cpanm, Perl necessary by using the cpanm --installdeps command
Install the library

Set the home directory of Getperf to GETPERF_HOME environment variable

::

    cd ~ / getperf
    source script / profile.sh
    echo source $ GETPERF_HOME / script / profile.sh >> ~ / .bash_profile

And cpanm, to install the Perl library

::

    sudo -E yum -y install perl-devel
    curl -L http://cpanmin.us | perl - --sudo App :: cpanminus
    cd $ GETPERF_HOME
    sudo -E cpanm --installdeps.

.. Note ::

  - The arrangement of the root under the control of the Perl library

    Such as / usr / share / perl5, to install the library in the directory under the root management.
    Therefore, the installation command, you can either run on all sudo privileges, - please run with the sudo option.

  - About cpanm command error

    cpanm command execution to the "Installing the dependencies failed:" If you get a library of dependent error of,
    Please install the Perl library manually in the package installation of the above-mentioned yum.
    There are cases where trial-and-error work is needed, but it is a complete if it is output the following message in cpanm.

    ::

        -> Working on.
        Configuring Getperf-0.01 ... OK
        <== Installed dependencies for .. Finishing.
        