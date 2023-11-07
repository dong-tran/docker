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
RUN apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/debian `lsb_release -cs` nginx" | \
  tee /etc/apt/sources.list.d/nginx.list
RUN echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | \
  tee /etc/apt/preferences.d/99nginx
RUN apt update -y && apt install -y nginx
RUN apt install -y -q ghostscript
# Install php-redis
RUN pecl -q install -o -n -f --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no" enable-redis-msgpack="no" enable-redis-lz4="no" with-liblz4="no"' redis && \
  rm -rf /tmp/pear && \
  docker-php-ext-enable redis
# Create folder for unix sock
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN mkdir -p /run/php-fpm
# Config nginx and php-fpm
COPY resources/nginx.conf /etc/nginx/conf.d/default.conf
COPY resources/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.backup
RUN mv /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf.backup
# Sample index
# COPY resources/phpinfo.php /var/www/html/phpinfo.php
# Prepare www docs
RUN groupadd www && \
  usermod -a -G www nginx && \
  chown -R nginx:www /var/www && \
  chmod 2775 /var/www
# Install WP
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/wordpress-6.2.3.tar.gz && \
  tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1 && \
  rm -rf /tmp/wordpress.tar.gz
COPY resources/wp-config-docker.php /var/www/html/wp-config.php
RUN chown -R nginx:www /var/www/html && \
  find /var/www -type d -exec chmod 2775 {} + && \
  find /var/www -type f -exec chmod 0664 {} +
# Entrypoint
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
