# Xray (VLESS + WebSocket) for Cloady.
# TLS is terminated at Cloady's edge (web ports get an https:// URL), so Xray
# listens for plain WebSocket inside the container.
# Cloady serves an app without a compose file on port 3000 unless the PORT
# variable names another port; the compose file in this repo pins 3000.
FROM alpine:3.21

ARG XRAY_VERSION=26.11.9

RUN apk add --no-cache ca-certificates curl unzip \
    && curl -L -o /tmp/xray.zip \
        "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip" \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/xray \
    && rm /tmp/xray.zip \
    && apk del curl unzip

COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
