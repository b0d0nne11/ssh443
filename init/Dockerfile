FROM alpine:3.22

# openssl for the TLS cert, ssh-keygen for the client key.
RUN set -eux; \
    apk add --no-cache \
        openssl \
        openssh-keygen \
    ;

COPY init.sh /init.sh
CMD ["/bin/sh", "/init.sh"]
