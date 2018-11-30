FROM alpine:latest

MAINTAINER Troy Kelly <troy.kelly@really.ai>

ENV VERSION=1.15.7
ENV OPENSSL_VERSION=1.1.1a
ENV LIBPNG_VERSION=1.6.35
ENV LUAJIT_VERSION=2.0.5
ENV NGXDEVELKIT_VERSION=0.3.0
ENV NGXLUA_VERSION=0.10.13
ENV MODSECURITY=3
ENV OWASPCRS_VERSION=3.0.0
ENV PYTHON_VERSION=3.7.1

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG OPENSSL_VERSION
ARG LIBPNG_VERSION
ARG LUAJIT_VERSION
ARG MODSECURITY
ARG OWASPCRS_VERSION
ARG PYTHON_VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="NGINX with ModSecurity, Certbot and lua support" \
      org.label-schema.description="Provides nginx ${VERSION} with ModSecurity v${MODSECURITY} (OWASP ModSecurity Core Rule Set CRS ${OWASPCRS_VERSION}) and lua (LuaJIT v${LUAJIT_VERSION}) support for certbot --nginx. Built with OpenSSL v${OPENSSL_VERSION} and LibPNG v${LIBPNG_VERSION}. Using Python ${PYTHON_VERSION} for Let's Encrypt Certbot" \
      org.label-schema.url="https://really.ai/about/opensource" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/reallyreally/docker-nginx-modsecurity" \
      org.label-schema.vendor="Really Really, Inc." \
      org.label-schema.version=v$VERSION \
      org.label-schema.schema-version="1.0"

RUN build_pkgs="alpine-sdk apr-dev apr-util-dev autoconf automake binutils-gold curl curl-dev g++ gcc geoip-dev git gnupg icu-dev libcurl libffi-dev libjpeg-turbo-dev libstdc++ libtool libxml2-dev linux-headers lmdb-dev m4 make openssh-client pcre-dev pcre2-dev perl pkgconf wget yajl-dev zlib-dev" && \
  runtime_pkgs="ca-certificates pcre apr-util libjpeg-turbo icu icu-libs yajl lua geoip libxml2 lua5.3-maxminddb libffi" && \
  apk add --update --no-cache ${build_pkgs} ${runtime_pkgs} && \
  mkdir -p /src /var/log/nginx /run/nginx /var/cache/nginx && \
  addgroup nginx && \
  adduser -s /usr/sbin/nologin -G nginx -D nginx && \
  cd /src && \
  git clone --depth 1 -b v${MODSECURITY}/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
  git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
  wget -qO - https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://nginx.org/download/nginx-${VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/simpl/ngx_devel_kit/archive/v${NGXDEVELKIT_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/openresty/lua-nginx-module/archive/v${NGXLUA_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASPCRS_VERSION}.tar.gz | tar xzf  - -C /src && \
  wget -qO - https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar xzf  - -C /src && \
  wget -qO /src/modsecurity.conf https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v${MODSECURITY}/master/modsecurity.conf-recommended && \
  cd /src/openssl-${OPENSSL_VERSION} && \
  ./config no-async -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' && \
  make -j$(nproc) depend && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  cd /src/Python-${PYTHON_VERSION} && \
  ./configure --build=$CBUILD --host=$CHOST --prefix=/usr --enable-shared && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  python3 -m ensurepip && \
  pip3 install --upgrade pip setuptools && \
  if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
  if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
  cd /src/LuaJIT-${LUAJIT_VERSION} && \
  make -j$(nproc) && \
  make -j$(nproc) install && \
  cd /src/libpng-${LIBPNG_VERSION} && \
  ./configure --build=$CBUILD --host=$CHOST --prefix=/usr --enable-shared --with-libpng-compat && \
  make -j$(nproc) install V=0 && \
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
  sed -i "s!^    #gzip  on;!    #gzip  on;\n    server_names_hash_max_size 6144;\n    server_names_hash_bucket_size 128;\n\nmodsecurity on;\nmodsecurity_rules_file /etc/nginx/modsec/modsec_includes.conf;\n!g" /etc/nginx/nginx.conf && \
  sed -i "s!^        #error_page  404              /404.html;!        include /etc/nginx/insert.d/*.conf;\n\n        #error_page  404              /404.html;!g" /etc/nginx/nginx.conf && \
  sed -i 's!events {!load_module modules/ngx_http_modsecurity_module.so;\n\nevents {!g' /etc/nginx/nginx.conf && \
  sed -i "s!^        server_name  localhost;!        server_name  localhost;\n\n        #include /etc/nginx/modsec/modsec_on.conf;!g" /etc/nginx/nginx.conf && \
  sed -i "s!^            index  index.html index.htm;!            index  index.html index.htm;\n            #include /etc/nginx/modsec/modsec_rules.conf;!g" /etc/nginx/nginx.conf && \
  cd ~ && \
  git clone https://github.com/certbot/certbot && \
  cd certbot && \
  CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" /usr/bin/pip install -r ./readthedocs.org.requirements.txt && \
  CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" /usr/bin/pip install --no-cache-dir \
	--editable ./acme \
	--editable ./certbot-dns-cloudxns \
	--editable ./certbot-dns-digitalocean \
	--editable ./certbot-dns-dnsimple \
	--editable ./certbot-dns-dnsmadeeasy \
	--editable ./certbot-dns-gehirn \
	--editable ./certbot-dns-google \
	--editable ./certbot-dns-linode \
	--editable ./certbot-dns-luadns \
	--editable ./certbot-dns-nsone \
	--editable ./certbot-dns-ovh \
	--editable ./certbot-dns-rfc2136 \
	--editable ./certbot-dns-route53 \
	--editable ./certbot-dns-sakuracloud \
	--editable ./certbot-nginx \
	--editable ./ && \
  CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" /usr/bin/pip install dns-lexicon && \
  /usr/bin/certbot --version && \
  mkdir -p /etc/nginx/modsec/conf.d && \
  echo -e "# Example placeholder\n" > /etc/nginx/modsec/conf.d/example.conf && \
  echo -e "# Include the recommended configuration\nInclude /etc/nginx/modsec/modsecurity.conf\n# User generated\nInclude /etc/nginx/modsec/conf.d/*.conf\n\n# OWASP CRS v${MODSECURITY} rules\nInclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf\nInclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/*.conf\n" > /etc/nginx/modsec/main.conf && \
  echo -e "# For inclusion and centralized control\nmodsecurity on;\n" > /etc/nginx/modsec/modsec_on.conf && \
  echo -e "# For inclusion and centralized control\nmodsecurity_rules_file /etc/nginx/modsec/modsec_includes.conf;\n" > /etc/nginx/modsec/modsec_rules.conf && \
  echo -e "# For inclusion and centralized control\ninclude /etc/nginx/modsec/modsecurity.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-901-INITIALIZATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-905-COMMON-EXCEPTIONS.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-910-IP-REPUTATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-911-METHOD-ENFORCEMENT.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-912-DOS-PROTECTION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-913-SCANNER-DETECTION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-921-PROTOCOL-ATTACK.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-949-BLOCKING-EVALUATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-950-DATA-LEAKAGES.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-959-BLOCKING-EVALUATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-980-CORRELATION.conf\ninclude /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf\n" > /etc/nginx/modsec/modsec_includes.conf && \
  mv /src/modsecurity.conf /etc/nginx/modsec && \
  sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsec/modsecurity.conf && \
  sed -i 's!SecAuditLog /var/log/modsec_audit.log!SecAuditLog /var/log/nginx/modsec_audit.log!g' /etc/nginx/modsec/modsecurity.conf && \
  mv /src/owasp-modsecurity-crs-${OWASPCRS_VERSION} /usr/local/ && \
  mv /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
  mv /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
  cp /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf.example /usr/local/owasp-modsecurity-crs-${OWASPCRS_VERSION}/crs-setup.conf && \
  curl https://raw.githubusercontent.com/SpiderLabs/ModSecurity/49495f1925a14f74f93cb0ef01172e5abc3e4c55/unicode.mapping -o /etc/nginx/modsec/unicode.mapping && \
  apk del ${build_pkgs} && \
  apk add ${runtime_pkgs} && \
  apk add gcc make perl && \
  cd /src/openssl-${OPENSSL_VERSION} && \
  make -j$(nproc) install && \
  if [ -f /usr/bin/openssl ]; then rm -f /usr/bin/openssl; fi && \
  if [ -f /usr/local/ssl/bin/openssl ]; then ln -s /usr/local/ssl/bin/openssl /usr/bin/; fi && \
  if [ -f /usr/local/bin/openssl ]; then ln -s /usr/local/bin/openssl /usr/bin/; fi && \
  cd ~ && \
  apk del perl gcc make && \
  rm -Rf /src && \
  rm -Rf ~/.cache && \
  echo -e "#!/usr/bin/env sh\n\nif [ -f "/usr/bin/certbot" ]; then\n  /usr/bin/certbot renew\nfi\n" > /etc/periodic/daily/certrenew && \
  chmod 755 /etc/periodic/daily/certrenew && \
  chown -R nginx:nginx /run/nginx /var/log/nginx /var/cache/nginx /etc/nginx && \
  echo -e "\n\n** /etc/nginx/nginx.conf\n" && \
  cat /etc/nginx/nginx.conf && \
  echo -e "\n\n** /etc/nginx/modsec/conf.d/example.conf\n" && \
  cat /etc/nginx/modsec/conf.d/example.conf && \
  echo -e "\n\n** /etc/nginx/modsec/main.conf\n" && \
  cat /etc/nginx/modsec/main.conf && \
  echo -e "\n\n** /etc/nginx/modsec/modsecurity.conf\n" && \
  cat /etc/nginx/modsec/modsecurity.conf && \
  echo -e "\n\n** /etc/nginx/modsec/modsec_on.conf\n" && \
  cat /etc/nginx/modsec/modsec_on.conf && \
  echo -e "\n\n** /etc/nginx/modsec/modsec_rules.conf\n" && \
  cat /etc/nginx/modsec/modsec_rules.conf && \
  echo -e "\n\n** /etc/nginx/modsec/modsec_includes.conf\n" && \
  cat /etc/nginx/modsec/modsec_includes.conf && \
  echo -e "\n\n** /etc/periodic/daily/certrenew\n" && \
  cat /etc/periodic/daily/certrenew

EXPOSE 80 443

COPY docker-entrypoint.sh /usr/local/bin/
COPY certbot.default.sh /usr/local/sbin/

ENTRYPOINT ["docker-entrypoint.sh"]
