FROM php:7.4-fpm

RUN apt update -y && apt upgrade -y && apt autoremove -y
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt update; \
	apt install -y --no-install-recommends \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg \
		--with-webp \
	; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		intl \
		mysqli \
		zip \
	; \
# https://pecl.php.net/package/imagick
	pecl install imagick-3.6.0; \
	docker-php-ext-enable imagick; \
	rm -r /tmp/pear;
# Configure PDO from sqlite to mysql
RUN docker-php-ext-install pdo_mysql
# Install apache
RUN apt install -y apache2 unzip
RUN sed -i s/#ServerRoot/ServerRoot/g /etc/apache2/apache2.conf
RUN sed -i 's/"" combined/" %{ms}T" combined/g' /etc/apache2/apache2.conf
RUN echo 'SetEnvIf Request_URI "^/robots\.txt$" dontlog' >> /etc/apache2/apache2.conf
RUN echo 'SetEnvIf Request_URI "^.+.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf|webp|woff2)$" dontlog' >> /etc/apache2/apache2.conf
RUN echo 'SetEnvIf Request_URI "/favicon\.ico$" dontlog' >> /etc/apache2/apache2.conf
RUN echo "CustomLog /dev/stdout combined" >> /etc/apache2/apache2.conf
RUN echo "ErrorLog  /dev/stderr" >> /etc/apache2/apache2.conf
# COPY resources/envvars.env /etc/apache2/envvars
COPY resources/apache2.conf /etc/apache2/sites-available/000-default.conf
RUN mkdir /var/run/apache2
RUN set -eux; \
	a2enmod rewrite expires headers proxy_http proxy_fcgi;
# Install GhostScript
RUN apt install -y -q ghostscript
# Install php-redis
RUN pecl -q install -o -n -f --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no" enable-redis-msgpack="no" enable-redis-lz4="no" with-liblz4="no"' redis && \
  rm -rf /tmp/pear && \
  docker-php-ext-enable redis opcache
# Ioncube
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        curl -fSL 'https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
        curl -fSL 'https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz' -o ioncube.tar.gz; \
    fi
# Extract and install IonCube
RUN mkdir -p ioncube && \
	tar -xf ioncube.tar.gz -C ioncube --strip-components=1 && \
	chmod 755 ioncube/ioncube_loader_lin_7.4.so && \
	chown -R root:root ioncube/ioncube_loader_lin_7.4.so && \
	mv ioncube/ioncube_loader_lin_7.4.so `php-config --extension-dir` && \
	rm -rf ioncube ioncube.tar.gz && \
	docker-php-ext-enable ioncube_loader_lin_7.4
# Create folder for unix sock
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN mkdir -p /run/php-fpm
# Config nginx and php-fpm
COPY resources/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.backup
RUN mv /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf.backup
# Sample phpinfo
RUN echo "<?php phpinfo(); ?>" >> /var/www/html/phpinfo.php
# Prepare www docs
RUN usermod -a -G www-data www-data && \
  chown -R www-data:www-data /var/www && \
  chmod 2775 /var/www
# Install WP
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/wordpress-6.2.3.tar.gz && \
  tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1 && \
  rm -rf /tmp/wordpress.tar.gz
# Remove default themes, plugins
RUN rm -rf /var/www/html/wp-content/themes/twentytwentyone && \
  rm -rf /var/www/html/wp-content/themes/twentytwentytwo && \
  # rm -rf /var/www/html/wp-content/plugins/akismet && \
  rm -rf /var/www/html/wp-content/plugins/hello.php
# Install object-cache
RUN curl -o /tmp/redis-cache.zip https://downloads.wordpress.org/plugin/redis-cache.2.4.4.zip && \
  unzip /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins && \
  rm -rf /tmp/redis-cache.zip && cp /var/www/html/wp-content/plugins/redis-cache/includes/object-cache.php /var/www/html/wp-content/object-cache.php
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
RUN chown -R www-data:www-data /var/www/html && \
  find /var/www -type d -exec chmod 2775 {} + && \
  find /var/www -type f -exec chmod 0664 {} +
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
CMD ["apachectl", "-D", "FOREGROUND"]
