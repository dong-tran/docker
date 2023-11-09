#!/bin/sh

printf "Starting PHP daemon...\n"
php-fpm --daemonize
printf "Starting Apache2...\n"
export APACHE_RUN_DIR=/run/apache2
export APACHE_PID_FILE=/run/apache2/apache2.pid
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
export APACHE_LOG_DIR=/var/log/apache2

exec "$@"
