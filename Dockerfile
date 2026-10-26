FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       age bash ca-certificates curl dnsutils git gnupg iputils-ping jq less \
       netcat-openbsd openssh-client procps python3 python3-venv ripgrep \
       rsync tmux tzdata unzip vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# renovate: datasource=deb depName=claude-code registryUrl=https://downloads.claude.ai/claude-code/apt/stable?suite=stable&components=main&binaryArch=amd64
ARG CLAUDE_CODE_VERSION=2.1.308-1
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.36.5
# renovate: datasource=deb depName=gh registryUrl=https://cli.github.com/packages?suite=stable&components=main&binaryArch=amd64
ARG GH_VERSION=2.103.2
# renovate: datasource=deb depName=helm registryUrl=https://packages.buildkite.com/helm-linux/helm-debian/any?suite=any&components=main&binaryArch=amd64
ARG HELM_VERSION=4.3.0-1

RUN set -eux; \
    add_repo() { \
      name=$1 key=/etc/apt/keyrings/$2 key_url=$3 fingerprints=$4 source=$5; \
      curl -fsSLo "$key" "$key_url"; \
      found=$(gpg --show-keys --with-colons "$key" \
        | awk -F: '$1 == "pub" {p = 1; next} $1 == "fpr" && p {print $10; p = 0}'); \
      [ -n "$found" ]; \
      for f in $found; do \
        case " $fingerprints " in *" $f "*) ;; *) echo "unexpected key $f in $key"; exit 1 ;; esac; \
      done; \
      echo "deb [signed-by=$key] $source" > "/etc/apt/sources.list.d/$name.list"; \
    }; \
    install -d -m 0755 /etc/apt/keyrings; \
    add_repo claude-code claude-code.asc https://downloads.claude.ai/keys/claude-code.asc \
      31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE \
      "https://downloads.claude.ai/claude-code/apt/stable stable main"; \
    kube_minor=${KUBECTL_VERSION%.*}; \
    add_repo kubernetes kubernetes.asc "https://pkgs.k8s.io/core:/stable:/${kube_minor}/deb/Release.key" \
      DE15B14486CD377B9E876E1A234654DA9A296436 \
      "https://pkgs.k8s.io/core:/stable:/${kube_minor}/deb/ /"; \
    add_repo github-cli github-cli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      "2C6106201985B60E6C7AC87323F3D4EA75716059 7F38BBB59D064DBCB3D84D725612B36462313325" \
      "https://cli.github.com/packages stable main"; \
    add_repo helm helm.asc https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
      DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6 \
      "https://packages.buildkite.com/helm-linux/helm-debian/any/ any main"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "claude-code=${CLAUDE_CODE_VERSION}" "kubectl=${KUBECTL_VERSION#v}-*" \
      "gh=${GH_VERSION}" "helm=${HELM_VERSION}"; \
    rm -rf /var/lib/apt/lists/*; \
    claude --version; kubectl version --client; gh --version; helm version

# renovate: datasource=github-releases depName=fluxcd/flux2
ARG FLUX_VERSION=v2.10.0
# renovate: datasource=github-releases depName=getsops/sops
ARG SOPS_VERSION=v3.13.3
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.54.1
# renovate: datasource=github-releases depName=siderolabs/talos
ARG TALOSCTL_VERSION=v1.14.4

RUN set -eux; cd /tmp; \
    gh_dl() { curl -fsSLO "https://github.com/$1/releases/download/$2/$3"; }; \
    flux=flux_${FLUX_VERSION#v}_linux_amd64.tar.gz; \
    gh_dl fluxcd/flux2 "$FLUX_VERSION" "$flux"; \
    gh_dl fluxcd/flux2 "$FLUX_VERSION" "flux_${FLUX_VERSION#v}_checksums.txt"; \
    grep " $flux\$" "flux_${FLUX_VERSION#v}_checksums.txt" | sha256sum -c -; \
    tar -xzf "$flux" -C /usr/local/bin flux; \
    sops=sops-${SOPS_VERSION}.linux.amd64; \
    gh_dl getsops/sops "$SOPS_VERSION" "$sops"; \
    gh_dl getsops/sops "$SOPS_VERSION" "sops-${SOPS_VERSION}.checksums.txt"; \
    grep " $sops\$" "sops-${SOPS_VERSION}.checksums.txt" | sha256sum -c -; \
    install -m 0755 "$sops" /usr/local/bin/sops; \
    gh_dl mikefarah/yq "$YQ_VERSION" yq_linux_amd64; \
    gh_dl mikefarah/yq "$YQ_VERSION" checksums; \
    gh_dl mikefarah/yq "$YQ_VERSION" checksums_hashes_order; \
    col=$(($(grep -nx SHA-256 checksums_hashes_order | cut -d: -f1) + 1)); \
    echo "$(awk -v c="$col" '$1 == "yq_linux_amd64" {print $c}' checksums)  yq_linux_amd64" | sha256sum -c -; \
    install -m 0755 yq_linux_amd64 /usr/local/bin/yq; \
    gh_dl siderolabs/talos "$TALOSCTL_VERSION" talosctl-linux-amd64; \
    gh_dl siderolabs/talos "$TALOSCTL_VERSION" sha256sum.txt; \
    grep " talosctl-linux-amd64\$" sha256sum.txt | sha256sum -c -; \
    install -m 0755 talosctl-linux-amd64 /usr/local/bin/talosctl; \
    rm -f /tmp/*; \
    flux version --client; sops --version; yq --version; talosctl version --client

COPY bin/ /usr/local/bin/

RUN useradd -m -u 1000 -s /bin/bash claude
USER claude
WORKDIR /home/claude
# ~/.local/bin off PATH deliberately.
ENV HOME=/home/claude \
    PATH=/usr/local/bin:/usr/bin:/bin \
    LANG=C.UTF-8
