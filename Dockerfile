FROM docker.io/nginx:stable-alpine
# Set Piwigo and PHP Version
ARG PHP_VERSION="83"
ARG PIWIGO_VERSION="15.6.0"

RUN apk add --update --no-cache \
	# PHP dependencies
	php${PHP_VERSION} \
	php${PHP_VERSION}-apcu \
	php${PHP_VERSION}-bcmath \
	php${PHP_VERSION}-bz2 \
	php${PHP_VERSION}-calendar \
	php${PHP_VERSION}-ctype \
	php${PHP_VERSION}-curl \
	php${PHP_VERSION}-dom \
	php${PHP_VERSION}-exif \
	php${PHP_VERSION}-ffi \
	php${PHP_VERSION}-fileinfo \
	php${PHP_VERSION}-fpm \
	php${PHP_VERSION}-ftp \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-gettext \
	php${PHP_VERSION}-gmp \
	php${PHP_VERSION}-iconv \
	php${PHP_VERSION}-imap \
	php${PHP_VERSION}-json \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-mysqli \
	php${PHP_VERSION}-mysqlnd \
	php${PHP_VERSION}-odbc \
	php${PHP_VERSION}-openssl \
	php${PHP_VERSION}-pcntl \
	php${PHP_VERSION}-pdo \
	php${PHP_VERSION}-pdo_dblib \
	php${PHP_VERSION}-pdo_mysql \
	php${PHP_VERSION}-pdo_odbc \
	php${PHP_VERSION}-pdo_pgsql \
	php${PHP_VERSION}-pdo_sqlite \
	php${PHP_VERSION}-phar \
	php${PHP_VERSION}-posix \
	php${PHP_VERSION}-session \
	php${PHP_VERSION}-shmop \
	php${PHP_VERSION}-simplexml \
	php${PHP_VERSION}-soap \
	php${PHP_VERSION}-sockets \
	php${PHP_VERSION}-sodium \
	php${PHP_VERSION}-sysvmsg \
	php${PHP_VERSION}-sysvsem \
	php${PHP_VERSION}-sysvshm \
	php${PHP_VERSION}-tokenizer \
	php${PHP_VERSION}-xml \
	php${PHP_VERSION}-xmlreader \
	php${PHP_VERSION}-xmlwriter \
	php${PHP_VERSION}-xsl \
	php${PHP_VERSION}-zip \
	# External dependencies
	exiftool ffmpeg mediainfo ghostscript findutils \
	# Imagemagick
	imagemagick \
	imagemagick-heic \
	imagemagick-jpeg \
	imagemagick-jxl \
	imagemagick-pango \
	imagemagick-pdf \
	imagemagick-raw \
	imagemagick-svg \
	imagemagick-tiff \
	imagemagick-webp \
	# Supervisor to run PHP-FPM and NGINX
	supervisor

# Configure PHP-FPM (set user to nginx)
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
&& sed -i "s|;listen.group\s*=\s*nobody|listen.group = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
&& sed -i "s|user\s*=\s*nobody|user = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
&& sed -i "s|group\s*=\s*nobody|group = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf

# Configure and set the php version of supervisor
COPY ./config/supervisord.conf /etc/supervisord.conf
RUN sed -i "s/PHP-VERSION/${PHP_VERSION}/" /etc/supervisord.conf

# Configure NGINX, fetch and extract piwigo
COPY ./config/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/www/html/piwigo /var/www/source/
RUN chown nginx:nginx /var/www/html/ /var/www/source/
USER nginx
RUN curl -o /tmp/piwigo.zip https://piwigo.org/download/dlcounter.php?code=${PIWIGO_VERSION}
RUN unzip /tmp/piwigo.zip -d /var/www/source/
RUN rm -rf /tmp/piwigo.zip

# Bind port 80
EXPOSE 80

# Copy script and start supervisord
USER root
COPY --chmod=0755 "./config/entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/ash","-c"]
CMD ["/usr/local/bin/entrypoint.sh"]