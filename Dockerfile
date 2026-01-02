FROM docker.io/alpine:latest

# Set Piwigo and PHP Version
ARG PHP_VERSION="84"
ARG PIWIGO_VERSION="16.2.0"
ARG BUILD_VERSION=${PIWIGO_VERSION}a

# Install dependencies
RUN apk add --update --no-cache \
	# s6-overlay Nginx and PHP fpm
	s6-overlay nginx php${PHP_VERSION} php${PHP_VERSION}-fpm \
	# PHP dependencies
	php${PHP_VERSION}-bcmath php${PHP_VERSION}-calendar php${PHP_VERSION}-ctype \
	php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-exif \
	php${PHP_VERSION}-ffi php${PHP_VERSION}-fileinfo php${PHP_VERSION}-ftp \
	php${PHP_VERSION}-gd php${PHP_VERSION}-gettext php${PHP_VERSION}-iconv \
	php${PHP_VERSION}-imap php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-mysqli php${PHP_VERSION}-mysqlnd php${PHP_VERSION}-opcache \
	php${PHP_VERSION}-openssl php${PHP_VERSION}-pcntl php${PHP_VERSION}-pdo \
	php${PHP_VERSION}-pdo_mysql php${PHP_VERSION}-phar php${PHP_VERSION}-posix \
	php${PHP_VERSION}-session php${PHP_VERSION}-shmop php${PHP_VERSION}-simplexml \
	php${PHP_VERSION}-sockets php${PHP_VERSION}-sodium php${PHP_VERSION}-sysvmsg \
	php${PHP_VERSION}-sysvsem php${PHP_VERSION}-sysvshm php${PHP_VERSION}-tokenizer \
	php${PHP_VERSION}-xml php${PHP_VERSION}-xmlreader php${PHP_VERSION}-xmlwriter \
	php${PHP_VERSION}-xsl php${PHP_VERSION}-zip \
	# External dependencies
	curl exiftool ffmpeg mediainfo ghostscript findutils tzdata \
	# Imagemagick
	imagemagick imagemagick-heic imagemagick-jpeg imagemagick-jxl imagemagick-pango \
	imagemagick-pdf imagemagick-raw imagemagick-svg imagemagick-tiff imagemagick-webp

# Configure PHP-FPM and NGINX
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
	&& sed -i "s|;listen.group\s*=\s*nobody|listen.group = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
	&& sed -i "s|user\s*=\s*nobody|user = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
	&& sed -i "s|group\s*=\s*nobody|group = nginx|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf
COPY ./config/php.ini /etc/php${PHP_VERSION}/conf.d/piwigo.ini
ENV PHP_VERSION=${PHP_VERSION}
COPY ./config/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/www/html/piwigo /var/www/source/
RUN chown nginx:nginx /var/www/html/ /var/www/source/
EXPOSE 80 

# Fetch, extract and install Piwigo
USER nginx
RUN curl -o /tmp/piwigo.zip https://piwigo.org/download/dlcounter.php?code=${PIWIGO_VERSION}
RUN unzip /tmp/piwigo.zip -d /var/www/source/
RUN rm -rf /tmp/piwigo.zip

# Add Tagging file
RUN printf "Official Piwigo container\nPiwigo ${PIWIGO_VERSION}\nPHP ${PHP_VERSION}\nBuild Version ${BUILD_VERSION}" > /var/www/html/piwigo-docker.info

# Configure s6-overlay
USER root
COPY --chmod=0755 ./config/s6/services/php-fpm/run /etc/services.d/php-fpm/run
COPY --chmod=0755 ./config/s6/services/nginx/run /etc/services.d/nginx/run
COPY --chmod=0755 ./config/s6/cont-init.d/00-timezone /etc/cont-init.d/00-timezone
COPY --chmod=0755 ./config/s6/cont-init.d/10-piwigo-setup /etc/cont-init.d/10-piwigo-setup
ENTRYPOINT ["/init"]