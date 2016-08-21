#!/bin/bash
#
# iPython notebook startup 
#

unset HTTP_PROXY
unset HTTPS_PROXY
unset http_proxy
unset https_proxy

ipython notebook --no-browser --ip=0.0.0.0 --port=8888 --profile=nbserver
