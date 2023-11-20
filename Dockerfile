ARG         base=ubuntu:22.04

###

FROM	    alpine as dind

ARG         dind=1f32e3c95d72a29b3eaacba156ed675dba976cb5

RUN         wget -q -O /usr/local/bin/dind https://raw.githubusercontent.com/docker/docker/${dind}/hack/dind && \
            chmod +x /usr/local/bin/dind

###

FROM        ${base}

ARG         TARGETARCH

ARG         version=

ARG         containerd=1.6.9
ARG         docker_buildx_plugin=0.11.2
ARG         docker_compose_plugin=2.21.0

COPY 	    modprobe.sh /usr/local/bin/modprobe
COPY 	    docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY 	    dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh

VOLUME 	    /var/lib/docker
EXPOSE 	    2375/tcp 2376/tcp

ENTRYPOINT  ["dockerd"]

COPY        --from=dind /usr/local/bin/dind /usr/local/bin/dind
            
            # Install docker
RUN         apt-get update && \
            apt-get install -y \
                curl \
                ca-certificates \
                gnupg2 \
                iptables \
                libdevmapper1* && \
            . /etc/os-release; curl -s --parallel --parallel-immediate --parallel-max 5 \
                --output containerd.io.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/containerd.io_${containerd}-1_${TARGETARCH}.deb \
                --output docker-buildx-plugin.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-buildx-plugin_${docker_buildx_plugin}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb \
                --output docker-ce-cli.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-ce-cli_${version}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb \
                --output docker-ce.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-ce_${version}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb \
                --output docker-compose-plugin.deb https://download.docker.com/linux/ubuntu/dists/${VERSION_CODENAME}/pool/stable/${TARGETARCH}/docker-compose-plugin_${docker_compose_plugin}-1~ubuntu.${VERSION_ID}~${VERSION_CODENAME}_${TARGETARCH}.deb && \
            dpkg -i \
                containerd.io.deb \
                docker-ce.deb \
                docker-ce-cli.deb \
                docker-buildx-plugin.deb \
                docker-compose-plugin.deb && \
            # Install nvidia-container-toolkit
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
            apt-get update && \
            apt-get install -y \
                nvidia-container-toolkit \
                kmod && \
            nvidia-ctk runtime configure --runtime=docker && \
            # Setup
            mkdir -p /certs /certs/client /etc/docker && \
            chmod 1777 /certs /certs/client && \
            dockerd --version && \
            containerd --version && \
            ctr --version && \
            runc --version
