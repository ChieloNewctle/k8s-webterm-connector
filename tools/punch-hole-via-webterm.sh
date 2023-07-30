#!/bin/sh
CONTAINER_SSH_BIND_PORT="$1"
HOLE_SOCKET="$2"

read line

UUID=$(uuidgen -r)

echo "stty raw -echo"

echo "mkdir /run/sshd"
echo "chmod 700 /run/sshd"
echo "/usr/sbin/sshd -p ${CONTAINER_SSH_BIND_PORT}"
echo "echo"
echo "echo ${UUID} && socat - tcp:localhost:${CONTAINER_SSH_BIND_PORT}"

while read line; do
	if echo "$line" | grep -q "$UUID" > /dev/null; then
		break
	else
		true
	fi
done

socat - "unix-l:${HOLE_SOCKET},reuseaddr,fork"
