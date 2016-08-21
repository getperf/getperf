Construction of IPython Notebook environment
===========================

Install an interactive Python development tools IPython Notebook using the Web browser.

Python integration package Anaconda installation
-------------------------------------------

And the Anaconda installation of Python integration package. Under the home directory of Anaconda is the general user
In order to build the environment, it will enable the installation of Python package without changing the OS environment.
Download the package to choose the PYTHON 2.7 Linux 64-bit from the following vendors site.

http://www.continuum.io/

The package file that you downloaded to start with sh to start the installer. Proceed with the installation with the default settings.
$ HOME / anaconda2 is the module of the home directory. And then re-read the .bash_profile to load the environment variables for Anaconda.

::

source ~ / .bash_profile

Upgrade the Python package installer pip.

::

pip install --upgrade pip

Install the Python library for Graphite in the pip.

::

pip install libgraphite

IPython Notebook Setup
--------------------------------

IPython Notebook is bundled with the Anaconda package, already available.
Here you create and configure a profiler for the IPython Notebook. Create a profiler of the provision that default.

::

ipython profile create default

Edit the configuration file of the profiler that was created.

::

vi ~ / .ipython / profile_default / ipython_config.py

Add the following to the last line, and to load automatically a variety of library at the time of start-up.

::

  c.InteractiveShellApp.exec_lines = [
          "Import numpy as np",
          "Import pandas as pd",
          "Import matplotlib.pyplot as plt",
          "Import libgraphite as lg",
          "% Matplotlib inline"
  ]

The setup is now completed. And make sure that it works in the IPython Notebook startup script.
Please start the script from the move to the development for the directory the current directory at the time of start-up it will be in IPython Notebook of the home directory. Start by creating a ~ / work / tmp directory to try.

::

mkdir ~ / work / tmp
cd ~ / work / tmp
ipython_notebook.sh

You access the following URL from the Web browser.

::

http: // {monitoring server}: 8888 /

Select the Python2 from the top right corner of the New menu of the browser screen.
