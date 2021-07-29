FROM alpine:latest
RUN apk add apache2
RUN echo "<h1>Hello World!</h1>" > /var/www/localhost/htdocs/index.html
ENTRYPOINT ["/usr/sbin/httpd", "-D", "FOREGROUND"]
EXPOSE 80