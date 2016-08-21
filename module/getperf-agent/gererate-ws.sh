#!/bin/bash
cd include
soapcpp2 -c -C GetperfServicerSoapcpp2.h

cp soapClientLib.c  ../src
cp soapClient.c      ../src
cp soapC.c             ../src
