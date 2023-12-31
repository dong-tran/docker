##### Builder setup needed application
FROM debian:bullseye AS builder

ENV NGINX_VERSION=1.24.0
ENV NGX_CACHE_PURGE_VERSION=2.3
ENV PHP_VERSION=7.4
ENV WP_VERSION=6.2.3
ENV REDIS_CACHE_VERSION=2.4.4
ENV PHP_NATIVE_SESSION_VERSION=1.4.2

## NginX
RUN apt update && apt upgrade -y && apt autoremove -y && \
    apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev wget unzip
WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz
RUN wget https://github.com/FRiCKLE/ngx_cache_purge/archive/${NGX_CACHE_PURGE_VERSION}.tar.gz && \
    tar -zxvf ${NGX_CACHE_PURGE_VERSION}.tar.gz
WORKDIR /tmp/nginx-${NGINX_VERSION}
RUN ./configure \
	--prefix=/etc/nginx \
	--user=www-data \
	--group=www-data \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_stub_status_module \
	--with-http_v2_module \
	--with-http_dav_module \
	--with-threads \
	--with-file-aio \
	--with-http_slice_module \
	--with-stream \
	--with-stream_ssl_module \
	--add-module=/tmp/ngx_cache_purge-${NGX_CACHE_PURGE_VERSION} && \
    make && make install
WORKDIR /tmp
## IonCube
RUN set -ex; \
	savedAptMark="$(dpkg --print-architecture)"; \
	if [ $savedAptMark = "amd64" ]; then \
		wget -O ioncube.tar.gz 'https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz'; \
	elif [ $savedAptMark = "arm64" ]; then \
		wget -O ioncube.tar.gz 'https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz'; \
	fi; \
	mkdir -p ioncube; \
	tar -xf ioncube.tar.gz -C ioncube --strip-components=1; \
	chmod 755 ioncube/ioncube_loader_lin_${PHP_VERSION}.so; \
	chown -R root:root ioncube/ioncube_loader_lin_${PHP_VERSION}.so; \
	mv ioncube/ioncube_loader_lin_${PHP_VERSION}.so /tmp/ioncube_loader.so; \
	rm -rf ioncube ioncube.tar.gz;
## Wordpress
RUN set -ex; \
	wget -O /tmp/wordpress.tar.gz https://wordpress.org/wordpress-${WP_VERSION}.tar.gz; \
	mkdir wordpress; \
	tar -xzf /tmp/wordpress.tar.gz -C wordpress --strip-components=1; \
  rm -rf /tmp/wordpress.tar.gz; \
	wget -O /tmp/redis-cache.zip https://downloads.wordpress.org/plugin/redis-cache.${REDIS_CACHE_VERSION}.zip; \
	unzip /tmp/redis-cache.zip; \
	rm -rf /tmp/redis-cache.zip; \
	wget -O /tmp/wp-native-php-sessions.zip https://downloads.wordpress.org/plugin/wp-native-php-sessions.${PHP_NATIVE_SESSION_VERSION}.zip; \
	unzip /tmp/wp-native-php-sessions.zip; \
	rm -rf /tmp/wp-native-php-sessions.zip;

### Main line
FROM php:7.4-fpm

ENV IMAGICK_VERSION=3.7.0

# Install GhostScript
RUN apt update -y && \
	apt upgrade -y && \
	apt autoremove -y && \
	apt install -y -q --no-install-recommends ghostscript libfreetype6-dev libicu-dev libjpeg-dev libmagickwand-dev libpng-dev libwebp-dev libzip-dev
# Install PHP modules
RUN set -ex; \
	docker-php-ext-configure gd	--with-freetype --with-jpeg --with-webp; \
	docker-php-ext-install -j "$(nproc)" bcmath exif gd intl mysqli zip pdo_mysql; \
	pecl install imagick-${IMAGICK_VERSION}; \
	pecl -q install -o -n -f --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no" enable-redis-msgpack="no" enable-redis-lz4="no" with-liblz4="no"' redis; \
	rm -r /tmp/pear; \
	docker-php-ext-enable imagick redis opcache;
# Install Nginx
COPY --from=builder /etc/nginx /etc/nginx
RUN ln -s /etc/nginx/sbin/nginx /usr/sbin/nginx
# IonCube
COPY --from=builder /tmp/ioncube_loader.so /tmp/ioncube_loader.so
RUN mv /tmp/ioncube_loader.so `php-config --extension-dir` && \
	docker-php-ext-enable ioncube_loader
# Prepare www docs
RUN usermod -a -G www-data www-data && \
  chown -R www-data:www-data /var/www && \
  chmod 2775 /var/www
# Install WP
COPY --from=builder /tmp/wordpress/ /var/www/html/
# Remove default themes, plugins
RUN rm -rf /var/www/html/wp-content/themes/twentytwentyone && \
  rm -rf /var/www/html/wp-content/themes/twentytwentytwo && \
  # rm -rf /var/www/html/wp-content/plugins/akismet && \
  rm -rf /var/www/html/wp-content/plugins/hello.php
# Install object-cache
COPY --from=builder /tmp/redis-cache /var/www/html/wp-content/plugins/redis-cache
COPY --from=builder /tmp/redis-cache/includes/object-cache.php /var/www/html/wp-content/object-cache.php
COPY --from=builder /tmp/wp-native-php-sessions /var/www/html/wp-content/plugins/wp-native-php-sessions
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
# # Sample phpinfo
# RUN echo "<?php phpinfo(); ?>" >> /var/www/html/phpinfo.php
RUN chown -R www-data:www-data /var/www/html && \
  find /var/www -type d -exec chmod 2775 {} + && \
  find /var/www -type f -exec chmod 0664 {} +
## Config NginX
COPY resources/nginx.conf /etc/nginx/conf/nginx.conf
COPY resources/nginx-server.conf /etc/nginx/conf.d/default.conf
## Config PHP-FPM
# Create folder for unix sock
RUN mkdir -p /run/php-fpm
# Config nginx and php-fpm
COPY resources/www.conf /usr/local/etc/php-fpm.d/www.conf
## Config php.ini
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN sed -i s/'error_reporting = E_ALL'/'error_reporting = E_ALL \& \~E_NOTICE '/g /usr/local/etc/php/php.ini
RUN sed -i s/'disable_functions ='/'disable_functions = error_reporting'/g /usr/local/etc/php/php.ini
RUN sed -i s/';fastcgi.logging = 0'/'fastcgi.logging = off'/g /usr/local/etc/php/php.ini
# Default listen on 9000 ==> remove to use unix sock 
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.backup
# Disable defaul config
RUN mv /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf.backup

# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
