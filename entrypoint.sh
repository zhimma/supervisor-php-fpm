#!/bin/sh
set -e 
supervisord --nodaemon --configuration /etc/supervisord/supervisord.conf
