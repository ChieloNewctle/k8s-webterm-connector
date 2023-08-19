#!/bin/sh
CONTAINER_SSH_BIND_PORT="$1"

UUID_LOWER=$(uuidgen -r | tr '[:upper:]' '[:lower:'])
UUID_UPPER=$(echo "$UUID_LOWER" | tr '[:lower:]' '[:upper:]')

# mute tty echo
echo "stty raw -echo"

# prepare ssh server
echo "mkdir /run/sshd"
echo "chmod 700 /run/sshd"
echo "/usr/sbin/sshd -p ${CONTAINER_SSH_BIND_PORT}"

# add public key to authorized_keys in the container
echo "mkdir -p ~/.ssh"
[ -e ~/.ssh/id_rsa.pub ] && echo "echo \"$(cat ~/.ssh/id_rsa.pub)\" >> ~/.ssh/authorized_keys && chmod -R 600 ~/.ssh" || true
echo "sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys"

# execute socat to bridge stdio with ssh tcp connection
echo "echo && echo ${UUID_UPPER} | tr '[:upper:]' '[:lower:'] \
  && socat -T30 - tcp:localhost:${CONTAINER_SSH_BIND_PORT}"

# drop useless outputs that are ahead of ssh connection
while read line; do
  if echo "$line" | grep -q "$UUID_LOWER" >/dev/null; then
    break
  else
    true
  fi
done
