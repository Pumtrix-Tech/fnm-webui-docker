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

DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-fnmwebui}
DB_USER=${DB_USER:-fnmwebui}
DB_TIMEOUT=${DB_TIMEOUT:-60}

# Handle .env
if [ ! -f "/data/.env" ]; then
  echo "Generating APP_KEY and unique NODE_ID"
  cat >"/data/.env" <<EOL
APP_KEY=$(artisan key:generate --no-interaction --force --show)
NODE_ID=$(php -r "echo uniqid();")
EOL
fi
cat "/data/.env" >>"${FNMWEBUI_PATH}/.env"
chown fnmwebui:fnmwebui /data/.env "${FNMWEBUI_PATH}/.env"

file_env 'DB_PASSWORD'
if [ -z "$DB_PASSWORD" ]; then
  echo >&2 "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi

dbcmd="mysql -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USER}" "-p${DB_PASSWORD}""
unset DB_PASSWORD

echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
counter=1
while ! ${dbcmd} -e "show databases;" >/dev/null 2>&1; do
  sleep 1
  counter=$((counter + 1))
  if [ ${counter} -gt ${DB_TIMEOUT} ]; then
    echo >&2 "ERROR: Failed to connect to database on $DB_HOST"
    exit 1
  fi
done
echo "Database ready!"

# Enable first run wizard if db is empty
counttables=$(echo 'SHOW TABLES' | ${dbcmd} "$DB_NAME" | wc -l)
echo ${dbcmd}
echo "Count: " ${counttables}
if [ "${counttables}" -eq "0" ]; then
  echo "Enabling First Run Wizard..."
  echo "INSTALL=user,finish">> ${FNMWEBUI_PATH}/.env
fi

echo "Updating database schema..."
artisan migrate --force --no-ansi --no-interaction
artisan db:seed --force --no-ansi --no-interaction

echo "Clear cache"
artisan cache:clear --no-interaction
artisan config:cache --no-interaction

mkdir -p /etc/services.d/nginx
cat >/etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat >/etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm81 -F
EOL
chmod +x /etc/services.d/php-fpm/run

