#!/bin/bash
set -x
if [ ! -z $timezone ]; then
  unlink /etc/localtime
  ln -s /usr/share/zoneinfo/$timezone /etc/localtime
else
  echo "timezone environment variable is not set"
fi 
exec $@