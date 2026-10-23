# claude-box

A container image for running [Claude Code](https://code.claude.com/docs)
Remote Control servers in a Kubernetes pod, so sessions can be started and
steered from the Claude app or claude.ai/code without a laptop running.

Debian plus git, tmux, python3, ripgrep and the cluster CLIs: kubectl, flux,
helm, sops, age, yq, gh.

- **Claude Code is not in the image.** `bin/claude-install`, run as an init
  container, installs it into the home volume (`/home/claude`), and its
  auto-updater keeps it current.
- **`bin/claude-rc <dir> <spawn mode>`** runs one `claude remote-control`
  server for `~/projects/<dir>`, one per container. It waits until
  `~/.claude-rc-ready` exists, the directory exists and Claude Code is logged
  in, so a server never starts half-way through first-time setup.
- **No credentials** are in this repo or the image. Logins and keys belong on
  the home volume.

Pushing to `main` publishes `ghcr.io/<owner>/claude-box:r<run number>` and
`:latest`.
