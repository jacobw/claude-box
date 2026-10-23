FROM debian:trixie-slim

# A base toolset for running Claude Code Remote Control servers in a
# Kubernetes pod. Claude Code itself is not in the image: claude-install puts
# it in the home volume, where its own auto-updater keeps it current. Python
# venvs and other per-project tooling belong in the home volume too.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash ca-certificates curl dnsutils git gnupg iputils-ping jq less \
       netcat-openbsd openssh-client procps python3 python3-venv ripgrep \
       rsync tmux tzdata unzip vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# kubectl should stay within one minor of the cluster it talks to, so
# Renovate only proposes its patches (renovate.json).
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.36.5
# renovate: datasource=github-releases depName=fluxcd/flux2
ARG FLUX_VERSION=v2.9.6
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v4.3.1
# renovate: datasource=github-releases depName=getsops/sops
ARG SOPS_VERSION=v3.13.3
# renovate: datasource=github-releases depName=FiloSottile/age
ARG AGE_VERSION=v1.3.2
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.54.1
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=v2.103.2

RUN set -eux; cd /tmp; \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    curl -fsSL "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION#v}_linux_amd64.tar.gz" \
      | tar -xz -C /usr/local/bin flux; \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin linux-amd64/helm; \
    curl -fsSLo /usr/local/bin/sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"; \
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin age/age age/age-keygen; \
    curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"; \
    curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_amd64.tar.gz" \
      | tar -xz --strip-components=2 -C /usr/local/bin "gh_${GH_VERSION#v}_linux_amd64/bin/gh"; \
    chmod 0755 /usr/local/bin/*; \
    kubectl version --client; flux version --client; helm version; sops --version; age --version; yq --version; gh --version

COPY bin/ /usr/local/bin/

# uid 1000 for the pod's securityContext; mount the home volume at
# /home/claude. Set TZ in the pod if you want local time.
RUN useradd -m -u 1000 -s /bin/bash claude
USER claude
WORKDIR /home/claude
ENV HOME=/home/claude \
    PATH=/home/claude/.local/bin:/usr/local/bin:/usr/bin:/bin \
    LANG=C.UTF-8
