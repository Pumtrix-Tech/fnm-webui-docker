# syntax=docker/dockerfile:1

ARG FNMWEBUI_VERSION="3.0.1"
ARG ALPINE_VERSION="3.17"

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3
COPY --from=yasu / /
RUN apk --update --no-cache add \
    busybox-extras \
    acl \
    bash \
    ca-certificates \
    coreutils \
    curl \
    file \
    git \
    libcap-utils \
    mariadb-client \
    nginx \
    openssl \
    openssh-client \
    php81 \
    php81-cli \
    php81-ctype \
    php81-curl \
    php81-dom \
    php81-fileinfo \
    php81-fpm \
    php81-gd \
    php81-gmp \
    php81-json \
    php81-ldap \
    php81-mbstring \
    php81-mysqlnd \
    php81-opcache \
    php81-openssl \
    php81-pdo \
    php81-pdo_mysql \
    php81-pecl-memcached \
    php81-pear \
    php81-phar \
    php81-posix \
    php81-session \
    php81-simplexml \
    php81-sockets \
    php81-tokenizer \
    php81-xml \
    php81-xmlwriter \
    php81-zip \
    runit \
    shadow \
    tzdata \
    util-linux \
  && apk --update --no-cache add -t build-dependencies \
    build-base \
    make \
    mariadb-dev \
    musl-dev \
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && apk del build-dependencies \
  && rm -rf /var/www/* /tmp/*

ENV FNMWEBUI_PATH="/opt/fnm-webui" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN addgroup -g ${PGID} fnmwebui \
  && adduser -D -h /home/fnmwebui -u ${PUID} -G fnmwebui -s /bin/sh -D fnmwebui

WORKDIR ${FNMWEBUI_PATH}
ARG FNMWEBUI_VERSION
RUN apk --update --no-cache add -t build-dependencies \
    build-base \
    linux-headers \
    musl-dev \
  && git clone --depth=1 --branch ${FNMWEBUI_VERSION} https://github.com/Pumtrix-Tech/fnm-webui.git . \
  && COMPOSER_CACHE_DIR="/tmp" composer install --no-dev --no-interaction --no-ansi \
  && chown -R nobody:nogroup ${FNMWEBUI_PATH} \
  && apk del build-dependencies \
  && rm -rf .git \
    doc/ \
    tests/ \
    /tmp/*

COPY rootfs /

EXPOSE 8000/tcp

ENTRYPOINT [ "/init" ]
