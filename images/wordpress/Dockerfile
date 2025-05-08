FROM wordpress:6.4-apache

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp

# Set PHP config overrides
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini \
 && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/uploads.ini \
 && echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/uploads.ini \
 && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini

