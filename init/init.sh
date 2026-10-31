#!/bin/sh
set -eu

mkdir -p /secrets/certs /secrets/ssh

if [ ! -f /secrets/certs/home.pem ]; then
    echo "init: generating self-signed TLS cert"
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
        -days 365 -subj "/CN=home.test" \
        -addext "subjectAltName=DNS:home.test,DNS:localhost" \
        -keyout /tmp/home.key -out /secrets/certs/home.crt 2>/dev/null
    cat /secrets/certs/home.crt /tmp/home.key > /secrets/certs/home.pem
    chmod 644 /secrets/certs/home.crt /secrets/certs/home.pem
fi

if [ ! -f /secrets/ssh/id_ed25519 ]; then
    echo "init: generating SSH client key"
    ssh-keygen -q -t ed25519 -N '' -C ssh443-test -f /secrets/ssh/id_ed25519
fi
