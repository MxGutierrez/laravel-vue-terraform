FROM php:8.0.5-fpm-alpine

WORKDIR /var/www

RUN set -ex \
	&& apk --no-cache add postgresql-libs postgresql-dev \
	&& docker-php-ext-install pgsql pdo_pgsql \
	&& apk del postgresql-dev

RUN curl -sS https://getcomposer.org/installer​ | php -- \
	--install-dir=/usr/local/bin --filename=composer

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

EXPOSE 9000

CMD ["php-fpm"]