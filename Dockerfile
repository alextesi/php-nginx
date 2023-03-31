ARG ALPINE_VERSION=3.12
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Alessandro Tesi <alextesi@gmail.com>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 7 based on Alpine Linux."


# Setup document root
WORKDIR /app
RUN cat /etc/apk/repositories
# COPY  config/repositories /etc/apk/repositories

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install packages and remove default server definition
RUN apk update 
RUN apk upgrade
RUN apk add --no-cache \
  vim  mc \
  gcc \
  musl-dev \
  make \
  mongo-c-driver \
  curl \
  nginx \
  bash bash-doc bash-completion \
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
  php7-pdo_pgsql \
  php7-phar \
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
  supervisor \
  nodejs \
  npm 

RUN npm update -g npm 
RUN composer self-update

RUN pecl install mongodb


# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/nginx/fpm-pool.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php/php-fpm.d/www.conf
COPY config/php.ini /etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
#RUN chown -R nobody.nobody /app /run /var/lib/nginx /var/log/nginx 

# Switch to use a non-root user from here on
ARG user=application
ARG group=application
ARG uid=1000
ARG gid=1000
RUN addgroup -g ${gid} ${group}
# -s /bin/bash -h /config/ssh-user
RUN adduser -D -u ${uid} -G ${group} ${user}
#RUN "$user ALL=(ALL) ALL" > /etc/sudoers.d/$user && chmod 0440 /etc/sudoers.d/$user

# Switch to user
#USER ${uid}:${gid}

# Add application
#COPY --chown=application src/ /app/

# Expose the port nginx is reachable on
EXPOSE 80 443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/ping
