#! /bin/bash

###################################################################
#Configure services used by host, guest and container.
###################################################################


###### exit on any script line that fails ########################
set -o errexit
###### bail on any unitialized variable reads ####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########
EXIT_CODE=0

echo nameserver 8.8.8.8 > /etc/resolvconf/resolv.conf.d/head
echo nameserver 1.1.1.1 > /etc/resolvconf/resolv.conf.d/head
