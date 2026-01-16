FROM wordpress:php8.2-apache

# Copy config
COPY wp-config.php /var/www/html/wp-config.php
COPY .htaccess /var/www/html/.htaccess

# Copy code custom
COPY wp-content /var/www/html/wp-content

RUN chown -R www-data:www-data /var/www/html
