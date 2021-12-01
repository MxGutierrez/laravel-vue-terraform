FROM php:8.0.5-fpm-alpine

WORKDIR /var/www

RUN set -ex \
	&& apk --no-cache add postgresql-libs postgresql-dev \
	&& docker-php-ext-install pgsql pdo_pgsql \
	&& apk del postgresql-dev

RUN curl -sS https://getcomposer.org/installer​ | php -- \
	--install-dir=/usr/local/bin --filename=composer

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# https://www.digitalocean.com/community/tutorials/how-to-set-up-laravel-nginx-and-mysql-with-docker-compose

COPY --chown=www-data:www-data . .

RUN chmod +x ./startup.sh

# https://laravel.com/docs/master/deployment#autoloader-optimization
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

EXPOSE 9000

CMD ["./startup.sh"]