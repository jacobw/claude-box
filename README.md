# claude-box

Image for running Claude Code Remote Control servers in a Kubernetes pod.

Debian trixie with Claude Code, kubectl, talosctl, flux, helm, sops, age, yq,
gh, git, tmux, python3 and ripgrep. Versions are pinned in the `Dockerfile`.

`claude-rc <dir> <spawn mode>` runs one server in `~/projects/<dir>`.

Pushing to `main` publishes `ghcr.io/<owner>/claude-box:r<run number>`.
