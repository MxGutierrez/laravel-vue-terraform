#!/bin/sh

php artisan config:cache
exec php-fpm