FROM nginx

RUN apt-get update -y
RUN apt-get upgrade -y --force-yes

RUN apt-get install curl wget git php7 php7-bz2 php7-mcrypt php7-mysql php7-curl php7-gd php7-intl php7-mcrypt php7-memcache php7-sqlite php7-pgsql php7-fpm gdal-bin net-tools npm python gdal-bin python-pip zip -y

RUN mkdir mapbender
RUN git clone -b release/3.0.64 https://github.com/mapbender/mapbender-starter.git mapbender
RUN cd mapbender; git submodule update --init --recursive
RUN cp mapbender/application/app/config/parameters.yml.dist mapbender/application/app/config/parameters.yml
RUN curl -sS https://getcomposer.org/installer | php
RUN ./composer.phar install -d mapbender/application/
RUN mapbender/application/app/console doctrine:database:create
RUN mapbender/application/app/console doctrine:schema:create
RUN mapbender/application/app/console assets:install mapbender/application/web/
RUN mapbender/application/app/console fom:user:resetroot --username=root --password=root --email=root@root.de -n
RUN mapbender/application/app/console doctrine:fixtures:load --fixtures=mapbender/application/mapbender/src/Mapbender/CoreBundle/DataFixtures/ORM/Epsg/ --append
RUN rm -rf mapbender/application/app/cache/* mapbender/application/app/logs/*
RUN chown www-data.www-data mapbender/application/app/cache mapbender/application/app/logs

RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php7/fpm/php-fpm.conf
RUN sed -e 's/;listen\.owner/listen.owner/' -i /etc/php5/fpm/pool.d/www.conf
RUN sed -e 's/;listen\.group/listen.group/' -i /etc/php5/fpm/pool.d/www.conf
RUN sed -e 's/listen = .var.run.php7-fpm.sock/listen = 127.0.0.1:9000/' -i /etc/php7/fpm/pool.d/www.conf
RUN sed -e 's/;catch_workers_output/catch_workers_output/' -i /etc/php5/fpm/pool.d/www.conf

COPY default.conf /etc/nginx/conf.d/default.conf

CMD /etc/init.d/php5-fpm restart; nginx -g 'daemon off;'
