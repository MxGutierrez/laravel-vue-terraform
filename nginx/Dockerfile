FROM nginx:1.19.8-alpine

ADD ./nginx/default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /var/www/public

WORKDIR /var/www/public

COPY ./backend/public/ .
