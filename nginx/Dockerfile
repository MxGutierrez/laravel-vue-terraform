FROM nginx:1.19.8-alpine

ADD ./nginx/templates /etc/nginx/templates

RUN mkdir -p /var/www/public

WORKDIR /var/www/public

COPY ./backend/public/ .

CMD ["nginx", "-g", "daemon off;"]