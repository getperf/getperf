Graph template customization
==============================

Cacti Notes on use
--------------------

Cacti
And the editing of the template from the Web browser by using the management console. Please refer to the \ `Cacti manual <http://www.cacti.net/downloads/docs/html/>` _ \ is how to edit. Here, we give specific attention point.

- Multi-device of graph templates

   The case of a multi-device configuration, "{template name} - {n} cols"
   Template named creates multiple. {N} is equivalent to the number of items of Cacti. The maximum value of the graph definition
   Become a few minutes of the value of the legend \ _max,
   ** Cacti-cli ** command creates at once a few minutes of graph templates of its value. Cacti
   Because the management console can not only edit the individual templates, before you run the \ ** cacti-cli ** \ command, in advance
   ** \ _ \ _ Root \ _ \ _ **
   Edit the properties required by the template. Because the template is created based on the edited template, you can edit efficiently template.

- Comment tag

   graph \ _comment tag of graph definition, Cacti
   It will be displayed as an input field that can be edited in the management console, but there is a problem that even if the change is not reflected.

- Set the graph title

   "Use of the left side of the check items in the title defines the properties of the chart template
   Per-Graph
   Value "Please be sure to check. In the graph entity by a check you can register an individual name.

   .. Figure :: ../image/cacti_console1.png
      : Align: center
      : Alt: graph template definition

      Graph template definition

Export of templates, import
--------------------------------------

Specify the host template, and export-import the graph template set of the host belongs. For example, Linux
Export host template of will be less.

::

    cacti-cli --export Linux
    Export 'Linux'
    Writing '/home/test/site/test1/lib/cacti/template/0.8.8e/cacti-host-template-Linux.xml'

It outputs the export files in the following path

::

    lib / cacti / template / 0.8.8e / cacti-host-template-Linux.xml

All of graph templates that belong to the host template, to export the data source template. If you want to import will be the following command

::

    cacti-cli --import Linux

Already skip the process without anything if there is a host template. If you want to re-register, please run the import command to delete the host template
