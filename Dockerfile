FROM alpine:latest

MAINTAINER Troy Kelly <troy.kelly@really.ai>

ENV VERSION=1.14.0
ENV OPENSSL_VERSION=1.0.2o
ENV LIBPNG_VERSION=1.6.34
ENV LUAJIT_VERSION=2.0.5
ENV NGXDEVELKIT_VERSION=0.3.0
ENV NGXLUA_VERSION=0.10.13
ENV OWASPCRS_VERSION=3.0.0

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG OPENSSL_VERSION
ARG LIBPNG_VERSION
ARG LUAJIT_VERSION
ARG OWASPCRS_VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="NGINX with Certbot and lua support" \
      org.label-schema.description="Provides nginx ${VERSION} with modsecurity and lua (LuaJIT v${LUAJIT_VERSION}) support for certbot --nginx. Built with OpenSSL v${OPENSSL_VERSION} and LibPNG v${LIBPNG_VERSION}" \
      org.label-schema.url="https://really.ai/about/opensource" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/reallyreally/docker-nginx-modsecurity" \
      org.label-schema.vendor="Really Really, Inc." \
      org.label-schema.version=v$VERSION \
      org.label-schema.schema-version="1.0"

RUN build_pkgs="alpine-sdk apr-dev apr-util-dev autoconf automake binutils-gold curl curl-dev g++ gcc geoip-dev git gnupg icu-dev libcurl libffi-dev libjpeg-turbo-dev libstdc++ libtool libxml2-dev linux-headers lmdb-dev m4 make openssh-client pcre-dev pcre2-dev perl pkgconf py-pip python python2-dev wget yajl-dev zlib-dev" && \
  runtime_pkgs="ca-certificates pcre apr-util libjpeg-turbo icu icu-libs python2 py-setuptools yajl lua geoip libxml2 lua5.3-maxminddb" && \
  apk add --update --no-cache ${build_pkgs} ${runtime_pkgs} && \
  pip install --upgrade pip && \
  mkdir -p /src /var/log/nginx /run/nginx /var/cache/nginx && \
  addgroup nginx && \
  adduser -s /usr/sbin/nologin -G nginx -D nginx && \
  cd /src && \
  git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
  git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
  wget -qO - https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://nginx.org/download/nginx-${VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/simpl/ngx_devel_kit/archive/v${NGXDEVELKIT_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/openresty/lua-nginx-module/archive/v${NGXLUA_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASPCRS_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO /src/modsecurity.conf https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v2/master/modsecurity.conf-recommended && \
  cd /src/LuaJIT-${LUAJIT_VERSION} && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  cd /src/libpng-${LIBPNG_VERSION} && \
  ./configure --build=$CBUILD --host=$CHOST --prefix=/usr --enable-shared --with-libpng-compat && \
  make -j$(nproc) install V=0 && \
  cd /src/openssl-${OPENSSL_VERSION} && \
  ./config no-async && \
  make -j$(nproc) depend && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  cd /src/ModSecurity && \
  git submodule init && \
  git submodule update && \
  ./build.sh && \
  ./configure && \
  make -j$(nproc) && \
  make install && \
  cd /src/nginx-${VERSION} && \
  ./configure \
  	--prefix=/etc/nginx \
  	--sbin-path=/usr/sbin/nginx \
  	--conf-path=/etc/nginx/nginx.conf \
  	--error-log-path=/var/log/nginx/error.log \
  	--http-log-path=/var/log/nginx/access.log \
  	--pid-path=/var/run/nginx.pid \
  	--lock-path=/var/run/nginx.lock \
  	--http-client-body-temp-path=/var/cache/nginx/client_temp \
  	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  	--user=nginx \
  	--group=nginx \
  	--with-http_ssl_module \
  	--with-http_realip_module \
  	--with-http_addition_module \
  	--with-http_sub_module \
  	--with-http_dav_module \
  	--with-http_flv_module \
  	--with-http_mp4_module \
  	--with-http_gunzip_module \
  	--with-http_gzip_static_module \
  	--with-http_random_index_module \
  	--with-http_secure_link_module \
  	--with-http_stub_status_module \
  	--with-http_auth_request_module \
  	--without-http_autoindex_module \
  	--without-http_ssi_module \
  	--with-threads \
  	--with-stream \
  	--with-stream_ssl_module \
  	--with-mail \
  	--with-mail_ssl_module \
  	--with-file-aio \
  	--with-http_v2_module \
    --with-cc-opt="-fPIC -I /usr/include/apr-1" \
    --with-ld-opt="-luuid -lapr-1 -laprutil-1 -licudata -licuuc -lpng16 -lturbojpeg -ljpeg" \
    --with-openssl-opt="no-async enable-ec_nistp_64_gcc_128 no-shared no-ssl2 no-ssl3 no-comp no-idea no-weak-ssl-ciphers -DOPENSSL_NO_HEARTBEATS -O3 -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
  	--with-ipv6 \
  	--with-pcre-jit \
  	--with-openssl=/src/openssl-${OPENSSL_VERSION} \
    --add-module=/src/ngx_devel_kit-${NGXDEVELKIT_VERSION} \
    --add-module=/src/lua-nginx-module-${NGXLUA_VERSION} \
    --add-dynamic-module=/src/ModSecurity-nginx && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  make -j$(nproc) modules && \
  cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules && \
  sed -i 's!#user  nobody!user nginx nginx!g' /etc/nginx/nginx.conf && \
  sed -i "s!^    # another virtual host!include /etc/nginx/conf.d/*.conf;\n    # another virtual host!g" /etc/nginx/nginx.conf && \
  sed -i "s!^    #gzip  on;!    #gzip  on;\n    server_names_hash_max_size 6144;\n    server_names_hash_bucket_size 128;\n!g" /etc/nginx/nginx.conf && \
  sed -i "s!^        #error_page  404              /404.html;!        include /etc/nginx/insert.d/*.conf;\n\n        #error_page  404              /404.html;!g" /etc/nginx/nginx.conf && \
  sed -i 's!events {!load_module modules/ngx_http_modsecurity_module.so;\n\nevents {!g' /etc/nginx/nginx.conf && \
  cat /etc/nginx/nginx.conf && \
  cd ~ && \
  pip install virtualenv && \
  virtualenv /env && \
  git clone https://github.com/certbot/certbot && \
  cd certbot && \
  /env/bin/pip install -r ./readthedocs.org.requirements.txt && \
  export VENV_ARGS="--python $(command -v python2 || command -v python2.7)" && \
  tools/_venv_common.sh -e acme -e . -e certbot-apache -e certbot-nginx && \
  ln -s /root/certbot/venv/bin/certbot /usr/bin/certbot && \
  mkdir -p /etc/nginx/modsec && \
  echo -e "# Include the recommended configuration\nInclude /etc/nginx/modsec/modsecurity.conf\n# OWASP CRS v3 rules\nInclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf\nInclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/*.conf\n" > /etc/nginx/modsec/main.conf && \
  mv /src/modsecurity.conf /etc/nginx/modsec && \
  sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsec/modsecurity.conf && \
  sed -i 's!SecAuditLog /var/log/modsec_audit.log!SecAuditLog /var/log/nginx/modsec_audit.log!g' /etc/nginx/modsec/modsecurity.conf && \
  sed -i 's!^SecRequestBodyInMemoryLimit!#SecRequestBodyInMemoryLimit!g' /etc/nginx/modsec/modsecurity.conf && \
  mv /src/owasp-modsecurity-crs-${OWASPCRS_VERSION} /usr/local/ && \
  cp /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf.example /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf && \
  apk del ${build_pkgs} && \
  apk add ${runtime_pkgs} && \
  apk add gcc make perl && \
  cd /src/openssl-${OPENSSL_VERSION} && \
  make -j$(nproc) install && \
  ln -s /usr/local/ssl/bin/openssl /usr/bin/ && \
  cd ~ && \
  apk del perl gcc make && \
  rm -Rf /src && \
  echo -e "#!/usr/bin/env sh\n\nif [ -f "/usr/bin/certbot" ]; then\n  /usr/bin/certbot renew\nfi\n" > /etc/periodic/daily/certrenew && \
  chmod 755 /etc/periodic/daily/certrenew && \
  chown -R nginx:nginx /run/nginx /var/log/nginx /var/cache/nginx /etc/nginx

EXPOSE 80 443

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
