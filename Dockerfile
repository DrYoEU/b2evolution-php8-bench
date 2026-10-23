ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-apache
# Extensions matching a typical b2evolution production host (gd, mysqli, mbstring, zip, intl, apcu, exif).
# imap: left PHP core in 8.4, installed from PECL — b2evolution uses it for returned-mail processing (cron) and post-by-mail.
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd mysqli mbstring zip intl apcu exif imap opcache \
 && a2enmod rewrite headers \
 && sed -i 's#/var/www/html#/var/www/html#; s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
 && mkdir -p /var/log/bench && chown www-data:www-data /var/log/bench
