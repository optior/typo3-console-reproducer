FROM mysql:5.7.38 AS mysql


FROM composer:2.4.0 AS composer


FROM php:7.4.29-apache AS base
WORKDIR /var/www/html
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libxml2-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        zlib1g-dev \
        ghostscript \
        graphicsmagick \
        locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    docker-php-ext-configure gd --with-libdir=/usr/include/ --with-jpeg --with-freetype && \
    docker-php-ext-install -j$(nproc) mysqli soap gd zip opcache intl && \
    a2enmod rewrite && \
    sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
    apt-get clean && \
    apt-get -y purge \
        libxml2-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* /usr/src/*
COPY docker/typo3.ini /usr/local/etc/php/conf.d/typo3.ini
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["apache2-foreground"]


FROM base AS build-base
ENV COMPOSER_HOME /var/www/composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt-get update && \
    apt-get install -y --no-install-recommends git unzip && \
    mkdir $COMPOSER_HOME && \
    chown www-data:www-data -R $COMPOSER_HOME && \
    rm -rf /var/lib/apt/lists/* /usr/src/*


FROM build-base AS build
COPY --chown=www-data:www-data composer.json composer.lock /var/www/html/
RUN composer install --no-interaction --no-dev


FROM base AS production
USER www-data
COPY --chown=www-data:www-data --from=build /var/www/html/ /var/www/html/
COPY --chown=www-data:www-data config/ /var/www/html/config/
COPY --chown=www-data:www-data public/ /var/www/html/public/
COPY --chown=www-data:www-data docker/SimpleFileBackend.php /var/www/html/public/typo3/sysext/core/Classes/Cache/Backend/SimpleFileBackend.php

