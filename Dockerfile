# syntax=docker/dockerfile:1
FROM debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

LABEL org.opencontainers.image.source="https://github.com/vicw0ng-hk/novnc-browser"

RUN useradd --create-home --uid 1000 --shell /bin/bash browser

USER 1000:1000
WORKDIR /home/browser

# Placeholder until the browser stack (Xvfb, VNC, noVNC, Chromium) lands.
CMD ["sleep", "infinity"]
