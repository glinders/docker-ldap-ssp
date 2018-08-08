#FROM php:5.6-apache
FROM php:7.2-apache

MAINTAINER mengzhaopeng <qiuranke@gmail.com>

ENV SSP_PACKAGE ltb-project-self-service-password-1.0.tar.gz

# Install the software that ssp environment requires
RUN apt-get update \
    && apt-get install -y libmcrypt-dev libldap2-dev libmagickwand-dev --no-install-recommends \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap gettext zip \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -rf /var/lib/apt/lists/*

# Install ssp
RUN curl -L https://ltb-project.org/archives/${SSP_PACKAGE} \
    -o ssp.tar.gz && tar xf ssp.tar.gz -C /var/www/html && rm -f ssp.tar.gz \
    && mv /var/www/html/ltb-project-self-service-password-1.0 /var/www/html/ssp

# ldap server info
ENV LDAP_URL "ldap://ldap:389"
ENV LDAP_BINDDN "cn=admin,dc=example,dc=com"
ENV LDAP_BINDPW "changeme"
ENV LDAP_BASE "dc=example,dc=com"

# ltb configuration file info
ENV PWD_MIN_LENGTH 0
ENV PWD_MAX_LENGTH 0
ENV PWD_MIN_LOWER 0
ENV PWD_MIN_UPPER 0
ENV PWD_MIN_DIGIT 0
ENV PWD_MIN_SPECIAL 0
ENV PWD_SPECIAL_CHARS "^a-zA-Z0-9"
ENV MAIL_FROM "admin@example.com"
ENV NOTIFY_ON_CHANGE false
ENV SMTP_AUTH true
ENV SMTP_HOST localhost
ENV SMTP_USER smtpuser
ENV SMTP_PASS smtppass

# This is where configuration goes
ADD assets/config.inc.php /var/www/html/ssp/conf/config.inc.php

ADD assets/apache2.sh /etc/service/apache2/run

ADD ./ldap-account-manager-6.4.tar.bz2 /
RUN cd /ldap-account-manager-6.4 && ./configure --with-web-root=/var/www/html/lam \
    --with-httpd-user=1000 --with-httpd-group=1000 \
    && make install \
    && cp /var/www/html/lam/config/config.cfg.sample /var/www/html/lam/config/config.cfg \
    && chown -R www-data:www-data /var/www/html/lam /usr/local/lam/var
ADD ./lam.conf /var/www/html/lam/config/lam.conf
RUN chown www-data:www-data /var/www/html/lam/config/lam.conf

EXPOSE 80

CMD ["/etc/service/apache2/run"]
