ARG     base=ubuntu:22.04

###

FROM 	${base} as base

RUN 	mkdir -p /usr/libexec/docker/cli-plugins && \
        apt-get update && \
        apt-get install -y \
            ca-certificates \
            wget

###

FROM 	base as docker

ARG     version=

RUN 	[ -e /etc/nsswitch.conf ] && grep '^hosts:\s*files\s*dns' /etc/nsswitch.conf

RUN 	wget -q -O - https://download.docker.com/linux/static/stable/$(uname -m)/docker-${version}.tgz | tar xz \
            --strip-components 1 \
            --directory /usr/local/bin \
            --no-same-owner

###

FROM 	base as docker-buildx

ARG     version_buildx=0.10.4

WORKDIR /usr/libexec/docker/cli-plugins

RUN 	wget -q -O docker-buildx https://github.com/docker/buildx/releases/download/v${version_buildx}/buildx-v${version_buildx}.linux-$(dpkg --print-architecture) && \
        chmod +x docker-buildx

###

FROM 	base as docker-compose

ARG     version_compose=2.17.2

WORKDIR /usr/libexec/docker/cli-plugins

RUN 	wget -q -O docker-compose https://github.com/docker/compose/releases/download/v${version_compose}/docker-compose-linux-$(uname -m) && \
        chmod +x docker-compose

###

FROM	base as dind

ARG     version_dind=1f32e3c95d72a29b3eaacba156ed675dba976cb5

RUN     wget -q -O /usr/local/bin/dind https://raw.githubusercontent.com/docker/docker/${version_dind}/hack/dind && \
        chmod +x /usr/local/bin/dind

###

FROM 	${base}

ARG     base=ubuntu:22.04

ENV 	DOCKER_VERSION=${version}
ENV     DOCKER_BUILDX_VERSION=${version_buildx}
ENV     DOCKER_COMPOSE_VERSION=${version_compose}
ENV 	DIND_COMMIT=${version_dind}
ENV 	DOCKER_TLS_CERTDIR=/certs

VOLUME 	/var/lib/docker
EXPOSE 	2375/tcp 2376/tcp
ENTRYPOINT ["dockerd-entrypoint.sh"]

COPY	--from=docker /usr/local/bin/ /usr/local/bin/
COPY	--from=docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY	--from=docker-compose /usr/libexec/docker/cli-plugins/docker-compose /usr/libexec/docker/cli-plugins/docker-compose
COPY	--from=dind /usr/local/bin/dind /usr/local/bin/dind

COPY 	modprobe.sh /usr/local/bin/modprobe
COPY 	docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY 	dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh

RUN 	mkdir -p /certs /certs/client /etc/docker && \
        chmod 1777 /certs /certs/client && \
        chmod +x \
            /usr/local/bin/docker-entrypoint.sh \
            /usr/local/bin/dockerd-entrypoint.sh \
            /usr/local/bin/modprobe && \
        apt-get update && \
        apt-get install -y \
            wget \
            gnupg \
            ca-certificates \
            openssh-client \
            btrfs-progs \
            e2fsprogs \
            iptables \
            iproute2 \
            openssl \
            uidmap \
            xfsprogs \
            xz-utils \
            pigz \
            zfsutils-linux \
            kmod && \
        addgroup --system dockremap && \
        adduser --system --group dockremap && \
        echo 'dockremap:165536:65536' >> /etc/subuid && \
        echo 'dockremap:165536:65536' >> /etc/subgid && \
        # HACK: ubuntu 22.04 uses iptables-nft by default, but docker doesn't support it yet
        update-alternatives --set iptables $(which iptables-legacy) && \
        dockerd --version && \
        containerd --version && \
        ctr --version && \
        runc --version

SHELL   ["/bin/bash", "-eu", "-o", "pipefail", "-c"] 

RUN     source /etc/lsb-release && \
        wget -q -O - https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
        wget -q -O - https://nvidia.github.io/libnvidia-container/${DISTRIB_ID@L}${DISTRIB_RELEASE}/libnvidia-container.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
        apt-get update && \
        apt-get install -y \
            nvidia-container-toolkit && \
        nvidia-ctk runtime configure --runtime=docker