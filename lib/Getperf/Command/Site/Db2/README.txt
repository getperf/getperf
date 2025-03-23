Stand alone single SELECT benchmark tool.

Helps to understand how DB2 client is interacting with the server, get an idea of the impact of scheduling or other kernel parameters. The tool is doing a 1.000.000 SELECTs against IBM's SYSDUMMY table. The select result is not affected by bufferpool configuration or I/O bottlenecks (reading a page). The result is a "pure" client->DB2->client round trip.
Every 1.000 request the time spend for that amount of requests is accounted. After all requests are done, you'll receive a CSV line with:


- runtime in s = complete runtime of the tool
- min time per 1000 selects in s
- max time per 1000 selects in s
- average per 1000 in s
- cpu_migrations discovered
- amount of peaks
- average distance between peak

If 1000 selects needs the double time of the current average, a "peak" will be accounted. This can be handy to understand scheduling issues, or identify strange hiccups.

How to build
------------

source ~db2inst1/sqllib/db2profile

Examples for build:

1. Do connect within MAKE with user and password
    make all DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1 USER=xx PSSWD=xy

2. Do connect without user and passwd
    make all DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1

3. Do NOT connect within MAKE (do connect yourself)
    make all DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1 DO_CONNECT=no



Bind within make file

1. Including connect and user&password
    make db2_bind DO_CONNECT=yes DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1 USER=xx PSSWD=xy

2. Do connect without user and passwd
    make db2_bind DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1

3. Do NOT connect within MAKE (do connect yourself)
    make db2_bind DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1 DO_CONNECT=no

Additional GRANTS might be needed.

    db2 grant execute on package $SCHEMA.UTILEMB to PUBLIC
    db2 grant execute on package $SCHEMA.TBSEL to PUBLIC

These examples are available under

    make db2_grant DB2PATH=$IBM_DB_HOME DB=DB1 SCHEMA=APPL1  ..

-----------
Run Test

- The stand alone test can be executed as follows:

  ./tbsel $DB $SCHEMA

With User and password:

  ./tbsel $DB $SCHEMA $USER $PASSWORD

- To create multiple runs, you can run

  export DB2DB=DB1
  export DB2SCHEMA=APPL1

 # optional
  export DB2USER=xxx
  export DB2PWD=xxx

source ~db2inst1/sqllib/db2profile
./run_test.sh  $cycles $id

 cycles = Amount of rounds
 id     = TestCaseID

Results in
$id.cv, like this:

CSV-stat-per-1000;9,882;0,00975;0,01164;0,00988;0;0;;
CSV-stat-per-1000;9,936;0,00967;0,01352;0,00994;0;0;;
CSV-stat-per-1000;9,654;0,00950;0,01303;0,00965;0;0;;
CSV-stat-per-1000;10,061;0,00989;0,01313;0,01006;0;0;;
CSV-stat-per-1000;7,585;0,00706;0,00971;0,00758;0;0;;


CSV columns:
runtime in s; min time per 1000 in s; max time per 1000 in s; average per 1000 in s;cpu_migrations;amount of peak; average distance between peaks


