ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache
# Extensions matching a typical b2evolution production host (gd, mysqli, mbstring, zip, intl, apcu, exif).
# imap left out on purpose: removed from core in PHP 8.4, b2evolution only uses it for two optional features.
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd mysqli mbstring zip intl apcu exif opcache \
 && a2enmod rewrite headers \
 && sed -i 's#/var/www/html#/var/www/html#; s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
 && mkdir -p /var/log/bench && chown www-data:www-data /var/log/bench
