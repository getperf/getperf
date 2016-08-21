Document Creation
===============

Create an HTML document using the documentation tools Sphinx.


Installation of the Sphinx
-----------------

::

sudo -E yum -y --enablerepo = epel install python-pip python-setuptools
sudo -E pip install sphinx

Generation of HTML documents
-----------------

Build with the following command.

::

     cd $ GETPERF_HOME / docs / ja / docs
     make BUILDDIR = $ GETPERF_HOME / var / docs / html

Make sure build the HTML from browser.

::

	http: // {monitoring server} / docs / html /
