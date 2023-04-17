#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(<"${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

TZ=${TZ:-UTC}

MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
FPM_PM_MAX_CHILDREN=${FPM_PM_MAX_CHILDREN:-15}
FPM_PM_START_SERVERS=${FPM_PM_START_SERVERS:-2}
FPM_PM_MIN_SPARE_SERVERS=${FPM_PM_MIN_SPARE_SERVERS:-1}
FPM_PM_MAX_SPARE_SERVERS=${FPM_PM_MAX_SPARE_SERVERS:-6}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
LISTEN_IPV6=${LISTEN_IPV6:-true}
REAL_IP_FROM=${REAL_IP_FROM:-"0.0.0.0/32"}
REAL_IP_HEADER=${REAL_IP_HEADER:-"X-Forwarded-For"}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}
MAX_INPUT_VARS=${MAX_INPUT_VARS:-1000}

MEMCACHED_PORT=${MEMCACHED_PORT:-11211}

DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-fnmwebui}
DB_USER=${DB_USER:-fnmwebui}
DB_TIMEOUT=${DB_TIMEOUT:-30}

FNMWEBUI_BASE_URL=${FNMWEBUI_BASE_URL:-/}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} >/etc/timezone

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
  -e "s/@FPM_PM_MAX_CHILDREN@/$FPM_PM_MAX_CHILDREN/g" \
  -e "s/@FPM_PM_START_SERVERS@/$FPM_PM_START_SERVERS/g" \
  -e "s/@FPM_PM_MIN_SPARE_SERVERS@/$FPM_PM_MIN_SPARE_SERVERS/g" \
  -e "s/@FPM_PM_MAX_SPARE_SERVERS@/$FPM_PM_MAX_SPARE_SERVERS/g" \
  /tpls/etc/php81/php-fpm.d/www.conf >/etc/php81/php-fpm.d/www.conf

echo "Setting PHP INI configuration..."
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php81/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php81/php.ini
sed -i "s|;max_input_vars.*|max_input_vars = ${MAX_INPUT_VARS}|g" /etc/php81/php.ini

# OpCache
echo "Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php81/conf.d/opcache.ini >/etc/php81/conf.d/opcache.ini

# Nginx
echo "Setting Nginx configuration..."
sed -e "s#@UPLOAD_MAX_SIZE@#$UPLOAD_MAX_SIZE#g" \
  -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
  -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
  -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
  /tpls/etc/nginx/nginx.conf >/etc/nginx/nginx.conf

if [ "$LISTEN_IPV6" != "true" ]; then
  sed -e '/listen \[::\]:/d' -i /etc/nginx/nginx.conf
fi

rm -rf ${FNMWEBUI_PATH}/logs
rm -f ${FNMWEBUI_PATH}/config.d/*
mkdir -p /etc/logrotate.d
touch /etc/logrotate.d/fnmwebui

echo "Setting FNM WebUI configuration..."

# Env file
if [ -z "$DB_HOST" ]; then
  echo >&2 "ERROR: DB_HOST must be defined"
  exit 1
fi
file_env 'DB_PASSWORD'
if [ -z "$DB_PASSWORD" ]; then
  echo >&2 "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi
cat >${FNMWEBUI_PATH}/.env <<EOL
APP_URL=${FNMWEBUI_BASE_URL}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOL

ln -sf /data/logs ${FNMWEBUI_PATH}/logs

# Fix perms
echo "Fixing perms..."
chown -R fnmwebui:fnmwebui ${FNMWEBUI_PATH}/bootstrap ${FNMWEBUI_PATH}/storage
#chown -R fnmwebui:fnmwebui /data/logs ${FNMWEBUI_PATH}/bootstrap ${FNMWEBUI_PATH}/logs ${FNMWEBUI_PATH}/storage
#chmod ug+rw /data/logs ${FNMWEBUI_PATH}/bootstrap/cache ${FNMWEBUI_PATH}/storage ${FNMWEBUI_PATH}/storage/framework/*
chmod ug+rw ${FNMWEBUI_PATH}/bootstrap/cache ${FNMWEBUI_PATH}/storage ${FNMWEBUI_PATH}/storage/framework/*
