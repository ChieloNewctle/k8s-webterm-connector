#!/bin/sh
set -ex

WEBTERM_PORT="$1"
CONTAINER_SSH_BIND_PORT="$2"
FORWARD_SSH_BIND_PORT="$3"

DIR_NAME=$(dirname "$0")

HOLE_SOCKET="/tmp/k8s-webterm-$1-$2-$3-hole.sock"
rm -f "${HOLE_SOCKET}"

trap "rm -f ${HOLE_SOCKET}" EXIT
trap "pkill -P $$" EXIT

socat tcp:localhost:${WEBTERM_PORT} \
	exec:"${DIR_NAME}/punch-hole-via-webterm.sh ${CONTAINER_SSH_BIND_PORT} ${HOLE_SOCKET}" &

until [ -f "${HOLE_SOCKET}" ]; do
	sleep 1
done

ssh -N \
	-o "ProxyCommand socat - unix:${HOLE_SOCKET}" \
	-o ServerAliveInterval=15 root@container \
	-L ${FORWARD_SSH_BIND_PORT}:localhost:${CONTAINER_SSH_BIND_PORT}
