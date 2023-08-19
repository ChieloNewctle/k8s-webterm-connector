#!/bin/sh
WEBTERM_PORT="$1"
CONTAINER_SSH_BIND_PORT="$2"

DIR_NAME=$(dirname "$0")

HOLE_SOCKET="/tmp/k8s-webterm-$1-$2-hole.sock"
rm -f "${HOLE_SOCKET}"

trap "rm -f '${HOLE_SOCKET}'" EXIT
trap "pkill -P $$" EXIT

socat -T30 tcp:localhost:${WEBTERM_PORT} \
  system:"'${DIR_NAME}/punch-hole-via-webterm.sh' '${CONTAINER_SSH_BIND_PORT}' && socat -T30 - 'unix-l:${HOLE_SOCKET},reuseaddr'" &

until [ -e "${HOLE_SOCKET}" ]; do
  sleep 1
done

socat -T30 - "unix:${HOLE_SOCKET}"
