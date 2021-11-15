FROM skillfir/alpine:gcc AS builder01
# 设置nginx版本变量，注意先查看https://nginx.org获取最新版本  
ENV NGINX_VERSION 1.21.4
LABEL AUTHOR="WEIPENG"
# 编译安装nginx
ARG CONFIG="\
        --prefix=/app/nginx \
        --conf-path=/app/nginx/nginx.conf \
        --sbin-path=/app/nginx/sbin/nginx \
        --error-log-path=/app/nginx/logs/error.log \
        --http-log-path=/app/nginx/logs/access.log \
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
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
    " 
RUN apk update && apk upgrade &&\
wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -O nginx.tar.gz &&\
tar -zxf nginx.tar.gz &&\
rm -f nginx.tar.gz &&\
cd /usr/src/nginx-$NGINX_VERSION &&\
./configure $CONFIG --with-debug &&\
make -j$(getconf _NPROCESSORS_ONLN) &&\
mv objs/nginx objs/nginx-debug && \
mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so  &&\
mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so  && \
mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so &&\
mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so &&\
make install


#第2阶段构建
FROM skillfir/alpine:latest
LABEL AUTHOR="weipeng weipeng@163.com" description="/app/nginx"
RUN apk update && apk upgrade &&\
    apk add --no-cache \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        gd-dev &&\
    addgroup -S nginx &&\
    adduser -s /sbin/nologin -H -D -G nginx nginx
#引用阶段1的镜像内容到镜像
COPY --from=builder01 /app/nginx /app/nginx
#COPY nginx.conf /app/nginx/nginx.conf
#COPY default.conf /app/nginx/conf.d/default.conf
WORKDIR /app/nginx
EXPOSE 80
CMD ["./sbin/nginx","-g","daemon off;"]
