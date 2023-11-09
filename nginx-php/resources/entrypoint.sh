#!/bin/sh

printf "Starting PHP daemon...\n"
php-fpm --daemonize
printf "Starting Nginx daemon...\n"
exec "$@"
