Create graph templates
======================

Based on the graph definition that you created, and then create a chart template by using the ** cacti-cli ** command. Graph templates, but we managed in the repository database of Cacti (MySQL),
** Cacti-cli ** command does the automatic registration of the template to access the database.

cacti-cli usage
------------------

Creating a chart template, ** cacti-cli -f -g -r {graph definition file} use the ** command.
The creation of the above-mentioned Linux load average of the template of will be less

::

    cacti-cli -f -g -r lib / graph / Linux / loadavg.json
    Check graph template: HW - CPU Load Average
    Elapse: 2.5727558135986

- -g Option in the template creation options, specify the graph definition file in the -r {path}.
- Graph templates already confirms the already registered, the default behavior is to skip the process without anything if you have a template.
- Forcibly override update the template without skip by attaching the -f option.

Please details of each option by referring to the ** cacti-cli --help **.

If the above message is output, 'HW - CPU Load Average' graph template has been created that, open the management console of Cacti from Web browser to confirm the template.

1. Go to the URL of the Cacti, and log in as the admin user.
2. Select the console tab, open the management screen.
3. From the Templates menu, and then select each of the following menus.

   - Select the Graph Templates menu, from the list - Make sure that the 'HW CPU Load Average' there.
   - Select Host Templates menu, check the 'Linux' that is there from the list.
   - Datasource Templates and select the menu, check the 'Linux / loadavg' that is there from the list.

In this book you omit the description, but it is possible to edit the chart template from Graph Templates menu.
Select a template, color scheme of the chart legend, and title, graph size, the change to suit a variety of properties such as auto scale to the requirements.
Please refer to the <http://www.cacti.net/downloads/docs/html/> `_` Cacti manual for Cacti configuration steps.

-f option is the option to forcibly overwrite update the already certain template, but there is a case override is not complete.
If this is the case, please run the ** cacti-cli ** command from then delete the corresponding template from Graph Templates menu.

For ** __ root __ ** template

The Graph Templates menu, peaked the chart template named ** __ root __ **.
In this template is the base template, and create templates to copy this template.
Creating more than one graph templates, if there is a common preset template (for example, the label for the Y-axis, such as you want to be named Bytes),
After the editing of the label of the Y-axis in this template, by executing the \ ** cacti-cli ** \ command, template set of base template is reflected is created.

Setting the color scheme
----------

** Cacti-cli **, set the color scheme of the chart legend by referring to the color scheme definition file under the lib / graph / color.
The definition of the color scheme (color scheme) has a default and all, if not specified, refer to the file of the following defalut.

- Default.json

   - The default color scheme definition file. ** Cacti-cli ** command refers to this file by default.
   - In the definition of the color scheme list, pattern be selected in random from this list, and set the color of the legend of the chart in any of the pattern to be selected from the first row in the order. The default is random.

- Default.txt

   - Color scheme definition of user-defined files.
   - Tab-delimited in the ID, list of RGB 3 bytes of the color scheme.
   - ID is a color scheme ID of Cacti repository, it will be the ID that has been defined by the {site home} /html/cacti/cacti.sql.
   - The user can edit this file, run the following make_color_list.pl script, and then generate a color scheme definition file.

- Make_color_list.pl

   ** By executing the make_color_list.pl defalut.txt **, default.json and default.html will be generated. default.html You can see the actual color of the definition by opening a Web browser.

all.txt is a list of all color scheme ID that is defined in the Cacti repository, you can create a new color scheme definition to copy this file to the alias.

::

    cd lib / graph / color
    cp all.txt new-color.txt
    Edit the list that you vi new-color.txt # copy
    perl make_color_list.pl new-color.txt

cacti-cli command of --color-scheme you read the color scheme defined in the {color scheme definition file path} option.
In addition, - in the color-style {color scheme} option, select a color from the first row of the color scheme pattern "gradiation" in order,
Or you can randomly select one of whether to select a color for the line of "random".
For example, if you select a color scheme definition of new-color.json from the first row in the order, run the following command.

::

    cacti-cli -f -g -r lib / graph / Linux / loadavg.json \
    --color-schema lib / graph / colors / new-color.json --color-style gradiation
    