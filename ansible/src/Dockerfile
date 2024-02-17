FROM nginx:1.25.4-alpine3.18-slim

LABEL maintainer="alvmorapa87@gmail.com"

COPY httpd.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/apache2/.htpasswd

RUN mkdir -p /opt/web
WORKDIR /opt/web

COPY index.html /opt/web/

EXPOSE 8080