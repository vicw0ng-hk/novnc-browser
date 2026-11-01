# novnc-browser
NoVNC browser.

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

CI runs the hooks, the image build, and the smoke test on every pull request.
