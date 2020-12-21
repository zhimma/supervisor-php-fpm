# 从官方基础版本构建
FROM php:7.3.8-fpm-alpine

# 参考地址：https://learnku.com/articles/31344
# 参考地址：https://github.com/lework/Docker-php-fpm/blob/master/Dockerfile
# 参考地址：https://github.com/tcyfree/lnmp-docker/blob/master/supervisor/conf.d/supervisord.conf

ARG WORKSPACE=/data/www
ENV WORKSPACE=${WORKSPACE} \
    TIMEZONE=Asia/Shanghai  \
    MAX_INPUT_VARS=2000\ 
    POST_MAX_SIZE=200M\
    UPLOAD_MAX_FILESIZE=200M\
    SUPERCRONIC=supercronic-linux-amd64


# 更新为国内镜像
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk --update -t --no-cache add tzdata tzdata \
    && ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    \
    && apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    autoconf \
    libcurl \
    curl \
    && apk add --no-cache augeas-dev \
    musl-dev \
    linux-headers \
    libmcrypt-dev \
    libpng-dev \
    libzip-dev\
    zlib-dev\
    icu-dev \
    libpq \
    libressl-dev \
    libxslt-dev \
    libffi-dev \
    freetype-dev \
    #libmemcached \
    #libmemcached-dev \
    libjpeg-turbo-dev \
    vim \
    bash \
    bash-completion \
    supervisor \
    procps \
    && docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure zip --with-libzip \  
    && docker-php-ext-install iconv pdo_mysql mysqli gd mbstring bcmath exif intl xsl json soap dom zip opcache pcntl \
    #&& pecl install memcached \
    #&& pecl install mongodb \
    && pecl install redis \
    \
    && docker-php-source delete \
    && apk del --no-network .build-deps \
    && rm -rf /tmp/pear/* /var/cache/apk/* ~/.pearrc \
    && docker-php-ext-enable redis \
    \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -i 's#;date.timezone =#date.timezone = ${TIMEZONE}#g' "$PHP_INI_DIR/php.ini" \
    && sed -i 's#; max_input_vars = 1000#max_input_vars = ${MAX_INPUT_VARS}#g' "$PHP_INI_DIR/php.ini" \
    && sed -i 's#post_max_size = 8M#post_max_size = ${POST_MAX_SIZE}#g' "$PHP_INI_DIR/php.ini" \
    && sed -i 's#upload_max_filesize = 2M#upload_max_filesize = ${UPLOAD_MAX_FILESIZE}#g' "$PHP_INI_DIR/php.ini" \
    && sed -i 's#;pm.status_path = /status#pm.status_path = /fpm-status#g' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's#;ping.path = /ping#ping.path = /fpm-ping#g' /usr/local/etc/php-fpm.d/www.conf \
    \
    && mkdir -p ${WORKSPACE} /data/www/run  \
    \
    && curl -O https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && apk del tzdata \
    && rm -rf /var/cache/apk/* 
    
WORKDIR ${WORKSPACE}
COPY ./supervisord.conf /etc/supervisord/
COPY ./entrypoint.sh /data/www/run/
COPY ./crontabs/www-data /var/spool/cron/crontabs/
COPY ./supercronic-linux-amd64 /usr/local/bin/${SUPERCRONIC}

RUN chmod +x "/usr/local/bin/${SUPERCRONIC}" \ 
  && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
  && mkdir -p /var/log/cron \
  && chmod +x /data/www/run/entrypoint.sh

#COPY ./src ${WORKSPACE}
#RUN composer install --no-dev --no-scripts

ENTRYPOINT ["/data/www/run/entrypoint.sh"]
