ARG IMG_VERSION=8.1-fpm-alpine3.16
FROM php:${IMG_VERSION}
LABEL Maintainer="Alessandro Tesi <alextesi@gmail.com>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 8 based on Alpine Linux."


# Setup document root
WORKDIR /app
RUN cat /etc/apk/repositories
# COPY  config/repositories /etc/apk/repositories

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install packages and remove default server definition
RUN apk update 
RUN apk upgrade
RUN apk add --no-cache  --repository http://dl-cdn.alpinelinux.org/alpine/edge/community php
RUN php -v 
RUN apk add --no-cache \
autoconf file g++ gcc binutils isl libatomic libc-dev musl-dev make re2c libstdc++ libgcc mpc1 gmp libgomp \
      coreutils \
      freetype-dev \
      libjpeg-turbo-dev \
      libltdl \
      libmcrypt-dev \
      openssl-dev \
        icu-dev \
        ldb-dev libldap openldap-dev \
  vim  mc \
  gcc \
  musl-dev \
  make \
  mongo-c-driver \
  curl \
  nginx \
  bash bash-doc bash-completion \
  supervisor \
  nodejs \
  bzip2-dev \
  gmp-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libxml2-dev \
  libzip-dev \
  imap-dev \
  curl-dev \
  npm \
  #&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure imap --with-imap --with-imap-ssl \
    && docker-php-ext-install imap

# enable xdebug support
# RUN pecl install xdebug 
# RUN docker-php-ext-enable xdebug 

RUN docker-php-ext-install  \
  bcmath \
  bz2 \
  curl \
  dba \
  gmp \
  # interbase \
  intl \
  json \
  ldap \
  mbstring \
  pdo_mysql \
  odbc \
  opcache \
  pdo_pgsql \
  phar \
  pspell \
  # readline \
  snmp \
  soap \
  pdo_sqlite \
  # sybase \
  tidy \
  xml \
  xmlrpc \
  xsl \
  zip 

RUN pecl install apcu igbinary mongodb
RUN docker-php-ext-enable  \
  bcmath \
  bz2 \
  curl \
  dba \
  gd \
  gmp \
  imap \
  # interbase \
  intl \
  json \
  ldap \
  mbstring \
  pdo_mysql \
  odbc \
  opcache \
  pdo_pgsql \
  phar \
  pspell \
  # readline \
  snmp \
  soap \
  pdo_sqlite \
  # sybase \
  tidy \
  xml \
  xmlrpc \
  xsl \
  zip 

RUN npm update -g npm 
RUN composer self-update

# Cleaning up the instlalation
RUN apk del autoconf file g++ gcc binutils isl libatomic libc-dev musl-dev make re2c libstdc++ libgcc binutils-libs mpc1 mpfr3 gmp libgomp \
    && rm -rf /var/cache/apk/*

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/nginx/fpm-pool.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php/php-fpm.d/www.conf
COPY config/02_mongodb.ini /etc/php/conf.d/02_mongodb.ini

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
