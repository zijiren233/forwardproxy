FROM golang:alpine AS builder

# GOPROXY is disabled by default, use:
# docker build --build-arg GOPROXY="https://goproxy.io" ...
# to enable GOPROXY.
ARG GOPROXY=""

ENV GOPROXY ${GOPROXY}

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /forwardproxy

COPY ./ ./

RUN xcaddy build --with github.com/caddyserver/forwardproxy@master=/forwardproxy

# multi-stage builds to create the final image
FROM alpine AS dist

RUN mkdir /etc/caddy

# bash is used for debugging, tzdata is used to add timezone information.
# Install ca-certificates to ensure no CA certificate errors.
#
# Do not try to add the "--no-cache" option when there are multiple "apk"
# commands, this will cause the build process to become very slow.
RUN set -ex \
    && apk upgrade \
    && apk add bash tzdata ca-certificates \
    && rm -rf /var/cache/apk/*

COPY --from=builder /forwardproxy/caddy /usr/local/bin/caddy

# Caddyfile
VOLUME [ "/etc/caddy" ]

ENTRYPOINT ["caddy"]