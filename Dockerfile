ARG ALPINE_VERSION=3.12
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Alessandro Tesi <alextesi@gmail.com>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 7 based on Alpine Linux."


# Setup document root
WORKDIR /app
RUN cat /etc/apk/repositories
# COPY  config/repositories /etc/apk/repositories

# Install packages and remove default server definition
RUN apk update 
RUN apk upgrade
RUN apk add --no-cache \
  gcc \
  musl-dev \
  make \
  mongo-c-driver \
  curl \
  nginx \
  php7 \
  php7-bcmath \
  php7-bz2 \
  php7-cgi \
  php7-cli \
  php7-common \
  php7-curl \
  php7-dba \
  php7-dev \
  php7-enchant \
  php7-fpm \
  php7-gd \
  php7-gmp \
  php7-imap \
  # php7-interbase \
  php7-intl \
  php7-json \
  php7-ldap \
  php7-mbstring \
  php7-pdo_mysql \
  php7-odbc \
  php7-opcache \
  php7-pear \
  php7-dev \
  php7-pdo_pgsql \
  php7-phpdbg \
  php7-pspell \
  # php7-pecl-mongodb \
  # php7-readline \
  php7-snmp \
  php7-soap \
  php7-pdo_sqlite \
  # php7-sybase \
  php7-tidy \
  php7-xml \
  php7-xmlrpc \
  php7-xsl \
  php7-zip \
  php7-apcu \
  # php-mongodb \
  php7-curl \
  supervisor \
  && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-install \
  nodejs \
  && npm update -g npm \
  && composer self-update \
  && docker-run-bootstrap \
  && docker-image-cleanup

RUN pecl install mongodb

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /app /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /app/

# Expose the port nginx is reachable on
EXPOSE 80 443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
