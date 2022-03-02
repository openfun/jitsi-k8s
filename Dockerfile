
FROM debian:stable-slim as base

# Upgrade system packages to install security updates
RUN apt-get update && \
    apt-get -y upgrade && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app


# -- Download --
FROM busybox as downloader

WORKDIR /download

ARG KUSTOMIZE_RELEASE=4.3.0
ARG KUBECTL_RELEASE=1.22.1
ARG YQ_RELEASE=4.12.1

RUN wget "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_RELEASE}/kustomize_v${KUSTOMIZE_RELEASE}_linux_amd64.tar.gz" && \
    tar xzf "kustomize_v${KUSTOMIZE_RELEASE}_linux_amd64.tar.gz" && \
    chmod 755 kustomize

RUN wget "https://dl.k8s.io/release/v${KUBECTL_RELEASE}/bin/linux/amd64/kubectl" && \
    chmod 755 kubectl

RUN wget "https://github.com/mikefarah/yq/releases/download/v${YQ_RELEASE}/yq_linux_amd64" -O yq &&\
    chmod 755 yq

# -- Core --
FROM base as core

RUN apt-get update && \
    apt-get install -y git gpg jq && \
    rm -rf /var/lib/apt/lists/*

COPY --from=downloader /download/kubectl /usr/local/bin/kubectl
COPY --from=downloader /download/kustomize /usr/local/bin/kustomize
COPY --from=downloader /download/yq /usr/local/bin/yq

COPY ./docker/files/usr/local/bin/entrypoint /usr/local/bin/entrypoint

WORKDIR /data

COPY k8s /data/k8s

# Give the "root" group the same permissions as the "root" user on /etc/passwd
# to allow a user belonging to the root group to add new users; typically the
# docker user (see entrypoint).
RUN chmod g=u /etc/passwd && \
    mkdir /home/jitsi && \
    chmod g=u /home/jitsi

# Un-privileged user running the application
ARG DOCKER_USER

RUN chown "${DOCKER_USER}" /home/jitsi
USER ${DOCKER_USER}


# We wrap commands run in this container by the following entrypoint that
# creates a user on-the-fly with the container user ID (see USER) and root group
# ID.
ENTRYPOINT [ "/usr/local/bin/entrypoint" ]

