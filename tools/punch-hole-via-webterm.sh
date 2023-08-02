#!/bin/sh
CONTAINER_SSH_BIND_PORT="$1"

UUID_LOWER=$(uuidgen -r | tr '[:upper:]' '[:lower:'])
UUID_UPPER=$(echo "$UUID_LOWER" | tr '[:lower:]' '[:upper:]')

echo "stty raw -echo"

echo "mkdir /run/sshd"
echo "chmod 700 /run/sshd"
echo "/usr/sbin/sshd -p ${CONTAINER_SSH_BIND_PORT}"

echo "echo && echo ${UUID_UPPER} | tr '[:upper:]' '[:lower:'] \
  && socat -T30 - tcp:localhost:${CONTAINER_SSH_BIND_PORT}"

while read line; do
	if echo "$line" | grep -q "$UUID_LOWER" >/dev/null; then
		break
	else
		true
	fi
done
