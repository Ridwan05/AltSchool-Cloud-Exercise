FROM php:8.1-fpm-alpine

RUN docker-php-ext-install pdo_mysql sockets
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY ./laravel /laravel
WORKDIR /laravel
RUN chown -hR www-data .
RUN composer install

