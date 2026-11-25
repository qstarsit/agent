# Fully qualified names: Podman does not assume docker.io
FROM docker.io/oven/bun:1.4.5-debian AS bun

FROM docker.io/library/debian:trixie-slim

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG OMP_VERSION=19.1.1

# Everything system-wide is installed here, as root, at BUILD time.
# At run time the container has no root access and no sudo.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client less procps \
      ripgrep jq bash-completion locales libcap2-bin \
 && rm -rf /var/lib/apt/lists/*

# Unprivileged user, deliberately not in sudoers. ~/.omp and /workspace are
# volume targets; owned by dev here so Podman gives dev the volumes.
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
 && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
 && mkdir -p "/home/${USERNAME}/.omp/agent" /workspace \
 && chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.omp" /workspace

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --chmod=755 set-key.sh /usr/local/bin/set-key
# Copied into the omp-config volume the first time it is created
COPY --chown=${USERNAME}:${USERNAME} omp-config.yml /home/${USERNAME}/.omp/agent/config.yml

ENV LANG=C.UTF-8

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# oh-my-pi (the coding agent), pinned, from npm; installs omp to ~/.bun/bin.
RUN bun install -g "@oh-my-pi/pi-coding-agent@${OMP_VERSION}"
ENV PATH="/home/${USERNAME}/.bun/bin:${PATH}"
