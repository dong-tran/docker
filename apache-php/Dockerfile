FROM wordpress:php8.2-fpm as wpsrc

FROM amazonlinux

RUN yum -y update
RUN yum install -y gcc make
RUN yum install -y httpd php-fpm
RUN yum install -y php-devel php-mysqli php-pdo \
  php-pear php-mbstring php-cli php-odbc \
  php-gd php-xml php-soap php-zip php-intl php-opcache
RUN yum install -y ghostscript
# Install Imagick
RUN yum install -y ImageMagick ImageMagick-devel && \
  pear update-channels && \
  pecl update-channels && \
  pecl install --configureoptions 'with-imagick="autodetect"' imagick
RUN echo "extension=imagick" >> /etc/php.d/30-imagick.ini
# Install php-redis
RUN pecl install redis
RUN echo "extension=redis" >> /etc/php.d/30-redis.ini
# Cleanup
RUN yum remove -y gcc make && yum autoremove && yum clean all
# Create folder for unix sock
RUN mkdir -p /run/php-fpm
# Config php-fpm
COPY resources/php-fpm.conf /etc/php-fpm.d/www.conf
# Sample index
# COPY resources/phpinfo.php /var/www/html/phpinfo.php
# Prepare www docs
RUN usermod -a -G apache apache && \
  chown -R apache:apache /var/www && \
  chmod 2775 /var/www
# Install WP
COPY --from=wpsrc /usr/src/wordpress /var/www/html
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
RUN chown -R apache:apache /var/www/html && \
  find /var/www/html -type d -exec chmod 2775 {} + && \
  find /var/www/html -type f -exec chmod 0664 {} +
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
