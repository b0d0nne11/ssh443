#!/bin/sh
set -eu

# Copy the key in rather than bind-mounting it so ownership and permissions
# satisfy sshd's StrictModes regardless of the host's file ownership.
install -d -o tunnel -g tunnel -m 700 /home/tunnel/.ssh
install -o tunnel -g tunnel -m 600 /secrets/id_ed25519.pub /home/tunnel/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
