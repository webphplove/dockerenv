# @description php 7.1 image base on the alpine 3.7 镜像更小，构建完成只有46M
#                       some information
# ------------------------------------------------------------------------------------
# @link https://hub.docker.com/_/alpine/      alpine image
# @link https://hub.docker.com/_/php/         php image
# @link https://github.com/docker-library/php php dockerfiles
# ------------------------------------------------------------------------------------
# @build-example docker build . -f alphp-cli.Dockerfile -t alphp:cli
#

FROM alphp:base
LABEL maintainer="inhere <cloud798@126.com>" version="1.0"

##
# ---------- env settings ----------
##
ARG add_user=www

ENV HIREDIS_VERSION=0.13.3 \
    PHALCON_VERSION=3.3.1 \
    SWOOLE_VERSION=2.0.12 \
    MONGO_VERSION=1.3.4

##
# install php extensions
##

# 下载太慢，所以推荐先下载好
# COPY services/php/deps/hiredis-${HIREDIS_VERSION}.tar.gz hiredis.tar.gz
# COPY services/php/deps/swoole-${SWOOLE_VERSION}.tar.gz swoole.tar.gz
# COPY services/php/deps/cphalcon-${PHALCON_VERSION}.tar.gz cphalcon.tar.gz
# COPY services/php/deps/mongodb-${MONGO_VERSION}.tgz mongodb.tgz
RUN set -ex \
        && cd /tmp \
        && curl -SL "https://github.com/redis/hiredis/archive/v${HIREDIS_VERSION}.tar.gz" -o hiredis.tar.gz \
        && curl -SL "https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz" -o swoole.tar.gz \
        # && curl -SL "https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz" -o cphalcon.tar.gz \
        && curl -SL "http://pecl.php.net/get/mongodb-${MONGO_VERSION}.tgz" -o mongodb.tgz \
        && ls -alh \
        && apk update \
        && apk add --no-cache --virtual .phpize-deps \
        $PHPIZE_DEPS \
        # for mongodb ext
        openssl-dev \
        # for swoole ext
        libaio linux-headers libaio-dev \

        # php extension: mongodb
        && pecl install ./mongodb.tgz \
        && echo "extension=mongodb.so" > /etc/php7/conf.d/20_mongodb.ini  \

        # php extension: phalcon framework
        # && tar -xf cphalcon.tar.gz \
        # && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
        # && cd cphalcon-${PHALCON_VERSION}/build \
        # # in alpine no bash shell, so change to 'sh install'
        # # && ./install \
        # && sh install \
        # && cp ../tests/_ci/phalcon.ini $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}') \
        # && cd ../../ \
        # && rm -r cphalcon-${PHALCON_VERSION} \

        # hiredis - redis C client, provide async operate support for Swoole
        # && wget -O hiredis.tar.gz -c https://github.com/redis/hiredis/archive/v${HIREDIS_VERSION}.tar.gz \
        && cd /tmp \
        && tar -zxvf hiredis.tar.gz \
        && cd hiredis-${HIREDIS_VERSION} \
        && make -j && make install \

        # php extension: swoole
        && cd /tmp \
        && mkdir -p swoole \
        && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
        && rm swoole.tar.gz \
        && ( \
            cd swoole \
            && phpize \
            && ./configure --enable-async-redis --enable-mysqlnd --enable-coroutine \
            && make -j$(nproc) && make install \
        ) \
        && rm -r swoole \
        && echo "extension=swoole.so" > /etc/php7/conf.d/20_swoole.ini \
        && apk del .phpize-deps \
        && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \

        # ---------- some config work ----------
        # - ensure 'www' user exists
        && addgroup -S ${add_user} \
        && adduser -D -S -G ${add_user} ${add_user} \

        # - create user dir
        && mkdir -p /data/tmp \
        && chown -R ${add_user}:${add_user} /data/tmp \

        && echo -e "\033[42;37m Build Completed :).\033[0m\n"

EXPOSE 9501
VOLUME ["/var/www", "/data/tmp"]
WORKDIR "/var/www"
