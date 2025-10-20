# Этап сборки бинарника
FROM --platform=$BUILDPLATFORM busybox:uclibc AS downloader
ARG TARGETARCH
ARG TAG
# Скачиваем бинарник прямо через wget из busybox
RUN mkdir /out && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        wget -O /out/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/$TAG/mihomo-linux-arm64-$TAG.gz; \
    elif [ "$TARGETARCH" = "arm" ]; then \
        wget -O /out/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/$TAG/mihomo-linux-armv7-$TAG.gz; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        wget -O /out/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/$TAG/mihomo-linux-amd64-v2-$TAG.gz; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    gunzip /out/mihomo.gz && \
    chmod +x /out/mihomo
# Минимальный финальный образ
FROM alpine:latest
ARG TARGETARCH
# Установка минимальных пакетов
RUN apk add --no-cache ca-certificates tzdata

RUN if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "amd64" ]; then \
        apk update && \
        apk add --no-cache ca-certificates tzdata nftables; \
    elif [ "$TARGETARCH" = "arm" ]; then \
        apk update && \
        apk add --no-cache ca-certificates tzdata iptables iptables-legacy && \
        rm -f /usr/sbin/iptables /usr/sbin/iptables-save /usr/sbin/iptables-restore && \
        ln -s /usr/sbin/iptables-legacy /usr/sbin/iptables && \
        ln -s /usr/sbin/iptables-legacy-save /usr/sbin/iptables-save && \
        ln -s /usr/sbin/iptables-legacy-restore /usr/sbin/iptables-restore; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi


# Копируем бинарник и скрипт
COPY --from=downloader /out/mihomo /mihomo
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Создаем папку для AWG конфигов
RUN mkdir -p /root/.config/mihomo/awg
# Стартовый скрипт
CMD ["/entrypoint.sh"]