FROM wordpress:php8.2-fpm as wpsrc

FROM amazonlinux

RUN yum -y update
RUN yum install -y -q gcc make
RUN yum install -y -q nginx php-fpm
RUN yum install -y -q php-devel php-mysqli php-pdo \
  php-pear php-mbstring php-cli php-odbc \
  php-gd php-xml php-soap php-zip php-intl php-opcache
RUN yum install -y -q ghostscript
# Install Imagick
RUN yum install -y -q ImageMagick ImageMagick-devel && \
  pear update-channels && \
  pecl update-channels && \
  pecl install --configureoptions 'with-imagick="autodetect"' imagick
RUN echo "extension=imagick" >> /etc/php.d/30-imagick.ini
# Install php-redis
RUN pecl install redis
RUN echo "extension=redis" >> /etc/php.d/30-redis.ini
# Cleanup
RUN yum remove -y -q gcc make && \
  yum autoremove && \
  yum clean all
# Create folder for unix sock
RUN mkdir -p /run/php-fpm
# Config nginx and php-fpm
COPY resources/nginx.conf /etc/nginx/conf.d/default.conf
COPY resources/php-fpm.conf /etc/php-fpm.d/www.conf
# Sample index
# COPY resources/phpinfo.php /var/www/html/phpinfo.php
# Prepare www docs
RUN groupadd www && \
  usermod -a -G www nginx && \
  chown -R nginx:www /var/www && \
  chmod 2775 /var/www
# Install WP
COPY --from=wpsrc /usr/src/wordpress /var/www/html
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
RUN chown -R nginx:www /var/www/html && \
  find /var/www -type d -exec chmod 2775 {} + && \
  find /var/www -type f -exec chmod 0664 {} +
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
