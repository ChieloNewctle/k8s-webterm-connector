#!/bin/sh
set -ex

WEBTERM_PORT="$1"
CONTAINER_SSH_BIND_PORT="$2"
FORWARD_SSH_BIND_PORT="$3"

DIR_NAME=$(dirname "$0")

trap "pkill -P $$" EXIT

ssh -N \
	-o "ProxyCommand '${DIR_NAME}/proxy-ssh-via-k8s-webterm.sh' '${WEBTERM_PORT}' '${CONTAINER_SSH_BIND_PORT}'" \
	-L ${FORWARD_SSH_BIND_PORT}:localhost:${CONTAINER_SSH_BIND_PORT} \
	-o ServerAliveInterval=15 \
	root@container
