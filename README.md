# ssh443

SSH over TLS hidden behind an ordinary-looking HTTPS site, for networks that
block VPN protocols but allow web traffic. Meant to be used either as a bastion
host or with [sshuttle](https://github.com/sshuttle/sshuttle). For now this is
simply a proof-of-concept and should not be used in production.

HAProxy terminates TLS on 443 and peeks at the first decrypted bytes:

```
                         ┌─ starts with "SSH-2.0" ─▶ sshd :22
:443 ─▶ HAProxy ─▶ peek ─┤
     (decrypts TLS)      └─ anything else ─────────▶ nginx :8080 (decoy page)
```

To a network filter it's a TLS connection to a website. A browser or crawler
that visits the domain gets a decoy page. Only a client that speaks SSH inside
the TLS session reaches sshd.

## Services

| Service   | Role                                                               |
|-----------|--------------------------------------------------------------------|
| `haproxy` | TLS on 443 (published as `localhost:8443`), routes SSH vs. web     |
| `sshd`    | Key-only OpenSSH for user `tunnel`, with python3 for sshuttle      |
| `web`     | nginx decoy page; gets the real client IP via PROXY protocol       |
| `init`    | One-shot; generates a self-signed cert and SSH key into `secrets/` |

## Bring it up

```sh
make up      # build, start, and stream logs in the foreground (Ctrl-C stops it)
make down    # stop and remove containers
make clean   # also remove local images and secrets/
```

## Browser (the decoy)

Visit <https://localhost:8443/>. The certificate is self-signed so the browser
will complain.

```sh
curl --cacert secrets/certs/home.crt https://localhost:8443/
```

## SSH through the TLS wrapper (bastion host)

Run from the repo root:

```sh
ssh -F ssh_config home
```

The `ProxyCommand` in the configuration wraps SSH in TLS with `openssl s_client`
so the connection looks like HTTPS. Plain `ssh` is rejected.

## sshuttle (the VPN)

Run from the repo root:

```sh
sshuttle --ssh-cmd "ssh -F ssh_config" -r home --dns --ns-hosts 1.1.1.1 0/0
```

While it's running, all your TCP + DNS traffic egresses from the `sshd`
container. Check it in Firefox at <https://api.ipify.org> or similar. This
forwards TCP and DNS only. Other UDP (QUIC, video calls) bypasses it.

`--ns-hosts 1.1.1.1` is needed because the container's `/etc/resolv.conf` points
at Docker's embedded resolver (`127.0.0.11`), which sshuttle can't forward to.
Against a real server plain `--dns` is enough. In this local model, `--ns-hosts`
routes the tunneled DNS to a public resolver the container can reach directly.

## Client SSH config (real deployment)

```
Host home
    HostName home.example.com
    Port 443
    User tunnel
    ProxyCommand openssl s_client -quiet -verify_quiet -verify_return_error -verify_hostname %h -servername %h -connect %h:%p
    ServerAliveInterval 30
```

With a publicly trusted certificate (e.g. Let's Encrypt) you don't need
`-CAfile`. Use a wildcard cert so the hostname doesn't appear in Certificate
Transparency logs.

## Notes

- The throwaway TLS cert and its key (`home.crt`, `home.pem`) are world-readable
  by design so haproxy can read them; the SSH private key (`id_ed25519`) is `0600`.
  All of `secrets/` is gitignored.
- DPI can't see the SSH banner (it's inside TLS), but a determined observer
  could still notice long-lived, high-volume TLS sessions to one host.
