#!/bin/sh

find ./ -name '*.obj'       | xargs rm
find ./ -name '*.exe'       | xargs rm
find ./ -name 'getperf'     | xargs rm
find ./ -name 'getperfctl'  | xargs rm
find ./ -name 'getperfsoap' | xargs rm
find ./ -name 'getperfzip'  | xargs rm
find ./ -name '*.log'       | xargs rm
