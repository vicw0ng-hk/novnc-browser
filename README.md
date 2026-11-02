# novnc-browser
Chromium in a container, used from any web browser through [noVNC](https://novnc.com/).

The image runs Chromium on a TigerVNC display with the openbox window manager, and serves noVNC on port 6080. The remote desktop resizes to fit your browser window.

## Usage

```sh
docker run --detach --name novnc-browser \
  --publish 127.0.0.1:6080:6080 \
  --volume novnc-browser-profile:/home/browser/.config/chromium \
  ghcr.io/vicw0ng-hk/novnc-browser:latest
```

Then open <http://localhost:6080>.

Images are built for `linux/amd64` and `linux/arm64`. Each push to `master` that passes CI publishes `latest` and a `sha-<commit>` tag. Pin a `sha-` tag if you need reproducible deploys.

The volume keeps the Chromium profile (logins, history, extensions) across container restarts. To use a host directory instead, make it writable by UID 1000.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `VNC_PASSWORD` | unset | When set, noVNC asks for a username and password (HTTP Basic auth). When unset, there is no login. |
| `VNC_USERNAME` | `browser` | Username for the login. Only used when `VNC_PASSWORD` is set. |
| `VNC_RESOLUTION` | `1280x720` | Starting screen size. noVNC resizes the screen to fit your browser window after it connects. |

## Security

Without `VNC_PASSWORD`, anyone who can reach port 6080 controls the browser. Publish the port on `127.0.0.1` as above, or put an authenticating proxy such as Cloudflare Access in front of it.

The container serves plain HTTP. Use a reverse proxy or tunnel for TLS. Browsers send the Basic auth password in every request, so don't set `VNC_PASSWORD` without TLS on untrusted networks.

Chromium runs with `--no-sandbox`, because Docker's default seccomp profile blocks the namespaces its sandbox needs. The container is the only isolation, so a compromised page renderer can read the profile and anything else in the container. The image sets a Chromium policy that hides the warning bar for `--no-sandbox`, so Chromium shows "Managed by your organization" in its menu.

## Development

Install [pre-commit](https://pre-commit.com/) (for example `brew install pre-commit`), then enable the hooks:

```sh
pre-commit install
```

On each commit the hooks lint the Dockerfile (hadolint), shell scripts (shellcheck, shfmt), and GitHub Actions workflows (actionlint). To run them on every file:

```sh
pre-commit run --all-files
```

Building the image and running the smoke test takes longer, so it is not part of the commit hook. Run it with either of:

```sh
make test
pre-commit run --hook-stage manual docker-build
```

`make run` builds the image and serves it on <http://localhost:6080>.

CI runs the hooks on every pull request, and builds and smoke-tests the image natively on amd64 and arm64.
