# really/nginx-modsecurity
Docker container providing [nginx](https://www.nginx.com) with [modsecurity] (https://www.modsecurity.org), [lua](https://www.nginx.com/resources/wiki/modules/lua/) and certbot for [Let's Encrypt](https://letsencrypt.org) SSL certificates

[![](https://images.microbadger.com/badges/image/really/nginx-modsecurity.svg)](https://microbadger.com/images/really/nginx-modsecurity "Get your own image badge on microbadger.com") [![GitHub issues](https://img.shields.io/github/issues/reallyreally/docker-nginx-modsecurity.svg?style=flat-square)](https://github.com/reallyreally/docker-nginx-modsecurity/issues) [![GitHub license](https://img.shields.io/github/license/reallyreally/docker-nginx-modsecurity.svg?style=flat-square)](https://github.com/reallyreally/docker-nginx-modsecurity/blob/master/LICENSE) [![Docker Pulls](https://img.shields.io/docker/pulls/really/nginx-modsecurity.svg?style=flat-square)](https://github.com/reallyreally/docker-nginx-modsecurity/)

Launch nginx using the default config:
```
docker run --name nginx-modsecurity \
  --restart=always \
  --net=host \
  -v /data/nginx/conf.d:/etc/nginx/conf.d:rw \
  -v /data/letsencrypt:/etc/letsencrypt:rw \
  -p 80:80 -p 443:443 -d \
  really/nginx-modsecurity
```

ModSecurity
-----------
Pre-configured with rules from OWASP CRS on my default.
If you want to disable it for a particular location simply set it to off
```
server
{
  listen 80;
  listen [::]:80;
  listen [::]:443 ssl http2;
  listen 443 ssl http2;

  server_name insecure.example.com;

  set $upstream "http://10.0.0.1:9000";

  include /etc/nginx/defaults/https.conf;
  include /etc/nginx/defaults/resolver.conf;

  location /
  {
    include /etc/nginx/defaults/proxy.conf;
    proxy_pass $upstream;
    modsecurity off;
  }

  include /etc/nginx/defaults/error-page.conf;

  ssl_certificate /etc/letsencrypt/live/insecure.example.com/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/insecure.example.com/privkey.pem; # managed by Certbot

  ssl_trusted_certificate /etc/letsencrypt/live/insecure.example.com/chain.pem; # managed by Certbot
  ssl_stapling on; # managed by Certbot
  ssl_stapling_verify on; # managed by Certbot

}
```

Certbot
-------
Easily add SSL security to your nginx hosts with certbot.
`docker exec -it nginx-modsecurity /bin/sh` will bring up a prompt at which time you can `certbot` to your hearts content.

_or_

`docker exec -it nginx-modsecurity certbot --no-redirect --must-staple -d example.com`

It even auto-renew's for you every day!
