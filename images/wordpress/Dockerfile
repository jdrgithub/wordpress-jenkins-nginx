FROM wordpress:6.4-apache

# Copy custom PHP config
COPY docker/php/php.ini /usr/local/etc/php/conf.d/

# Copy wp-config.php
COPY wp-config.php /var/www/html

# Copy child theme
COPY wp-content/themes/astra-child/ /var/www/html/wp-content/themes/astra-child/

# Astra Pro plugin (if you're bundling it)
COPY wp-content/plugins/astra-addon/ /var/www/html/wp-content/plugins/astra-addon/

# Permissions
RUN chown -R www-data:www-data /var/www/html/wp-content

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp
