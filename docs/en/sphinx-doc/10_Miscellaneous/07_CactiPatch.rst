Compatibility support of Cacti-0.8.8c or later version and IE
=======================================

From Cacti-0.8.8c, tree menu display for the library is the change,
Cacti menu layout in compatibility issues with IE is the problem of collapse will occur. This matter will be resolved in the corresponding below.

To use the * IE11
* To Cacti script to apply the patch below

Cacti patching
--------------

Cacti Go to the site Cacti home directory.

::

	cd {site home} / html / cacti

Following in the two scripts to change the description of the <meta http-equiv = "X-UA-Compatible" content = "edge">.
content = the "edge", will change the content = "IE = 11".

::

	sed -i -e "s / content = \" edge \ "/ content = \" IE = 11 \ "/ g" include / top_header.php
	sed -i -e "s / content = \" edge \ "/ content = \" IE = 11 \ "/ g" include / top_graph_header.php
