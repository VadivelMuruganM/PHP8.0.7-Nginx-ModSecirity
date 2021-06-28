FROM php:8.0.7-fpm

LABEL maintainer="Vadivel Murugan <vadivelmurugan.cse@gmail.com>" \
	Description="Lightweight container with Latest Nginx, PHP-FPM 8.0.7 & Supervisor)."

# Copy existing application directory contents
COPY . /var/www/html

# Working directory
WORKDIR /var/www/html

# Required dependencies, Supervisor Configuration, Nginx Configuration, Remove default server definition, PDO, PgSQL, Zip,
# GD, Opcache, Redis, MongoDB, CRON, Application Supervisor, Install Composer &  Update Composer,
# Add user for laravel application, Copy php.ini file
RUN apt-get update && apt autoremove -y && apt-get install -y nginx cron vim wget telnet supervisor apt-utils libmcrypt-dev mcrypt git nano curl wget \
    zip unzip zlib1g zlib1g-dev zlibc libbz2-dev libzip-dev libxslt-dev libgd-dev libperl-dev libonig-dev libpng-dev libpq-dev \
    bison build-essential ca-certificates curl dh-autoreconf doxygen flex gawk git iputils-ping libcurl4-gnutls-dev \
    libexpat1-dev libgeoip-dev liblmdb-dev libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev \
    libyajl-dev locales lua5.3-dev pkg-config \
    && cp nginx/supervisor.conf /etc/supervisor/supervisord.conf && cp nginx/nginx.conf /etc/nginx/nginx.conf && pecl channel-update pecl.php.net \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && docker-php-ext-install pdo_pgsql pgsql opcache gd zip \
    && pecl install -o -f mongodb redis && rm -rf /tmp/pear && docker-php-ext-enable mongodb redis \
    && mkdir /setup && cd /setup && git clone https://github.com/ssdeep-project/ssdeep && cd ssdeep/ \
    && ./bootstrap && ./configure && make && make install && cd /setup && git clone https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity && git checkout v3/master && git submodule init && git submodule update \
    && sh build.sh && ./configure && make && make install && cd /setup && git clone https://github.com/SpiderLabs/ModSecurity-nginx \
    && cd /setup && wget http://nginx.org/download/nginx-1.14.2.tar.gz && tar -zxvf nginx-1.14.2.tar.gz \
    && cd nginx-1.14.2 && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && make modules \
    && ./configure --add-dynamic-module=../ModSecurity-nginx --with-cc-opt='-g -O2 -fPIC -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_dav_module --with-http_flv_module --with-http_geoip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module --with-http_mp4_module --with-http_perl_module --with-http_random_index_module --with-http_secure_link_module --with-http_v2_module --with-http_sub_module --with-http_xslt_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-threads \
    && make modules && cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/ && ldconfig && cd /setup \
    && wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v3.2.0.tar.gz && tar -zxvf v3.2.0.tar.gz \
    && mv owasp-modsecurity-crs-3.2.0 owasp-modsecurity-crs && mv owasp-modsecurity-crs/crs-setup.conf.example owasp-modsecurity-crs/crs-setup.conf \
    && mv owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example  owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf \
    && mv owasp-modsecurity-crs /usr/local/ \
    && cp /var/www/html/nginx/nginx.conf /etc/nginx/nginx.conf && mkdir -p /etc/nginx/modsec \
    && cp /setup/ModSecurity/unicode.mapping /etc/nginx/modsec/ && cp /var/www/html/nginx/modsecurity.conf /etc/nginx/modsec/modsecurity.conf \
    && cp /var/www/html/nginx/main.conf /etc/nginx/modsec/main.conf
# Start supervisord, nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]