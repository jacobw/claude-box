# claude-box

A container image for running [Claude Code](https://code.claude.com/docs)
Remote Control servers in a Kubernetes pod, so sessions can be started and
steered from the Claude app or claude.ai/code without a laptop running.

Debian plus git, tmux, python3, ripgrep, Claude Code and the cluster CLIs:
kubectl, flux, helm, sops, age, yq, gh.

- **Claude Code, kubectl, gh and helm come from their makers' apt repos**,
  each version pinned and bumped by Renovate. The build fails if a repo's
  signing key isn't one whose fingerprint the Dockerfile lists. age is
  Debian's. flux, sops and yq have no apt repo; they are downloaded from
  their GitHub releases and checked against each release's checksums file.
- **Claude Code doesn't update itself.** Its apt install has no
  auto-updater: a new version is a new image, and takes effect when the pod
  is restarted on it. Renovate proposes those bumps at most once a week. The
  stable channel runs about a week behind and skips releases with major
  regressions.
- **`bin/claude-rc <dir> <spawn mode>`** runs one `claude remote-control`
  server for `~/projects/<dir>`, one per container. It waits until
  `~/.claude-rc-ready` exists, the directory exists and Claude Code is logged
  in, so a server never starts half-way through first-time setup.
- **No credentials** are in this repo or the image. Logins and keys belong on
  the home volume.

Pushing to `main` publishes `ghcr.io/<owner>/claude-box:r<run number>` and
`:latest`.
