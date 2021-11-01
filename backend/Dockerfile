FROM php:8.0.5-fpm-alpine

WORKDIR /app

RUN set -ex \
	&& apk --no-cache add postgresql-libs postgresql-dev \
	&& docker-php-ext-install pgsql pdo_pgsql \
	&& apk del postgresql-dev

RUN curl -sS https://getcomposer.org/installer​ | php -- \
     --install-dir=/usr/local/bin --filename=composer

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . .

# https://github.com/aschmelyun/docker-compose-laravel/issues/49
RUN apk add shadow && usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN composer install

EXPOSE 8000

CMD php artisan serve --host=0.0.0.0 --port=8000
