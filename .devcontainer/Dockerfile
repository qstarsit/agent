# Fully qualified names: Podman does not assume docker.io
FROM docker.io/oven/bun:1.4.5-debian AS bun
FROM docker.io/library/node:26.13.1-trixie-slim AS node

FROM docker.io/library/debian:trixie-slim

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG OMP_VERSION=19.1.1
# kubectl stays within one minor version of the exercise cluster (k3s 1.35)
ARG KUBECTL_VERSION=v1.35.10
ARG HELM_VERSION=v4.3.2
ARG K9S_VERSION=v0.51.0
ARG SOFKA_VERSION=v0.38.0
ARG K8S_MCP_VERSION=v0.1.3
ARG OHA_VERSION=v1.17.0
ARG UV_VERSION=0.13.10

# Everything system-wide is installed here, as root, at BUILD time.
# At run time the container has no root access and no sudo.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client less procps \
      ripgrep jq bash-completion locales libcap2-bin \
      python3 python3-pip python3-venv python-is-python3 libatomic1 \
 && rm -rf /var/lib/apt/lists/*

# Kubernetes tools, the Kubernetes MCP server for omp, oha (load testing), uv
RUN set -eu; \
    arch="$(dpkg --print-architecture)"; \
    rarch="$(uname -m)"; \
    gh=https://github.com; \
    bin=/usr/local/bin; \
    curl -fsSLo "$bin/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"; \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${arch}.tar.gz" \
      | tar -xz -C "$bin" --strip-components=1 "linux-${arch}/helm"; \
    curl -fsSL "$gh/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${arch}.tar.gz" \
      | tar -xz -C "$bin" k9s; \
    curl -fsSL "$gh/nklmilojevic/sofka/releases/download/${SOFKA_VERSION}/sofka-${SOFKA_VERSION}-${rarch}-unknown-linux-gnu.tar.gz" \
      | tar -xz -C "$bin" sofka; \
    curl -fsSLo "$bin/kubernetes-mcp-server" \
      "$gh/containers/kubernetes-mcp-server/releases/download/${K8S_MCP_VERSION}/kubernetes-mcp-server-linux-${arch}"; \
    curl -fsSLo "$bin/oha" "$gh/hatoo/oha/releases/download/${OHA_VERSION}/oha-linux-${arch}"; \
    curl -fsSL "$gh/astral-sh/uv/releases/download/${UV_VERSION}/uv-${rarch}-unknown-linux-gnu.tar.gz" \
      | tar -xz -C "$bin" --strip-components=1; \
    chmod 755 "$bin"/kubectl "$bin"/helm "$bin"/k9s "$bin"/sofka \
      "$bin"/kubernetes-mcp-server "$bin"/oha "$bin"/uv "$bin"/uvx

# Unprivileged user, deliberately not in sudoers. ~/.omp and /workspace are
# volume targets; owned by dev here so Podman gives dev the volumes.
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
 && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
 && mkdir -p "/home/${USERNAME}/.omp/agent" /workspace \
 && chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.omp" /workspace

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
COPY --chmod=755 set-key.sh /usr/local/bin/set-key
COPY --chmod=755 set-kubeconfig.sh /usr/local/bin/set-kubeconfig
# Copied into the omp-config volume the first time it is created
COPY --chown=${USERNAME}:${USERNAME} omp-config.yml /home/${USERNAME}/.omp/agent/config.yml
COPY --chown=${USERNAME}:${USERNAME} omp-mcp.json /home/${USERNAME}/.omp/agent/mcp.json

ENV LANG=C.UTF-8

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# oh-my-pi (the coding agent), pinned, from npm; installs omp to ~/.bun/bin.
RUN bun install -g "@oh-my-pi/pi-coding-agent@${OMP_VERSION}"
ENV PATH="/home/${USERNAME}/.bun/bin:${PATH}"
