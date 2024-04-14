ARG         base=ubuntu:22.04

###

FROM        ${base}

ARG         TARGETARCH

ARG         version=
ARG         containerd=1.6.31

ENV 	    DOCKER_VERSION=${version}
ENV 	    DOCKER_TLS_CERTDIR=/certs

VOLUME 	    /var/lib/docker
EXPOSE 	    2375/tcp
EXPOSE      2376/tcp

ENTRYPOINT  ["dockerd-entrypoint.sh"]

            # Install docker
RUN         apt-get update && \
            apt-get install -y \
                curl \
                ca-certificates \
                iptables \
                iproute2 \
                openssl \
                tini && \
            . /etc/os-release; version_major=$(echo ${version} | cut -d. -f1); curl -s --parallel \
                --output /usr/local/bin/modprobe https://raw.githubusercontent.com/docker-library/docker/master/${version_major}/cli/modprobe.sh \
                --output /usr/local/bin/dockerd-entrypoint.sh https://raw.githubusercontent.com/docker-library/docker/master/${version_major}/dind/dockerd-entrypoint.sh \
                --output /usr/local/bin/dind https://raw.githubusercontent.com/moby/moby/v${version}/hack/dind \
                --output containerd.io.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/containerd.io_${containerd}-1_${TARGETARCH}.deb \
                --output docker-ce-cli.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-ce-cli_${version}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb \
                --output docker-ce.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-ce_${version}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb && \
            dpkg -i \
                containerd.io.deb \
                docker-ce.deb \
                docker-ce-cli.deb && \
            apt-get remove -y \
                curl && \
            rm *.deb && \
            # Setup
            ln -s $(which tini) /usr/bin/docker-init && \
            # HACK: ubuntu 22.04 uses iptables-nft by default, but docker doesn't support it yet
            update-alternatives --set iptables $(which iptables-legacy) && \
            update-alternatives --set ip6tables $(which ip6tables-legacy) && \
            chmod +x \
                /usr/local/bin/modprobe \
                /usr/local/bin/dockerd-entrypoint.sh \
                /usr/local/bin/dind && \
            mkdir -p /certs /certs/client /etc/docker && \
            chmod 1777 /certs /certs/client && \
            dockerd --version && \
            containerd --version && \
            ctr --version && \
            runc --version

            # Install nvidia-container-toolkit
RUN         apt-get update && \
            apt-get install -y \
                curl \
                gnupg2 && \
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                sed 's|deb https://|deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://|g' | \
                    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
            apt-get update && \
            apt-get install -y \
                nvidia-container-toolkit && \
            apt-get remove -y \
                curl \
                gnupg2 && \
            nvidia-ctk runtime configure --runtime=docker
