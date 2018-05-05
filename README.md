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
Pre-configured with rules from OWASP CRS
Generates `/etc/nginx/modsec/modsec_on.conf` and `/etc/nginx/modsec/modsec_rules.conf` which you can use in for configurations. For example:
```
server {
    listen       80;
    server_name  localhost;

    include /etc/nginx/modsec/modsec_on.conf;

    location / {
        root   html;
        index  index.html index.htm;
        include /etc/nginx/modsec/modsec_rules.conf;
    }
  }
```

Certbot
-------
Easily add SSL security to your nginx hosts with certbot.
`docker exec -it nginx-modsecurity /bin/sh` will bring up a prompt at which time you can `certbot` to your hearts content.

_or_

`docker exec -it nginx-modsecurity certbot --no-redirect --must-staple -d example.com`

It even auto-renew's for you every day!
