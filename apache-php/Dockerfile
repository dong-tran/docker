# Dockerfile for Alpine Apache, mod_rewrite, PHP-FPM 8.2, GD, MBString, DOM, JSON
 
# Base Image
FROM alpine
 
# Environment Variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
 
# Install Apache
RUN apk update && apk add --no-cache --update --verbose \
  apache2 \
  apache2-proxy
# Install php
RUN apk add --no-cache --update --verbose \
  # php82 \
  php82-fpm \
  php82-json \
  php82-mysqli \
  php82-curl \
  php82-dom \
  php82-mbstring \
  php82-exif \
  php82-fileinfo \
  php82-pecl-imagick \
  php82-gd \
  php82-ctype \
  php82-redis
RUN rm -rf /var/cache/apk /tmp
# Configure Apache
RUN sed -i "s/#ServerName www.example.com:80/ServerName localhost:80/" /etc/apache2/httpd.conf && \
    sed -i "s/#LoadModule mpm_event_module/LoadModule mpm_event_module/" /etc/apache2/httpd.conf && \
    sed -i "s/^LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/" /etc/apache2/httpd.conf && \
    sed -i "s/#LoadModule rewrite_module/LoadModule rewrite_module/" /etc/apache2/httpd.conf && \
    sed -i "s/AllowOverride None/AllowOverride All/" /etc/apache2/httpd.conf && \
    sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php index.html/" /etc/apache2/httpd.conf

RUN echo "<FilesMatch \.php$>" >> /etc/apache2/httpd.conf && \
    echo '    SetHandler "proxy:fcgi://127.0.0.1:9000"' >> /etc/apache2/httpd.conf && \
    echo "</FilesMatch>" >> /etc/apache2/httpd.conf

RUN echo "Mutex posixsem" >> /etc/apache2/httpd.conf
 
# Configure PHP-FPM
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php82/php-fpm.conf && \
    sed -i "s/;listen.owner = nobody/listen.owner = www-data/" /etc/php82/php-fpm.conf && \
    sed -i "s/;listen.group = nobody/listen.group = www-data/" /etc/php82/php-fpm.conf && \
    sed -i "s/;listen.mode = 0660/listen.mode = 0666/" /etc/php82/php-fpm.conf

# Sample index
COPY resources/phpinfo.php /var/www/localhost/htdocs/phpinfo.php
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

# Expose Ports
EXPOSE 80

ENTRYPOINT [ "entrypoint.sh" ]
