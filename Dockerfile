# syntax=docker/dockerfile:1
FROM debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

LABEL org.opencontainers.image.source="https://github.com/vicw0ng-hk/novnc-browser"

# Package versions follow the pinned Debian release. Pinning each package
# would break the build whenever Debian replaces it with a security update.
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    chromium \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-core \
    novnc \
    openbox \
    supervisor \
    tigervnc-standalone-server \
    tini \
    websockify \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 --shell /bin/bash browser \
  && install -d -o browser -g browser /home/browser/.config /home/browser/.config/chromium \
  && install -d -m 1777 /tmp/.X11-unix

COPY rootfs/ /

ENV DISPLAY=:0 \
  LANG=C.UTF-8 \
  VNC_RESOLUTION=1280x720

USER 1000:1000
WORKDIR /home/browser
EXPOSE 6080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "--configuration", "/etc/supervisor/supervisord.conf"]
