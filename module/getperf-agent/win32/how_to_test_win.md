How to build of Windows unit test
=================================

Install CUnit
-------------

The Agent test use [CUnit](http://cunit.sourceforge.net/).

Download latest archive from CUnit site.

https://sourceforge.net/projects/cunit/

Build libcunit.lib using Visual Studio.
When you unzip will come out, Use the solution (CUnit.sln) in the VC9.
2010 Select the VC9 even if you are using or later, I think that it is OK if the conversion of the solution file.

After you open the solution file, generate a library of CUnit, and set the project of "libcunit".
View the properties page of the project, change the run-time library of the "C/C++", "Code Generation" to "multi-threaded DLL (/MD)".

All you need to build.
The resulting Lib file, - you should have as a "libcunit.lib" under the "Release Static Lib".

Copy './VC9/Release - Static Lib with MEMTRACE/libcunit.lib' to win32/CUnit/lib.

cd CUnit-2.1-3
cp './VC9/Release - Static Lib with MEMTRACE/libcunit.lib' $WIN32_HOME/CUnit/lib/libcunit.lib

Copy Header files to win32/CUnit/include.

cp -r ./CUnit/Headers/* $WIN32_HOME/CUnit/include/CUnit/

Compile test binary
-------------------

See how_to_test.md
