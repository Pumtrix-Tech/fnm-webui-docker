#!/usr/bin/with-contenv sh
# shellcheck shell=sh
set -e

if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g fnmwebui)" ]; then
  echo "Switching to PGID ${PGID}..."
  sed -i -e "s/^fnmwebui:\([^:]*\):[0-9]*/fnmwebui:\1:${PGID}/" /etc/group
  sed -i -e "s/^fnmwebui:\([^:]*\):\([0-9]*\):[0-9]*/fnmwebui:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u fnmwebui)" ]; then
  echo "Switching to PUID ${PUID}..."
  sed -i -e "s/^fnmwebui:\([^:]*\):[0-9]*:\([0-9]*\)/fnmwebui:\1:${PUID}:\2/" /etc/passwd
fi
