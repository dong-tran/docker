FROM amazonlinux

RUN yum -y update
RUN ulimit -n 1024 && yum install -y -q gcc make
RUN ulimit -n 1024 && yum install -y -q httpd php-fpm
RUN ulimit -n 1024 && yum install -y -q php-devel php-mysqli php-pdo \
  php-pear php-mbstring php-cli php-odbc \
  php-gd php-xml php-soap php-zip php-intl php-opcache
RUN ulimit -n 1024 && yum install -y -q ghostscript
# Install Imagick
RUN ulimit -n 1024 && yum install -y -q ImageMagick ImageMagick-devel && \
  pecl update-channels && \
  pecl -q install --configureoptions 'with-imagick="autodetect"' imagick
RUN echo "extension=imagick" >> /etc/php.d/30-imagick.ini
# Install php-redis
RUN pecl -q install redis
RUN echo "extension=redis" >> /etc/php.d/30-redis.ini
# Cleanup
RUN yum autoremove && \
  yum clean all
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
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/wordpress-6.3.2.tar.gz && \
  tar -xzf /tmp/wordpress.tar.gz -C /var/www/html && \
  rm -rf /tmp/wordpress.tar.gz
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
RUN chown -R apache:apache /var/www/html && \
  find /var/www/html -type d -exec chmod 2775 {} + && \
  find /var/www/html -type f -exec chmod 0664 {} +
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
