#!/bin/sh

printf "Starting PHP daemon...\n"
php-fpm --daemonize
printf "Starting Nginx daemon...\n"
nginx -g "daemon on;"
printf "Finished bootstrap\n"
# tail -f /var/log/nginx/access.log
