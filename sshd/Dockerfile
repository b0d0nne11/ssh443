FROM alpine:3.22

RUN set -eux; \
    apk add --no-cache \
        openssh-server \
        python3 \
    ; \
    ssh-keygen -A;

RUN set -eux; \
    adduser -D -s /bin/sh tunnel; \
    echo 'tunnel:*' | chpasswd -e ;

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
