#!/bin/sh

printf "Starting PHP 7.0 daemon...\n"
php-fpm82 --daemonize
printf "Starting Apache2...\n"
httpd -D FOREGROUND
printf "Finished bootstrap\n"
# tail -f /var/log/nginx/access.log
