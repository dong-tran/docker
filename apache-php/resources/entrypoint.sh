#!/bin/sh

printf "Starting PHP daemon...\n"
php-fpm --daemonize
printf "Starting Apache2...\n"
httpd -DFOREGROUND
# printf "Finished bootstrap\n"
# tail -f /var/log/httpd/access.log
