#!/bin/sh

printf "Starting PHP daemon...\n"
php-fpm --daemonize
printf "Starting Apache2...\n"

exec "$@"
