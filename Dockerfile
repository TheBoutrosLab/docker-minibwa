ARG MINIFORGE_VERSION=26.1.1-2
ARG SAMTOOLS_VERSION=1.24
ARG CONDA_ENV_PATH=/opt/conda/envs/minibwa

FROM condaforge/miniforge3:${MINIFORGE_VERSION} AS builder

ARG CONDA_ENV_PATH
ARG MINIBWA_VERSION=0.7
ARG MINIBWA_SHA256=ea5f974a03fbd5f5dd3c7d4323d6e63917c440d26767bf649d008cebb96c7701

ADD --checksum=sha256:${MINIBWA_SHA256} \
    https://github.com/lh3/minibwa/releases/download/v${MINIBWA_VERSION}/minibwa-${MINIBWA_VERSION}.tar.bz2 \
    /tmp/minibwa.tar.bz2

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bzip2 \
    build-essential \
    ca-certificates \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${CONDA_ENV_PATH}/bin /tmp/minibwa && \
    tar -xjf /tmp/minibwa.tar.bz2 -C /tmp/minibwa --strip-components=1 && \
    make -C /tmp/minibwa omp=0 -j"$(nproc)" && \
    install -m 0755 /tmp/minibwa/minibwa ${CONDA_ENV_PATH}/bin/minibwa && \
    rm -rf /tmp/minibwa /tmp/minibwa.tar.bz2

FROM ghcr.io/theboutroslab/samtools:${SAMTOOLS_VERSION} AS final

ARG CONDA_ENV_PATH

COPY --from=builder ${CONDA_ENV_PATH} ${CONDA_ENV_PATH}

ENV CONDA_ENV_PATH="${CONDA_ENV_PATH}" \
    PATH="${CONDA_ENV_PATH}/bin:${PATH}"

# Change the default user to bldocker from root
USER bldocker

LABEL maintainer="Yash Patel <ypatel@sbpdiscovery.org>" \
      org.opencontainers.image.source=https://github.com/TheBoutrosLab/docker-minibwa \
      org.opencontainers.image.description="Dockerfile for minibwa"
