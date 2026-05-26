#!/bin/sh

set -e

cp /tmp/nginx.conf /etc/nginx/conf.d/nginx.conf

nginx -t

exec nginx -g "daemon off;"
