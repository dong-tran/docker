##### Builder setup needed application
FROM debian:bullseye AS builder

ENV APACHE_VERSION=2.4.58
ARG APR_VERSION=1.7.4
ARG APR_UTIL_VERSION=1.6.3
ARG NGHTTP2_VERSION=1.58.0
ENV PHP_VERSION=7.4
ENV WP_VERSION=6.2.3
ENV REDIS_CACHE_VERSION=2.4.4
ENV PHP_NATIVE_SESSION_VERSION=1.4.2

## Install Apache2
RUN apt update && apt upgrade -y && apt autoremove -y && \
    apt install -y build-essential wget unzip libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libnghttp2-dev libexpat1-dev
WORKDIR /tmp
RUN wget https://dlcdn.apache.org/httpd/httpd-${APACHE_VERSION}.tar.gz && \
	gzip -d httpd-${APACHE_VERSION}.tar.gz && \
  tar xvf httpd-${APACHE_VERSION}.tar
RUN wget https://archive.apache.org/dist/apr/apr-${APR_VERSION}.tar.gz \
	&& tar -xf apr-${APR_VERSION}.tar.gz \
	&& mv apr-${APR_VERSION} httpd-${APACHE_VERSION}/srclib/apr \
	&& rm apr-${APR_VERSION}.tar.gz
RUN wget https://archive.apache.org/dist/apr/apr-util-${APR_UTIL_VERSION}.tar.gz \
	&& tar -xf apr-util-${APR_UTIL_VERSION}.tar.gz \
	&& mv apr-util-${APR_UTIL_VERSION} httpd-${APACHE_VERSION}/srclib/apr-util \
	&& rm apr-util-${APR_UTIL_VERSION}.tar.gz
RUN wget https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz \
	&& tar -xf nghttp2-${NGHTTP2_VERSION}.tar.gz \
	&& rm nghttp2-${NGHTTP2_VERSION}.tar.gz \
	&& cd nghttp2-${NGHTTP2_VERSION} \
	&& ./configure \
	&& make \
	&& make install \
	&& cd -
WORKDIR /tmp/httpd-${APACHE_VERSION}
RUN set -ex; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
	--quiet \
	--prefix=/etc/httpd \
	--build="$gnuArch" \
	--enable-fpm \
	--with-mpm=worker \
	--without-ssl \
	--enable-worker=static \
	--enable-rewrite=static \
	--enable-expires=static \
	--enable-headers=static \
	--enable-proxy=static \
	--enable-proxy-fcgi=static \
	--enable-buffer=static \
	--enable-slotmem-shm=static \
	--enable-heartmonitor=static \
	--enable-watchdog=static \
	--enable-alias=static; \
	make; \
	make install;
RUN sed -i s/'User daemon'/'User www-data'/g /etc/httpd/conf/httpd.conf
RUN sed -i s/'Group daemon'/'Group www-data'/g /etc/httpd/conf/httpd.conf
RUN sed -i 's#ErrorLog "logs/error_log"#ErrorLog "/dev/stderr"#g' /etc/httpd/conf/httpd.conf
RUN sed -i s/'" combined'/' %{ms}T" combined'/g /etc/httpd/conf/httpd.conf
RUN sed -i '/CustomLog "logs\/access_log" common/c \
    SetEnvIf Request_URI "^/robots\.txt$" dontlog\n\
    SetEnvIf Request_URI "^/.*\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf|webp|woff2)$" dontlog\n\
    SetEnvIf Request_URI "/favicon\.ico$" dontlog\n\
    CustomLog /dev/stdout combined env=!dontlog' /etc/httpd/conf/httpd.conf
RUN sed -i 's/#Include conf\/extra\/httpd-mpm\.conf/Include conf\/extra\/httpd-mpm\.conf/' /etc/httpd/conf/httpd.conf
RUN sed -i 's/#Include conf\/extra\/httpd-default\.conf/Include conf\/extra\/httpd-default\.conf/' /etc/httpd/conf/httpd.conf
RUN sed -i '/Include conf\/extra\/httpd-default.conf/a \
		Include conf\/extra\/httpd-www.conf' /etc/httpd/conf/httpd.conf
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
# IonCube
COPY --from=builder /tmp/ioncube_loader.so /tmp/ioncube_loader.so
RUN mv /tmp/ioncube_loader.so `php-config --extension-dir` && \
	docker-php-ext-enable ioncube_loader
# Install Apache
COPY --from=builder /etc/httpd /etc/httpd
RUN ln -s /etc/httpd/bin/httpd /usr/bin/httpd && \
	ln -s /etc/httpd/bin/apachectl /usr/bin/apachectl
RUN mkdir /var/run/httpd;
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
COPY src/ /var/www/html/
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
# # Sample phpinfo
RUN echo "<?php phpinfo(); ?>" >> /var/www/html/phpinfo.php
RUN chown -R www-data:www-data /var/www/html && \
  find /var/www -type d -exec chmod 2775 {} + && \
  find /var/www -type f -exec chmod 0664 {} +
## Config 
# COPY resources/httpd.conf /etc/httpd/conf/httpd.conf
COPY resources/apache2.conf /etc/httpd/conf/extra/httpd-www.conf
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
CMD [ "httpd", "-D", "FOREGROUND" ]
