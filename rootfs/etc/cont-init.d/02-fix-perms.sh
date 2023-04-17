#!/usr/bin/with-contenv sh
# shellcheck shell=sh
set -e

echo "Fixing perms..."
mkdir -p /data \
  /var/run/nginx \
  /var/run/php-fpm
chown fnmwebui:fnmwebui \
  /data \
  "${FNMWEBUI_PATH}"
#  "${FNMWEBUI_PATH}" \
#  "${FNMWEBUI_PATH}/.env"
chown -R fnmwebui:fnmwebui \
  /home/fnmwebui \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php81 \
  /var/run/nginx \
  /var/run/php-fpm
